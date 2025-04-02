import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';
import 'package:fftcg_companion/core/storage/hive_storage.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Shows account limits and verification requirements to users
class AccountLimitsDialog extends ConsumerWidget {
  const AccountLimitsDialog({super.key});

  // TODO: Set to false before release
  static final bool _debugDisableTimeCheck = false;
  static bool _isShowing = false;

  /// Shows the dialog if needed based on user state and last shown time
  static Future<void> showIfNeeded(BuildContext context) async {
    if (_isShowing) {
      talker.debug('Dialog already showing, skipping');
      return;
    }
    talker.debug('Checking if settings box is available...');
    final storage = HiveStorage();
    final isBoxAvailable = await storage.isBoxAvailable('settings');
    if (!isBoxAvailable) {
      talker.error('Settings box not available, skipping dialog');
      return;
    }

    talker.debug('Getting last shown timestamp from settings...');
    final lastShown = await storage.get<int>('last_limits_dialog_shown',
            boxName: 'settings') ??
        0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastShown = now - lastShown;

    talker
        .debug('Last shown: ${DateTime.fromMillisecondsSinceEpoch(lastShown)}');
    talker.debug(
        'Time since last shown: ${Duration(milliseconds: timeSinceLastShown)}');

    // Show once per day (24 hours = 86400000 milliseconds)
    if (_debugDisableTimeCheck || timeSinceLastShown > 86400000) {
      if (_debugDisableTimeCheck) {
        talker.debug('Debug mode: Time check disabled');
      }
      talker.debug('Time check passed, proceeding with dialog');
      talker.debug('Showing account limits dialog');
      if (!context.mounted) {
        talker.debug('Context not mounted, skipping dialog');
        return;
      }

      talker.debug('Showing dialog via showDialog');
      _isShowing = true;
      try {
        await showDialog(
          context: context,
          builder: (context) => const AccountLimitsDialog(),
        );
        talker.debug('Dialog shown successfully');
      } finally {
        _isShowing = false;
        talker.debug('Dialog flag reset');
      }

      try {
        await storage.put('last_limits_dialog_shown', now, boxName: 'settings');
        talker.debug('Updated last shown timestamp');
      } catch (e) {
        talker.error('Failed to update last shown timestamp: $e');
      }
    } else {
      talker.debug(
          'Time check failed, skipping dialog. Time since last shown: ${Duration(milliseconds: timeSinceLastShown)}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = AuthService();
    final isAnonymous = authService.isAnonymous();
    final user = authService.currentUser;
    final isEmailVerified = user?.emailVerified ?? false;

    talker.debug('Building AccountLimitsDialog:');
    talker.debug('User: ${user?.email}');
    talker.debug('Is anonymous: $isAnonymous');
    talker.debug('Is email verified: $isEmailVerified');

    return AlertDialog(
      title: const Text('Account Limits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAnonymous) ...[
            const Text(
              'You are using an anonymous account, which has the following limits:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Maximum of 50 unique cards in your collection'),
            const Text('• Some features may be restricted'),
            const SizedBox(height: 16),
            const Text(
              'Sign in or create an account to remove these limits and save your collection securely.',
            ),
          ] else if (!isEmailVerified) ...[
            const Text(
              'Please verify your email to unlock full access:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
                '• After 7 days, email verification will be required to:'),
            const Text('  - Add new cards to your collection'),
            const Text('  - Create and share decks'),
            const Text('  - Access premium features'),
            const SizedBox(height: 16),
            const Text(
              'Check your email for a verification link, or request a new one in your profile settings.',
            ),
          ],
        ],
      ),
      actions: [
        if (isAnonymous) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/profile/auth');
            },
            child: const Text('Sign In'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/profile/register');
            },
            child: const Text('Create Account'),
          ),
        ] else if (!isEmailVerified)
          TextButton(
            onPressed: () async {
              try {
                await authService.sendEmailVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification email sent!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Could not send verification email. Please try again later.',
                      ),
                    ),
                  );
                }
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Resend Verification'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
