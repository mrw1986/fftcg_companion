import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart'; // Import logger
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart'; // Import SnackBarHelper

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetEmailSent = false;
  // final talker = Talker(); // Remove incorrect instantiation

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is logged in
    final user = ref.read(authStateProvider).user;
    if (user != null && user.email != null && user.email!.isNotEmpty) {
      _emailController.text = user.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    talker.debug(
        'Attempting to send password reset email to: ${_emailController.text.trim()}'); // Add log

    try {
      // Check if user is authenticated before attempting to sign out
      final authState = ref.read(authStateProvider);
      final isUserAuthenticated =
          authState.isAuthenticated && !authState.isAnonymous;

      await ref.read(authServiceProvider).sendPasswordResetEmail(
            _emailController.text.trim(),
          );

      // Only sign out if the user is authenticated
      if (isUserAuthenticated) {
        // Pass the flag to skip the dialog timestamp reset
        await ref
            .read(authServiceProvider)
            .signOut(); // Removed skipAccountLimitsDialog argument
      }

      setState(() {
        _resetEmailSent = true;
        _isLoading = false;
      });

      // Customize message based on authentication state
      String successMessage = isUserAuthenticated
          ? 'Password reset email sent successfully. You have been logged out for security reasons.'
          : 'Password reset email sent successfully. Please check your email for instructions.';

      // Show success message as SnackBar with action button
      if (mounted) {
        SnackBarHelper.showSnackBar(
          // Use SnackBarHelper
          context: context,
          message: successMessage,
          // Removed isError parameter
          duration: const Duration(seconds: 10),
        );
      }
    } catch (e) {
      talker.error('Error sending password reset email: $e'); // Add log
      setState(() {
        _isLoading = false;
      });

      // Show error message as SnackBar with user-friendly message
      if (mounted) {
        String errorMessage = 'Failed to send password reset email';

        if (e is FirebaseAuthException) {
          final authService = ref.read(authServiceProvider);
          // Corrected call to getReadableAuthError
          errorMessage = authService.getReadableAuthError(e.code, e.message);
        }

        SnackBarHelper.showErrorSnackBar(
          // Use SnackBarHelper
          context: context,
          message: errorMessage,
          duration: const Duration(seconds: 10),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/images/logo_transparent.png',
                    height: 150,
                  ),
                  const SizedBox(height: 24),
                  if (_resetEmailSent)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(25), // Use withAlpha for clarity
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Password reset email sent!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions to reset your password.',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => context.go('/profile/login'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text('Return to Login'),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    const Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _sendPasswordResetEmail,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text('Send Reset Link'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/profile/login'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: const Text('Back to Login'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
