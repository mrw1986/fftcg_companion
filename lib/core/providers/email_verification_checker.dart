import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
// Import UserRepository to update Firestore
// Removed unused imports
// import 'package:fftcg_companion/core/routing/app_router.dart';

/// Provider that checks for email verification when the app is in the foreground
/// and the user has an unverified email
final emailVerificationCheckerProvider = Provider.autoDispose<void>((ref) {
  Timer? verificationTimer;

  void startVerificationCheck() {
    // Cancel any existing timer before starting a new one
    verificationTimer?.cancel();
    talker.debug('Starting email verification checker timer...');

    // Check immediately first, and cancel timer if verified
    _checkEmailVerification(ref).then((verified) {
      if (verified) {
        verificationTimer?.cancel();
        talker
            .debug('Verification detected on initial check, timer cancelled.');
      } else if (verificationTimer == null || !verificationTimer!.isActive) {
        // If not verified initially AND timer isn't already running, set up the periodic timer
        verificationTimer =
            Timer.periodic(const Duration(seconds: 3), (_) async {
          final isVerifiedNow = await _checkEmailVerification(ref);
          if (isVerifiedNow) {
            // Cancel the timer explicitly when verification is detected
            verificationTimer?.cancel();
            talker.debug('Verification detected in timer, cancelling timer.');
          }
        });
      }
    });
  }

  void stopVerificationCheck() {
    if (verificationTimer?.isActive ?? false) {
      verificationTimer?.cancel();
      talker.debug('Stopped email verification checker timer.');
    }
  }

  // Listen to auth state changes with explicit types
  ref.listen<AuthState>(authStateProvider,
      (AuthState? previous, AuthState next) {
    // Start checking if the state is emailNotVerified OR
    // if the state is authenticated but the user's email isn't verified yet
    // (covers linking unverified email to existing authenticated account)
    bool shouldStartChecking = next.status == AuthStatus.emailNotVerified ||
        (next.status == AuthStatus.authenticated &&
            !(next.user?.emailVerified ?? true));

    // Check if the condition to start checking wasn't met previously
    bool wasCheckingPreviously =
        previous?.status == AuthStatus.emailNotVerified ||
            (previous?.status == AuthStatus.authenticated &&
                !(previous?.user?.emailVerified ?? true));

    if (shouldStartChecking) {
      // Start only if we weren't already in a state that required checking
      if (!wasCheckingPreviously) {
        talker
            .debug('EmailVerificationChecker: Condition met, starting check.');
        startVerificationCheck();
      } else {
        talker.debug(
            'EmailVerificationChecker: Condition still met, check likely already running.');
      }
    } else {
      // Stop checking if the condition is no longer met
      if (wasCheckingPreviously) {
        talker.debug(
            'EmailVerificationChecker: Condition no longer met, stopping check.');
        stopVerificationCheck();
      }
    }
  });

  // Initial check in case the provider initializes when already in the target state
  final initialAuthState = ref.read(authStateProvider);
  // Added null check for initialAuthState and check for authenticated but unverified email
  if (initialAuthState.status == AuthStatus.emailNotVerified ||
      (initialAuthState.status == AuthStatus.authenticated &&
          !(initialAuthState.user?.emailVerified ?? true))) {
    talker.debug(
        'EmailVerificationChecker: Initial state requires check, starting.');
    startVerificationCheck();
  }

  // Clean up timer when provider is disposed
  ref.onDispose(() {
    stopVerificationCheck();
    talker.debug('Email verification checker disposed');
  });

  return;
});

/// Helper function to check email verification status
/// Returns true if email is verified, false otherwise.
Future<bool> _checkEmailVerification(Ref ref) async {
  final authService = ref.read(authServiceProvider);
  final user = authService.currentUser;

  // Exit early if no user or user is already verified
  if (user == null || user.emailVerified) {
    talker.debug(
        'Skipping verification check: User is null or already verified.');
    // Ensure the detected flag is false if already verified or no user
    ref.read(emailVerificationDetectedProvider.notifier).state = false;
    return user?.emailVerified ??
        false; // Return true if verified, false if null
  }

  // Also exit if user doesn't have an email provider (e.g., only Google linked)
  if (!user.providerData.any((element) => element.providerId == 'password')) {
    talker.debug(
        'Skipping verification check: User does not have email/password provider.');
    // Ensure the detected flag is false if not applicable
    ref.read(emailVerificationDetectedProvider.notifier).state = false;
    return false; // Not applicable for verification check
  }

  talker.debug('Checking email verification status for: ${user.email}');

  try {
    // Force refresh the user to get the latest verification status
    await user.reload();

    // Get the refreshed user directly from FirebaseAuth instance after reload
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Check if the email is now verified
    if (refreshedUser != null && refreshedUser.emailVerified) {
      talker
          .info('Email verification detected for user: ${refreshedUser.email}');

      // **Update Firestore Immediately:** Ensure DB reflects verified status.
      try {
        talker
            .debug('Verification detected, updating Firestore immediately...');
        await ref
            .read(userRepositoryProvider)
            .createUserFromAuth(refreshedUser);
        talker.debug(
            'Firestore updated immediately after verification detection.');
      } catch (firestoreError, stackTrace) {
        talker.error('Error updating Firestore immediately after verification',
            firestoreError, stackTrace);
        // Continue even if Firestore update fails, but log the error
      }

      // **Set the immediate detection flag:** Signal to UI to hide banner.
      ref.read(emailVerificationDetectedProvider.notifier).state = true;
      talker.debug('Set emailVerificationDetectedProvider to true.');

      // **KEEP INVALIDATION REMOVED:** Let the stream propagate naturally.
      talker.debug(
          'Verification detected, Firestore updated, and flag set. Stream should propagate state naturally.');
      return true; // Indicate verification was detected
    } else {
      talker.debug('Email still not verified.');
      // Ensure the detected flag is false if still not verified
      ref.read(emailVerificationDetectedProvider.notifier).state = false;
      return false; // Indicate still not verified
    }
  } catch (e) {
    // Handle potential errors during reload or token fetching
    talker.error('Error checking email verification status', e);
    // Ensure the detected flag is false on error
    ref.read(emailVerificationDetectedProvider.notifier).state = false;
    return false; // Assume not verified on error
  }
}
