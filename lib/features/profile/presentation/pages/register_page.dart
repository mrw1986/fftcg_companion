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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Account created successfully. Please check your email for verification.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 10), // Longer duration
            action: SnackBarAction(
              label: 'OK',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
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
                  'Password is too weak. Please use a stronger password';
              break;
            case 'operation-not-allowed':
              errorMessage = 'Email/password accounts are not enabled';
              break;
            default:
              errorMessage = 'Registration failed: ${e.message}';
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully with Google'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const ThemedLogo(height: 150),
                  const SizedBox(height: 24),
                  if (isAnonymous)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
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
                          color: Theme.of(context)
                                  .extension<ContrastExtension>()
                                  ?.onSurfaceWithContrast ??
                              Theme.of(context).colorScheme.onSurface,
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
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
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
                  const SizedBox(height: 24),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  GoogleSignInButton(
                    onPressed: () async {
                      await _signInWithGoogle();
                    },
                    onError: (e) {
                      talker.error('Google Sign-In error in register page: $e');
                      // Show a more detailed error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Google Sign-In failed: ${e.toString()}'),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 10),
                          action: SnackBarAction(
                            label: 'OK',
                            textColor: Colors.white,
                            onPressed: () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    },
                    text: isAnonymous
                        ? 'Link with Google'
                        : 'Register with Google',
                  ),
                ],
              ),
            ),
    );
  }
}
