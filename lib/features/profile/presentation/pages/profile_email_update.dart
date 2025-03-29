import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileEmailUpdate extends ConsumerWidget {
  const ProfileEmailUpdate({
    super.key,
    required this.emailController,
    required this.onUpdateEmail,
    required this.isLoading,
    required this.user,
  });

  final TextEditingController emailController;
  final VoidCallback onUpdateEmail;
  final bool isLoading;
  final User? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user has Google auth (a verified method)
    final hasGoogleAuth = user?.providerData
            .any((userInfo) => userInfo.providerId == 'google.com') ??
        false;

    // Determine the appropriate message
    final noteText = hasGoogleAuth
        ? 'Note: You will receive a verification email to confirm this change.'
        : 'Note: You will receive a verification email to confirm this change. You will be logged out after updating your email.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'New Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: isLoading ? null : onUpdateEmail,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('Update Email'),
        ),
        const SizedBox(height: 8),
        Text(
          noteText,
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Shows a dialog to confirm email update
Future<bool> showEmailUpdateConfirmationDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  final user = FirebaseAuth.instance.currentUser;

  // Check if user has Google auth (a verified method)
  final hasGoogleAuth = user?.providerData
          .any((userInfo) => userInfo.providerId == 'google.com') ??
      false;

  // Determine the appropriate message
  final message = hasGoogleAuth
      ? 'A verification link will be sent to your new email address. Please click the link to confirm the change.'
      : 'A verification link will be sent to your new email address. Please click the link to confirm the change. You will be logged out after updating your email.';

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.email_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Confirm Email Update'),
              ],
            ),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Send Verification Email'),
              ),
            ],
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        },
      ) ??
      false;
}

/// Shows a dialog after email update is initiated
Future<void> showEmailUpdateCompletedDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  final user = FirebaseAuth.instance.currentUser;

  // Check if user has Google auth (a verified method)
  final hasGoogleAuth = user?.providerData
          .any((userInfo) => userInfo.providerId == 'google.com') ??
      false;

  // Determine the appropriate message
  final message = hasGoogleAuth
      ? 'A verification email has been sent to your new email address. Please check your inbox and click the link to finalize the email change. You will remain logged in since you have other verified authentication methods.'
      : 'A verification email has been sent to your new email address. Please check your inbox and click the link to finalize the email change. You will be logged out after verifying since this is your only authentication method.';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Verification Email Sent'),
          ],
        ),
        content: Text(message),
        actions: <Widget>[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    },
  );
}
