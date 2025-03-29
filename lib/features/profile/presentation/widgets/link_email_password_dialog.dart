import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';

class LinkEmailPasswordDialog extends ConsumerStatefulWidget {
  const LinkEmailPasswordDialog({
    super.key,
    required this.onSuccess,
    this.initialEmail, // Add optional parameter
  });

  final VoidCallback onSuccess;
  final String? initialEmail; // Add optional parameter

  @override
  ConsumerState<LinkEmailPasswordDialog> createState() =>
      _LinkEmailPasswordDialogState();
}

class _LinkEmailPasswordDialogState
    extends ConsumerState<LinkEmailPasswordDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocusNode = FocusNode(); // Add FocusNode
  bool _isPasswordFocused = false; // State to track focus

  @override
  void initState() {
    super.initState(); // Call super.initState first
    // Add listener to FocusNode
    _passwordFocusNode.addListener(_onPasswordFocusChange);

    // Use the passed-in initialEmail if available to pre-populate
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
    // DO NOT read provider state here, rely on constructor parameter
  }

  @override
  void dispose() {
    _passwordFocusNode
        .removeListener(_onPasswordFocusChange); // Remove listener
    _passwordFocusNode.dispose(); // Dispose FocusNode
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Listener for focus changes
  void _onPasswordFocusChange() {
    setState(() {
      _isPasswordFocused = _passwordFocusNode.hasFocus;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  Future<void> _linkEmailPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).user;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if user is signed in with Google
      final hasGoogleProvider = user?.providerData.any(
            (element) => element.providerId == 'google.com',
          ) ??
          false;

      if (hasGoogleProvider && !user!.isAnonymous) {
        // Use the new method for Google users
        await ref.read(linkEmailPasswordToGoogleProvider(
                EmailPasswordCredentials(email: email, password: password))
            .future);
      } else {
        // Use the standard method for anonymous users
        // Corrected method call
        await ref.read(authServiceProvider).linkEmailAndPasswordToAnonymous(
              email,
              password,
            );
      }

      if (mounted) {
        // Invalidate providers to force UI refresh
        ref.invalidate(authStateProvider);
        ref.invalidate(currentUserProvider);

        // Wait a moment for providers to update before closing dialog
        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          // Add mounted check
          // Show verification email notification with consistent styling
          SnackBarHelper.showSuccessSnackBar(
            context: context,
            message:
                'Email/password authentication added successfully. Please check your email to verify your account.',
            duration: const Duration(seconds: 6),
          );

          Navigator.of(context).pop();
          widget
              .onSuccess(); // Call the onSuccess callback provided by the parent
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Handle specific error cases
        if (e is FirebaseAuthException) {
          if (e.code == 'requires-recent-login') {
            // Show a more specific message for re-authentication requirement
            SnackBarHelper.showErrorSnackBar(
              context: context,
              message:
                  'For security reasons, you need to re-authenticate before adding a password. Please sign out and sign in again, then try adding a password.',
              duration: const Duration(seconds: 6),
            );
            // Close the dialog since re-authentication is needed
            Navigator.of(context).pop();
            return;
          } else if (e.code == 'email-already-in-use' ||
              e.code == 'credential-already-in-use') {
            SnackBarHelper.showErrorSnackBar(
              context: context,
              message: 'This email is already associated with another account.',
              duration: const Duration(seconds: 4),
            );
            return;
          } else if (e.code == 'provider-already-linked') {
            SnackBarHelper.showErrorSnackBar(
              context: context,
              message:
                  'Email/password authentication is already set up for this account.',
              duration: const Duration(seconds: 4),
            );
            return;
          }
        }

        // Default error handling
        SnackBarHelper.showErrorSnackBar(
          context: context,
          message: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Removed unused variables: user, hasGoogleProvider

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.password_outlined, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Add Email/Password'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set a password for your account. This will allow you to sign in with email and password.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                // REMOVED: enabled property to make it always editable
                // enabled: !hasGoogleProvider || user!.isAnonymous,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  // Simple email validation
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                focusNode: _passwordFocusNode, // Assign FocusNode
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters long.';
                  }
                  // Check for uppercase letter
                  if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                    return 'Password must contain an uppercase letter.';
                  }
                  // Check for lowercase letter
                  if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
                    return 'Password must contain a lowercase letter.';
                  }
                  // Check for numeric character
                  if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
                    return 'Password must contain a number.';
                  }
                  // Check for special character
                  if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])')
                      .hasMatch(value)) {
                    return 'Password must contain a special character.';
                  }
                  return null; // Password is valid
                },
              ),
              // Conditionally show requirements based on focus state
              if (_isPasswordFocused) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerLow, // Use a slightly different background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Requirements:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('• At least 8 characters long'),
                      Text('• At least one uppercase letter (A-Z)'),
                      Text('• At least one lowercase letter (a-z)'),
                      Text('• At least one number (0-9)'),
                      Text(
                          '• At least one special character (!@#\$%^&*(),.?":{}|<>)'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
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
                    return 'Please confirm your password';
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _isLoading ? null : _linkEmailPassword,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('Add'),
        ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
