import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileEmailUpdate extends ConsumerWidget {
  const ProfileEmailUpdate({
    super.key,
    required this.emailController,
    required this.onUpdateEmail,
    required this.isLoading,
  });

  final TextEditingController emailController;
  final VoidCallback onUpdateEmail;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        const Text(
          'Note: You will receive a verification email to confirm this change. You will be logged out after updating your email.',
          style: TextStyle(
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
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update Email'),
            content: const Text(
              'After updating your email, you will be logged out for security reasons. '
              'You will need to log back in with your new email after verifying it. '
              '\n\nDo you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ) ??
      false;
}

/// Shows a dialog after email update is initiated
Future<void> showEmailUpdateCompletedDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Email Update Initiated'),
        content: const Text(
          'A verification email has been sent to your new email address. '
          'For security reasons, you will now be logged out. '
          '\n\nAfter verifying your email, please log back in with your new email address.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
