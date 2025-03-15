import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileReauthDialog extends ConsumerWidget {
  const ProfileReauthDialog({
    super.key,
    required this.reauthEmailController,
    required this.reauthPasswordController,
    required this.showReauthPassword,
    required this.isAccountDeletion,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onCancel,
    required this.onAuthenticate,
  });

  final TextEditingController reauthEmailController;
  final TextEditingController reauthPasswordController;
  final bool showReauthPassword;
  final bool isAccountDeletion;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onCancel;
  final VoidCallback onAuthenticate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Re-authenticate',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'For security reasons, please re-enter your credentials to continue.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reauthEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reauthPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showReauthPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: onTogglePasswordVisibility,
                      tooltip: showReauthPassword
                          ? 'Hide password'
                          : 'Show password',
                    ),
                  ),
                  obscureText: !showReauthPassword,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : onAuthenticate,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Authenticate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
