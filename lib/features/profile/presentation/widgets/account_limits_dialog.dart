import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';
import 'package:fftcg_companion/core/storage/hive_storage.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Shows account limits and verification requirements to users
class AccountLimitsDialog extends ConsumerWidget {
  const AccountLimitsDialog({super.key});

  // Set to false before release
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
          barrierDismissible: false, // Added this line
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
    final colorScheme = Theme.of(context).colorScheme; // Get colorScheme

    talker.debug('Building AccountLimitsDialog:');
    talker.debug('User: ${user?.email}');
    talker.debug('Is anonymous: $isAnonymous');
    talker.debug('Is email verified: $isEmailVerified');

    return AlertDialog(
      shape: RoundedRectangleBorder(
        // Added shape
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        // Changed title
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Account Information'), // Changed title text
        ],
      ),
      content: SingleChildScrollView(
        // Wrapped content
        child: Column(
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
      ),
      actions: [
        if (isAnonymous) ...[
          // Changed to FilledButton for primary actions
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () {
              context.pop(); // Use context.pop()
              context.go('/profile/register');
            },
            child: const Text('Create Account'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () {
              context.pop(); // Use context.pop()
              context.go('/profile/auth');
            },
            child: const Text('Sign In'),
          ),
        ] else if (!isEmailVerified)
          // Changed to FilledButton
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
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
                context.pop(); // Use context.pop()
              }
            },
            child: const Text('Resend Verification'),
          ),
        // Standard Close button (styled like Cancel)
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          onPressed: () => context.pop(), // Use context.pop()
          child: const Text('Close'),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Added padding
    );
  }
}
