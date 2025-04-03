import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

/// Represents the user's choice regarding guest data when linking accounts.
enum MergeAction {
  merge, // Add guest data to existing account data.
  overwrite, // Replace account data with guest data.
  discard, // Keep account data, delete guest data.
}

/// A dialog that prompts the user to choose how to handle anonymous guest data
/// when linking to an existing account.
Future<MergeAction?> showMergeDataDecisionDialog(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog<MergeAction>(
    context: context,
    barrierDismissible: false, // User must make a choice
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.merge_type_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Handle Guest Data?'),
        ],
      ),
      content: const SingleChildScrollView(
        // Ensure content scrolls if needed
        child: Text(
          'We found data saved from when you used the app as a guest. '
          'How would you like to handle this data now that you are signing in?\n\n'
          '• Merge: Add guest data to your current account data.\n'
          '• Overwrite: Replace your current account data with the guest data.\n'
          '• Discard: Keep your current account data and delete the guest data.',
        ),
      ),
      actions: [
        // Discard Button (Less prominent, styled like Cancel)
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          onPressed: () => context.pop(MergeAction.discard), // Use context.pop
          child: const Text('Discard'),
        ),
        // Overwrite Button (Destructive)
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          onPressed: () =>
              context.pop(MergeAction.overwrite), // Use context.pop
          child: const Text('Overwrite'),
        ),
        // Merge Button (Primary Action)
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: () => context.pop(MergeAction.merge), // Use context.pop
          child: const Text('Merge'),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}

/// Shows a confirmation dialog before performing an irreversible merge/overwrite/discard action.
Future<bool> showMergeConfirmationDialog(
    BuildContext context, MergeAction action) {
  String titleText;
  String contentText;
  String confirmText;
  IconData titleIcon;
  Color confirmButtonColor;
  Color confirmButtonTextColor;
  final colorScheme = Theme.of(context).colorScheme;

  switch (action) {
    case MergeAction.merge:
      titleText = 'Confirm Merge?';
      contentText =
          'This will add your guest data to your account. This action cannot be undone.';
      confirmText = 'Merge';
      titleIcon = Icons.merge_type_outlined;
      confirmButtonColor = colorScheme.primary;
      confirmButtonTextColor = colorScheme.onPrimary;
      break;
    case MergeAction.overwrite:
      titleText = 'Confirm Overwrite?';
      contentText =
          'This will permanently replace your current account data with your guest data. This action cannot be undone.';
      confirmText = 'Overwrite';
      titleIcon = Icons.warning_amber_rounded;
      confirmButtonColor = colorScheme.error;
      confirmButtonTextColor = colorScheme.onError;
      break;
    case MergeAction.discard:
      titleText = 'Confirm Discard?';
      contentText =
          'This will permanently delete your guest data. This action cannot be undone.';
      confirmText = 'Discard';
      titleIcon = Icons.delete_sweep_outlined;
      confirmButtonColor = colorScheme.error;
      confirmButtonTextColor = colorScheme.onError;
      break;
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must confirm or cancel
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(titleIcon,
              color: action == MergeAction.merge
                  ? colorScheme.primary
                  : colorScheme.error),
          const SizedBox(width: 12),
          Text(titleText),
        ],
      ),
      content: SingleChildScrollView(
        // Wrapped content
        child: Text(contentText),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            // Styled Cancel button
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          onPressed: () => context.pop(false), // Use context.pop
          child: const Text('Cancel'),
        ),
        FilledButton(
          // Changed to FilledButton
          style: FilledButton.styleFrom(
            backgroundColor: confirmButtonColor,
            foregroundColor: confirmButtonTextColor,
          ),
          onPressed: () => context.pop(true), // Use context.pop
          child: Text(confirmText),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Added padding
    ),
  ).then((value) => value ?? false); // Return false if dialog is dismissed
}
