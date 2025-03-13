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

    // Force refresh the user to get the latest verification status
    await user.reload();

    // Get the refreshed user object
    final refreshedUser = FirebaseAuth.instance.currentUser;

    // Check if the email is now verified
    if (refreshedUser != null && refreshedUser.emailVerified) {
      talker
          .info('Email verification detected for user: ${refreshedUser.email}');

      // Handle email verification completion
      // This will update Firestore and refresh the auth state
      await authService.handleEmailVerificationComplete();

      // Force a reload of the current user to ensure we have the latest state
      await FirebaseAuth.instance.currentUser?.reload();

      // Force a refresh of the auth state provider
      ref.invalidate(authStateProvider);

      // Refresh the router to update the UI
      final router = ref.read(routerProvider);
      router.refresh();

      // If we're on the profile page, navigate to it again to force a rebuild
      final currentLocation =
          router.routeInformationProvider.value.uri.toString();
      if (currentLocation.contains('/profile') &&
          !currentLocation.contains('/profile/')) {
        talker.debug('Refreshing profile page after email verification');
        // Use a slight delay to ensure the auth state has fully propagated
        Timer(const Duration(milliseconds: 300), () {
          router.go('/profile');
        });
      }
    }
  } catch (e) {
    talker.error('Error checking email verification status', e);
  }
}
