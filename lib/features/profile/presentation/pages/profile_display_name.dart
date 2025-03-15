import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileDisplayName extends ConsumerWidget {
  const ProfileDisplayName({
    super.key,
    required this.displayNameController,
    required this.onUpdateProfile,
    required this.isLoading,
  });

  final TextEditingController displayNameController;
  final VoidCallback onUpdateProfile;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : onUpdateProfile,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a snackbar with a message
void showThemedSnackBar({
  required BuildContext context,
  required String message,
  required bool isError,
  Duration duration = const Duration(seconds: 4),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor:
          isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: isError
            ? colorScheme.onErrorContainer
            : colorScheme.onPrimaryContainer,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
