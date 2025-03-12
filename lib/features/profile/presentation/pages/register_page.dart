import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';
import 'package:fftcg_companion/shared/widgets/themed_logo.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPasswordRequirements = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final authState = ref.read(authStateProvider);

      // If user is anonymous, link the account
      if (authState.isAnonymous) {
        await authService.linkWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Otherwise create a new account
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        // Show success message with action button
        showThemedSnackBar(
          context: context,
          message:
              'Account created successfully. Please check your email for verification.',
          isError: false,
          duration: const Duration(seconds: 10),
        );

        // Navigate to profile page
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show user-friendly error message as SnackBar
      if (mounted) {
        String errorMessage = 'Failed to create account';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              errorMessage =
                  'An account already exists with this email address';
              break;
            case 'invalid-email':
              errorMessage = 'Please enter a valid email address';
              break;
            case 'weak-password':
              errorMessage =
                  'Password is too weak. Please use a password with at least 8 characters, '
                  'including uppercase, lowercase, numeric, and special characters.';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Email/password accounts are not enabled';
              break;
            default:
              errorMessage = 'Registration failed: ${e.message}';
          }
        }

        showThemedSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
          duration: const Duration(seconds: 10),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      talker.debug('Register page: Starting Google Sign-In');
      final authService = ref.read(authServiceProvider);
      final authState = ref.read(authStateProvider);

      // If user is anonymous, link the account
      if (authState.isAnonymous) {
        talker.debug('Register page: Linking anonymous account with Google');
        await authService.linkWithGoogle();
        talker.debug('Register page: Google linking successful');
      } else {
        // Otherwise sign in with Google
        talker.debug('Register page: Creating new account with Google');
        await authService.signInWithGoogle();
        talker.debug('Register page: Google Sign-In successful');
      }

      if (mounted) {
        // Show success message with action button
        showThemedSnackBar(
          context: context,
          message: 'Account created successfully with Google',
          isError: false,
          duration: const Duration(seconds: 5),
        );

        // Navigate to profile page
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show user-friendly error message as SnackBar
      if (mounted) {
        String errorMessage = 'Failed to sign in with Google';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'account-exists-with-different-credential':
              errorMessage =
                  'An account already exists with the same email address but different sign-in credentials';
              break;
            case 'invalid-credential':
              errorMessage = 'The sign-in credential is invalid';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Google sign-in is not enabled for this project';
              break;
            case 'user-disabled':
              errorMessage = 'This account has been disabled';
              break;
            default:
              errorMessage = 'Google sign-in failed: ${e.message}';
          }
        } else if (e.toString().contains('sign in was cancelled')) {
          errorMessage = 'Google sign-in was cancelled';
        }

        showThemedSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
          duration: const Duration(seconds: 10),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isAnonymous = authState.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAnonymous ? 'Complete Registration' : 'Register'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const ThemedLogo(height: 120), // Reduced height
                    const SizedBox(height: 16), // Reduced spacing
                    if (isAnonymous)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin:
                            const EdgeInsets.only(bottom: 16), // Reduced margin
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(51), // 0.2 * 255 = 51
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                    .extension<ContrastExtension>()
                                    ?.primaryWithContrast ??
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha(128),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'You\'re currently using the app without an account. Complete your registration to save your collection, decks, and settings.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password (8+ characters)',
                              border: const OutlineInputBorder(),
                              helperText:
                                  'Must include uppercase, lowercase, number, and special character',
                              helperMaxLines: 2,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                              ),
                            ),
                            obscureText: !_showPassword,
                            onTap: () {
                              setState(() {
                                _showPasswordRequirements = true;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              // Check for uppercase
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return 'Password must include an uppercase letter';
                              }
                              // Check for lowercase
                              if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return 'Password must include a lowercase letter';
                              }
                              // Check for number
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return 'Password must include a number';
                              }
                              // Check for special character
                              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                  .hasMatch(value)) {
                                return 'Password must include a special character';
                              }
                              return null;
                            },
                          ),
                          if (_showPasswordRequirements) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withAlpha(128), // 0.5 * 255 = 128
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                  _showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => setState(() =>
                                    _showConfirmPassword =
                                        !_showConfirmPassword),
                              ),
                            ),
                            obscureText: !_showConfirmPassword,
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
                          const SizedBox(height: 24),
                          Center(
                            child: StyledButton(
                              onPressed: _registerWithEmailAndPassword,
                              text: isAnonymous
                                  ? 'Complete Registration'
                                  : 'Register',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add Google Sign-In button below the Complete Registration button (no divider)
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      onPressed: () async {
                        await _signInWithGoogle();
                      },
                      onError: (e) {
                        talker
                            .error('Google Sign-In error in register page: $e');
                        // Show a more detailed error message
                        showThemedSnackBar(
                          context: context,
                          message: 'Google Sign-In failed: ${e.toString()}',
                          isError: true,
                          duration: const Duration(seconds: 10),
                        );
                      },
                      text: isAnonymous
                          ? 'Continue with Google'
                          : 'Register with Google',
                    ),

                    if (!isAnonymous) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => context.go('/profile/login'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              foregroundColor: Theme.of(context)
                                      .extension<ContrastExtension>()
                                      ?.primaryWithContrast ??
                                  Theme.of(context).colorScheme.primary,
                            ),
                            child: const Text('Already have an account? Login'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
