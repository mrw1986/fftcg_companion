import 'package:flutter/material.dart';

/// Shows a confirmation dialog before unlinking an authentication provider.
/// Returns true if the user confirms, false otherwise.
Future<bool> showUnlinkConfirmationDialog(
    BuildContext context, String providerName) {
  final colorScheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must make a choice
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.link_off, color: colorScheme.error),
          const SizedBox(width: 12),
          const Text('Remove Sign-in Method?'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You are about to remove $providerName as a sign-in method.\n',
            ),
            const Text(
              'What this means:\n',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '• You will no longer be able to sign in with $providerName\n'
              '• Your account and data will remain unchanged\n'
              '• You can add $providerName authentication back later in Account Settings\n\n'
              'Note: If this is your only sign-in method, you cannot remove it.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Remove'),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  ).then((value) => value ?? false); // Return false if dialog is dismissed
}
