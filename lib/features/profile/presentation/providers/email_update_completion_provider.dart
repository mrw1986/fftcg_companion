import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/account_settings_page.dart';

/// Provider that monitors and handles email update completion
final emailUpdateCompletionProvider =
    NotifierProvider<EmailUpdateCompletionNotifier, void>(() {
  return EmailUpdateCompletionNotifier();
});

class EmailUpdateCompletionNotifier extends Notifier<void> {
  @override
  void build() {
    // Watch auth state and pending email
    ref.watch(authNotifierProvider);
    ref.watch(emailUpdateNotifierProvider);

    // Set up listener for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      _checkEmailUpdate(next);
    });
  }

  void _checkEmailUpdate(AuthState authState) async {
    final user = authState.user;
    final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
    final originalEmail = ref.read(originalEmailForUpdateCheckProvider);

    talker.debug('EmailUpdateCompletionNotifier: Checking email update...');
    talker.debug('Current user email: ${user?.email}');
    talker.debug('Pending email: $pendingEmail');
    talker.debug('Original email: $originalEmail');

    // Clear states if user is null (signed out) and we have pending/original email
    if (user == null && (pendingEmail != null || originalEmail.isNotEmpty)) {
      talker.info('User signed out during email update, clearing states');
      ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
      ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
      return;
    }

    // Check for email updates if we have a user and either pending or original email
    if (user != null && (pendingEmail != null || originalEmail.isNotEmpty)) {
      try {
        // Store current email before reload
        final currentEmail = user.email;

        // Force reload user to get latest data
        await user.reload();

        // Get fresh user instance after reload
        final reloadedUser = FirebaseAuth.instance.currentUser;
        if (reloadedUser != null) {
          final newEmail = reloadedUser.email;

          // Check if email changed from original
          if (originalEmail.isNotEmpty && newEmail != originalEmail) {
            talker.info(
                'Email change detected from original. Old: $originalEmail, New: $newEmail');
            // Clear states since update is complete
            ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
            ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
            // Force auth state refresh
            ref.invalidate(authNotifierProvider);
          }
          // Check if email matches pending
          else if (pendingEmail != null && newEmail == pendingEmail) {
            talker.info('Email matches pending email: $newEmail');
            // Clear states since update is complete
            ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
            ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
            // Force auth state refresh
            ref.invalidate(authNotifierProvider);
          }
          // Check if email changed from current
          else if (currentEmail != newEmail) {
            talker.info(
                'Email changed but doesn\'t match pending. Current: $currentEmail, New: $newEmail');
            // Clear states since something changed
            ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
            ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
            // Force auth state refresh
            ref.invalidate(authNotifierProvider);
          }
        } else {
          talker
              .warning('User is null after reload - session may have expired');
          // Clear states since we can't verify
          ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
          ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
        }
      } catch (e) {
        talker.error('Error during email update check', e);
        if (e.toString().contains('user-token-expired')) {
          talker.warning('User token expired during email update check');
          // Clear states since we can't verify
          ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
          ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
        }
      }
    }
  }
}
