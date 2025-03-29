import 'package:flutter/material.dart';

/// A dialog that prompts the user to choose whether to merge anonymous data
/// into their signed-in account or discard it.
Future<bool?> showMergeDataDecisionDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Merge Anonymous Data?'),
      content: const Text(
        'You have existing data as a guest. Would you like to merge it into your signed-in account, or discard it and start fresh?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Discard'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Merge'),
        ),
      ],
    ),
  );
}
