import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget for displaying account actions like sign out and delete account
class ProfileAccountActions extends ConsumerWidget {
  const ProfileAccountActions({
    super.key,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onShowReauthDialog,
  });

  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onShowReauthDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Sign Out
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              subtitle: const Text('Sign out of your account'),
              onTap: onSignOut,
            ),

            const Divider(),

            // Delete Account
            ListTile(
              leading: Icon(Icons.delete_forever, color: colorScheme.error),
              title: Text('Delete Account',
                  style: TextStyle(color: colorScheme.error)),
              subtitle: const Text(
                'Permanently delete your account and all associated data',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              onTap: () => _showDeleteAccountConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account?',
          style: TextStyle(
            color: colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.\n\n'
          'You will need to re-authenticate before deleting your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onShowReauthDialog();
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}
