import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/routing/app_router.dart';

/// Provider that checks for email verification when the app is in the foreground
/// and the user has an unverified email
final emailVerificationCheckerProvider = Provider.autoDispose<void>((ref) {
  Timer? verificationTimer;

  // Listen to auth state changes
  ref.listen(authStateProvider, (previous, next) async {
    // Cancel any existing timer
    verificationTimer?.cancel();

    // If the user has an unverified email, start checking for verification
    if (next.isEmailNotVerified) {
      talker.debug('Starting email verification checker for unverified user');

      // Check immediately first
      // Pass the timer so it can be cancelled inside if verification is detected
      await _checkEmailVerification(ref, verificationTimer);

      // Then set up a timer to check periodically (every 3 seconds)
      verificationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        // Pass the timer so it can be cancelled inside if verification is detected
        await _checkEmailVerification(ref, verificationTimer);
      });
    }
  });

  // Clean up timer when provider is disposed
  ref.onDispose(() {
    verificationTimer?.cancel();
    talker.debug('Email verification checker disposed');
  });

  return;
});

/// Helper function to check email verification status
/// Accepts the Timer object to allow cancellation upon verification detection
Future<void> _checkEmailVerification(Ref ref, Timer? verificationTimer) async {
  try {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    // If no user or user is not using email/password auth, do nothing
    if (user == null ||
        !user.providerData.any((element) => element.providerId == 'password')) {
      return;
    }

    talker.debug('Checking email verification status for: ${user.email}');

    // Get the ID token before reload to compare later
    final beforeToken = await user.getIdToken();

    // Force refresh the user to get the latest verification status
    await user.reload();

    // Get a fresh ID token after reload
    final afterToken = await user.getIdToken(true);

    // Check if the token has changed, which indicates a state change
    final tokenChanged = beforeToken != afterToken;
    if (tokenChanged) {
      talker.debug('ID token changed, state may have updated');
    }

    // Get the refreshed user through the auth service
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Check if the email is now verified
    if (refreshedUser != null && refreshedUser.emailVerified) {
      talker
          .info('Email verification detected for user: ${refreshedUser.email}');

      // Cancel the verification timer since we've detected verification
      verificationTimer?.cancel();
      talker.debug('Cancelled verification timer after detecting verification');

      // Handle email verification completion
      // Pass the refreshed user directly to ensure we use the verified state
      await authService.handleEmailVerificationComplete(refreshedUser);

      // Force a refresh of the auth state provider and currentUserProvider
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);

      // Wait for the auth state to be updated. A short delay helps ensure
      // that the providers have time to update before the router refresh.
      // Increased delay to ensure UI has time to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Refresh the router to update the UI.
      final router = ref.read(routerProvider);
      router.refresh();

      talker.debug('Router refreshed after email verification');
    }
  } catch (e) {
    talker.error('Error checking email verification status', e);
  }
}
