import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';

class ProfileAccountActions extends ConsumerWidget {
  const ProfileAccountActions({
    super.key,
    required this.onSignOut,
    required this.onDeleteAccount,
    required this.onResetPassword,
  });

  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
            if (!user.isAnonymous &&
                user.providerData
                    .any((element) => element.providerId == 'password'))
              ListTile(
                title: const Text('Reset Password'),
                subtitle:
                    const Text('Send a password reset email to your account'),
                leading: const Icon(Icons.lock_reset_outlined),
                onTap: onResetPassword,
              ),
            ListTile(
              title: const Text('Sign Out'),
              subtitle: const Text('Sign out of your current account'),
              leading: const Icon(Icons.logout_outlined),
              onTap: onSignOut,
            ),
            if (!user.isAnonymous) ...[
              const Divider(),
              ListTile(
                title: const Text('Delete Account'),
                subtitle: const Text(
                    'Permanently delete your account and all associated data'),
                leading: const Icon(Icons.delete_forever_outlined,
                    color: Colors.red),
                onTap: onDeleteAccount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a confirmation dialog before deleting the account
Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Account?'),
            content: const Text(
              'Warning: This action cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(color: Colors.red),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete Account'),
              ),
            ],
          );
        },
      ) ??
      false;
}

/// Shows a dialog explaining that re-authentication is required
Future<bool> showReauthRequiredDialog(BuildContext context,
    {bool isForDeletion = true}) async {
  String operationText =
      isForDeletion ? 'deleting your account' : 'updating your email';

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Authentication Required'),
            content: Text(
              'For security reasons, you need to verify your identity before $operationText. '
              'Please re-enter your credentials to continue.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Re-authenticate'),
              ),
            ],
          );
        },
      ) ??
      false;
}
