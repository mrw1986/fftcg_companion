import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountActionsCard extends StatelessWidget {
  final User? user;
  final Function() onSignOut;
  final Function() onDeleteAccount;

  const AccountActionsCard({
    super.key,
    required this.user,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with icon
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Sign Out button
            ListTile(
              title: const Text('Sign Out'),
              subtitle: const Text('Sign out of your current account'),
              leading: Icon(
                Icons.logout_outlined,
                color: colorScheme.secondary,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: onSignOut,
            ),

            // Delete Account button (only for non-anonymous users)
            if (!user!.isAnonymous) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Delete Account'),
                subtitle: const Text(
                  'Permanently delete your account and all associated data',
                ),
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: colorScheme.error,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: onDeleteAccount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
