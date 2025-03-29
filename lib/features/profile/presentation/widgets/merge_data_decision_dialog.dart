import 'package:flutter/material.dart';

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
      title: const Text('Handle Guest Data?'),
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
        // Discard Button (Less prominent)
        TextButton(
          onPressed: () => Navigator.of(context).pop(MergeAction.discard),
          child: const Text('Discard'),
        ),
        // Overwrite Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(MergeAction.overwrite),
          child: Text(
            'Overwrite',
            style: TextStyle(
                color: colorScheme
                    .error), // Use error color for destructive action
          ),
        ),
        // Merge Button (Most prominent)
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(MergeAction.merge),
          child: const Text('Merge'),
        ),
      ],
    ),
  );
}

/// Shows a confirmation dialog before performing an irreversible merge/overwrite/discard action.
Future<bool> showMergeConfirmationDialog(
    BuildContext context, MergeAction action) {
  String title;
  String content;
  String confirmText;

  switch (action) {
    case MergeAction.merge:
      title = 'Confirm Merge?';
      content =
          'This will add your guest data to your account. This action cannot be undone.';
      confirmText = 'Merge';
      break;
    case MergeAction.overwrite:
      title = 'Confirm Overwrite?';
      content =
          'This will permanently replace your current account data with your guest data. This action cannot be undone.';
      confirmText = 'Overwrite';
      break;
    case MergeAction.discard:
      title = 'Confirm Discard?';
      content =
          'This will permanently delete your guest data. This action cannot be undone.';
      confirmText = 'Discard';
      break;
  }

  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // User must confirm or cancel
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Cancel
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                action == MergeAction.overwrite || action == MergeAction.discard
                    ? Theme.of(context)
                        .colorScheme
                        .error // Destructive action color
                    : null, // Default for merge
          ),
          onPressed: () => Navigator.of(context).pop(true), // Confirm
          child: Text(confirmText),
        ),
      ],
    ),
  ).then((value) => value ?? false); // Return false if dialog is dismissed
}
