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
      await _checkEmailVerification(ref);

      // Then set up a timer to check periodically (every 3 seconds)
      verificationTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        await _checkEmailVerification(ref);
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
Future<void> _checkEmailVerification(Ref ref) async {
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

      // Handle email verification completion
      // This will update Firestore and refresh the auth state
      await authService.handleEmailVerificationComplete();

      // Force a refresh of the auth state provider
      ref.invalidate(authStateProvider);

      // Also invalidate the currentUserProvider to ensure it gets the latest user
      ref.invalidate(currentUserProvider);

      // Wait for the auth state to be updated
      await Future.delayed(const Duration(milliseconds: 300));

      // Refresh the router to update the UI
      final router = ref.read(routerProvider);
      router.refresh();

      // // If we're on the profile page, navigate to it again to force a rebuild
      // final currentLocation =
      //     router.routeInformationProvider.value.uri.toString();
      // if (currentLocation.contains('/profile')) {
      //   talker.debug('Refreshing profile page after email verification');
      //   // Use a slightly longer delay to ensure the auth state has fully propagated
      //   Timer(const Duration(milliseconds: 800), () {
      //     // Force a full refresh by going to a different page first
      //     router.go('/');
      //     // Then go back to profile after a short delay
      //     Timer(const Duration(milliseconds: 100), () {
      //       router.go('/profile');
      //     });
      //   });
      // }
    } else {
      // If the user is still not verified, log the current state
      if (refreshedUser != null) {
        talker.debug(
            'User email verification status: ${refreshedUser.emailVerified}');
      }
    }
  } catch (e) {
    talker.error('Error checking email verification status', e);
  }
}
