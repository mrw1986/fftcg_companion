import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/account_settings_page.dart';

// Removed emailVerificationDetectedProvider - already defined in auth_provider.dart

/// Provider that monitors and handles email update completion
final emailUpdateCompletionProvider =
    NotifierProvider<EmailUpdateCompletionNotifier, bool>(() {
  return EmailUpdateCompletionNotifier();
});

class EmailUpdateCompletionNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Watch auth state and pending email
    ref.watch(authNotifierProvider);
    ref.watch(emailUpdateNotifierProvider);

    // Set up listener for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      _checkEmailUpdate(previous, next);
    });

    // Return false as initial value (no completion detected)
    return false;
  }

  void _checkEmailUpdate(AuthState? previous, AuthState next) async {
    // Create local copies of all values to prevent provider access during transitions
    final user = next.user;
    final previousUser = previous?.user;
    final bool wasVerified = previousUser?.emailVerified ?? false;
    final bool isVerified = user?.emailVerified ?? false;

    // Detect verification status changes
    if (!wasVerified && isVerified) {
      talker.info('Email verification detected! Setting verified flag.');
      // Use the provider from auth_provider.dart
      ref.read(emailVerificationDetectedProvider.notifier).update((_) => true);
    }

    // Safely retrieve pending email with error handling
    String? pendingEmail;
    String originalEmail = '';

    // Error boundary for provider state access
    try {
      final emailUpdateState = ref.read(emailUpdateNotifierProvider);
      pendingEmail = emailUpdateState.pendingEmail;
      originalEmail = ref.read(originalEmailForUpdateCheckProvider);
    } catch (e) {
      talker.error('Error reading provider state during email update check', e);
      // Continue with null/default values
      pendingEmail = null;
      originalEmail = '';
    }

    talker.debug('EmailUpdateCompletionNotifier: Checking email update...');
    talker.debug(
        'Current user email: ${user?.email}, verified: ${user?.emailVerified}');
    talker.debug(
        'Previous user email: ${previousUser?.email}, verified: ${previousUser?.emailVerified}');
    talker.debug('Pending email: $pendingEmail');
    talker.debug('Original email: $originalEmail');

    // Clear states if user is null (signed out) and we have pending/original email
    if (user == null && (pendingEmail != null || originalEmail.isNotEmpty)) {
      talker.info('User signed out during email update, clearing states');
      try {
        ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
        ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
        state = false; // Reset completion state in our Notifier
      } catch (e) {
        talker.error('Error clearing provider state during sign-out', e);
      }
      return;
    }

    // Quick check for email changes without server refresh
    if (user != null &&
        previousUser != null &&
        user.email != previousUser.email &&
        pendingEmail != null &&
        user.email == pendingEmail) {
      talker.info('Email change detected from auth state change!');
      _handleEmailUpdateCompletion(pendingEmail);
      return;
    }

    // Full server-side check for email updates if we have a user and either pending or original email
    if (user != null && (pendingEmail != null || originalEmail.isNotEmpty)) {
      try {
        // Store current email before reload
        final currentEmail = user.email;

        // Attempt token refresh with error recovery
        bool tokenRefreshed = false;
        try {
          // Progressive token refresh strategy
          talker.debug('Attempting token refresh without force...');
          await user.getIdToken(false);
          tokenRefreshed = true;
          talker.debug('Token refreshed successfully without force');
        } catch (e) {
          talker.debug('Token refresh without force failed: $e');

          // Check if this is a token expiration (which is actually expected after email verification)
          if (e is FirebaseAuthException &&
              (e.code == 'user-token-expired' || e.code.contains('token'))) {
            talker.info(
                'Token expired - this is expected after email verification');

            try {
              // Try with force
              await user.getIdToken(true);
              tokenRefreshed = true;
              talker.debug(
                  'Token refreshed successfully with force after expiration');
            } catch (forceError) {
              talker.error('Force token refresh also failed after expiration',
                  forceError);
              // This is actually expected sometimes after email verification
              // Continue with reload anyway
            }
          } else {
            // Try with force for other error types
            try {
              await user.getIdToken(true);
              tokenRefreshed = true;
              talker.debug('Token refreshed successfully with force');
            } catch (tokenError) {
              talker.error('Token refresh with force also failed', tokenError);
              // Continue with reload attempt anyway
            }
          }
        }

        // Force reload user to get latest data
        bool userReloaded = false;
        try {
          await user.reload();
          userReloaded = true;
          talker.debug('User reloaded successfully');
        } catch (reloadError) {
          if (reloadError is FirebaseAuthException &&
              (reloadError.code == 'user-token-expired' ||
                  reloadError.code == 'user-disabled' ||
                  reloadError.code == 'user-not-found')) {
            talker.warning(
                'User session expired during email update check: ${reloadError.code}');
            // Clear states since we can't verify
            try {
              ref
                  .read(emailUpdateNotifierProvider.notifier)
                  .clearPendingEmail();
              ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
              state = false; // Reset completion state
            } catch (stateError) {
              talker.error('Error clearing provider state after session expiry',
                  stateError);
            }
            return;
          }

          talker.error(
              'Error reloading user during email update check', reloadError);
          // Continue with potentially stale user data
        }

        // Get fresh user instance after reload
        final reloadedUser = FirebaseAuth.instance.currentUser;
        if (reloadedUser != null) {
          final newEmail = reloadedUser.email;
          final isEmailVerified = reloadedUser.emailVerified;

          // Special handling for email verification change
          if (!wasVerified && isEmailVerified) {
            talker.info('Email verification status changed: now verified!');
            // Use the provider from auth_provider.dart
            ref
                .read(emailVerificationDetectedProvider.notifier)
                .update((_) => true);
          }

          // Check if email changed from original
          if (originalEmail.isNotEmpty &&
              newEmail != null &&
              newEmail != originalEmail) {
            talker.info(
                'Email change detected from original. Old: $originalEmail, New: $newEmail');
            _handleEmailUpdateCompletion(newEmail);
          }
          // Check if email matches pending
          else if (pendingEmail != null && newEmail == pendingEmail) {
            talker.info('Email matches pending email: $newEmail');
            _handleEmailUpdateCompletion(newEmail);
          }
          // Check if email changed from current
          else if (currentEmail != null &&
              newEmail != null &&
              currentEmail != newEmail) {
            talker.info(
                'Email changed but doesn\'t match pending. Current: $currentEmail, New: $newEmail');
            _handleEmailUpdateCompletion(newEmail);
          }
          // Check if we refreshed tokens/reloaded but no changes detected
          else if ((tokenRefreshed || userReloaded) && pendingEmail != null) {
            talker.debug(
                'Token refreshed or user reloaded, but email still unchanged');

            // If verification status changed but email didn't, we may be in a transitional state
            if (!wasVerified && isEmailVerified && newEmail != pendingEmail) {
              talker.info(
                  'Special case: Email verified but not yet updated to $pendingEmail. Current: $newEmail');
              // Don't clear pending email, wait for the actual email change
            }
          }
        } else {
          talker
              .warning('User is null after reload - session may have expired');
          // Clear states since we can't verify
          try {
            ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
            ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
            state = false; // Reset completion state
          } catch (e) {
            talker.error(
                'Error clearing provider state with null user after reload', e);
          }
        }
      } catch (e) {
        talker.error('Error during email update check', e);

        // Handle specific token errors
        if (e.toString().contains('user-token-expired')) {
          talker.warning('User token expired during email update check');
          // Clear states since we can't verify
          try {
            ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
            ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
            state = false; // Reset completion state
          } catch (stateError) {
            talker.error('Error clearing provider state after token expiration',
                stateError);
          }
        }
      }
    }
  }

  /// Helper method to handle email update completion
  void _handleEmailUpdateCompletion(String? newEmail) {
    if (newEmail == null) {
      talker.warning(
          'Attempted to handle email update completion with null email');
      return;
    }

    talker.info('Email update completed to: $newEmail');

    try {
      // Clear states since update is complete
      ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
      ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';

      // Force auth state refresh
      ref.invalidate(authNotifierProvider);

      // Update our completion state
      state = true;
    } catch (e) {
      talker.error(
          'Error updating provider state on email update completion', e);
    }
  }
}
