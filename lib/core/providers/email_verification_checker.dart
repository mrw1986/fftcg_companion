import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

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

    // Force refresh the user to get the latest verification status
    await user.reload();

    // Get the refreshed user object
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Check if the email is now verified
    if (refreshedUser != null && refreshedUser.emailVerified) {
      talker
          .info('Email verification detected for user: ${refreshedUser.email}');

      // Update the verification status in Firestore
      await authService.updateVerificationStatus();

      // Force refresh the auth state by getting a new ID token
      // This will trigger a state change in authStateProvider
      await refreshedUser.getIdToken(true);
    }
  } catch (e) {
    talker.error('Error checking email verification status', e);
  }
}
