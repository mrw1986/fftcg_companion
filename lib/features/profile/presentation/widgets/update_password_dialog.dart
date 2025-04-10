import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

class UpdatePasswordDialog extends ConsumerStatefulWidget {
  final Function(String) onUpdatePassword;

  const UpdatePasswordDialog({
    super.key,
    required this.onUpdatePassword,
  });

  @override
  ConsumerState<UpdatePasswordDialog> createState() =>
      _UpdatePasswordDialogState();
}

class _UpdatePasswordDialogState extends ConsumerState<UpdatePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  final FocusNode _passwordFocusNode = FocusNode();
  // Removed _isPasswordFocused state variable as it's no longer needed for conditional rendering

  @override
  void initState() {
    super.initState();
    // Removed listener as we no longer need to track focus for this
  }

  @override
  void dispose() {
    // Removed listener removal
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Removed _onPasswordFocusChange method

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  Future<void> _submitUpdatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the callback provided by the parent widget
      await widget.onUpdatePassword(_passwordController.text);

      if (mounted) {
        context.pop(); // Use context.pop()
      }
    } catch (e) {
      // Error handling is likely done in the parent widget where the actual
      // AuthService call is made, but we can show a generic message here if needed.
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update password: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.lock_reset_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Update Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your new password below.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.primary,
                    ),
                    onPressed: _togglePasswordVisibility,
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                  ),
                ),
                obscureText: !_showPassword,
                focusNode: _passwordFocusNode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long.';
                  }
                  if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                    return 'Password must contain an uppercase letter.';
                  }
                  if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                    return 'Password must contain a lowercase letter.';
                  }
                  if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                    return 'Password must contain a number.';
                  }
                  if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])')
                      .hasMatch(value)) {
                    return 'Password must contain a special character.';
                  }
                  return null; // Password is valid
                },
              ),
              // Removed the conditional rendering based on focus
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('• At least 8 characters long',
                        style: TextStyle(
                            color: colorScheme
                                .onSurfaceVariant)), // Slightly muted text
                    Text('• At least one uppercase letter (A-Z)',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    Text('• At least one lowercase letter (a-z)',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    Text('• At least one number (0-9)',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    Text(
                        '• At least one special character (!@#\$%^&*(),.?":{}|<>)',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.primary,
                    ),
                    onPressed: _togglePasswordVisibility,
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          onPressed: () => context.pop(), // Use context.pop()
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _submitUpdatePassword,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('Update'),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
