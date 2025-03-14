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

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // If user is anonymous, we need to handle linking differently
      if (authState.isAnonymous) {
        // First check if the account exists by trying to sign in
        try {
          // Create a secondary auth instance to check if the account exists
          // without affecting the current user
          final secondaryAuth = FirebaseAuth.instance;
          await secondaryAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // If we get here, the account exists, so we can link it
          await authService.linkWithEmailAndPassword(email, password);

          if (mounted) {
            context.go('/profile');
          }
        } catch (signInError) {
          // Check if the error is because the user doesn't exist
          if (signInError is FirebaseAuthException &&
              (signInError.code == 'user-not-found' ||
                  signInError.code == 'wrong-password')) {
            // Show a specific error message for this case
            setState(() {
              _isLoading = false;
            });
          } else {
            // For other errors, rethrow to be caught by the outer catch
            rethrow;
          }
        }
      } else {
        // Normal sign in for non-anonymous users
        await authService.signInWithEmailAndPassword(email, password);

        if (mounted) {
          context.go('/profile');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show user-friendly error message as SnackBar
      if (mounted) {
        String errorMessage =
            'Failed to sign in. Please check your email and password.';
        bool isError = true;

        if (e is FirebaseAuthException) {
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e);

          // Don't show cancellation as an error
          if (e.code == 'cancelled-by-user') {
            isError = false;
          }
        } else {
          errorMessage = e.toString();
        }

        showThemedSnackBar(
          context: context,
          message: errorMessage,
          isError: isError,
          duration: isError
              ? const Duration(seconds: 10)
              : const Duration(seconds: 3),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      talker.debug('Login page: Starting Google Sign-In');
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);

      // If user is anonymous, link the account instead of creating a new one
      if (authState.isAnonymous) {
        try {
          talker.debug('Login page: Calling authService.linkWithGoogle()');
          await authService.linkWithGoogle();
          talker.debug('Login page: Google linking successful');

          if (mounted) {
            context.go('/profile');
          }
        } catch (linkError) {
          setState(() {
            _isLoading = false;
          });

          // Show user-friendly error message
          if (mounted) {
            String errorMessage = 'Failed to sign in with Google';
            bool isError = true;

            if (linkError is FirebaseAuthException) {
              errorMessage = authService.getReadableAuthError(linkError);

              // Don't show cancellation as an error
              if (linkError.code == 'cancelled-by-user') {
                isError = false;
                talker.debug('Showing cancellation message');
              } else {
                talker.debug('Showing error message: $errorMessage');
              }
            } else if (linkError.toString().contains('sign in was cancelled')) {
              errorMessage =
                  'Sign-in was cancelled. You can try again when you\'re ready.';
              isError = false;
              talker
                  .debug('Showing cancellation message for non-Firebase error');
            } else {
              errorMessage = linkError.toString();
              talker.debug('Showing non-Firebase error: $errorMessage');
            }

            showThemedSnackBar(
              context: context,
              message: errorMessage,
              isError: isError,
              duration: isError
                  ? const Duration(seconds: 10)
                  : const Duration(seconds: 3),
            );
          }
        }
      } else {
        // Normal Google sign in for non-anonymous users
        talker.debug('Login page: Calling authService.signInWithGoogle()');
        await authService.signInWithGoogle();
        talker.debug('Login page: Google Sign-In successful');

        if (mounted) {
          context.go('/profile');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show user-friendly error message as SnackBar
      if (mounted) {
        String errorMessage = 'Failed to sign in with Google';
        bool isError = true;

        if (e is FirebaseAuthException) {
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e);

          // Don't show cancellation as an error
          if (e.code == 'cancelled-by-user') {
            isError = false;
          }
        } else if (e.toString().contains('sign in was cancelled')) {
          errorMessage =
              'Sign-in was cancelled. You can try again when you\'re ready.';
          isError = false;
        } else {
          errorMessage = e.toString();
        }

        showThemedSnackBar(
          context: context,
          message: errorMessage,
          isError: isError,
          duration: isError
              ? const Duration(seconds: 10)
              : const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            ref.watch(authStateProvider).isAnonymous ? 'Account' : 'Login'),
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
                    if (ref.watch(authStateProvider).isAnonymous)
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You have two options:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Link this anonymous account to preserve your current data',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2. Sign in with an existing account (will replace anonymous data)',
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Anonymous accounts are deleted after 30 days of inactivity.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
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
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () => setState(
                                    () => _showPassword = !_showPassword),
                                tooltip: _showPassword
                                    ? 'Hide password'
                                    : 'Show password',
                              ),
                            ),
                            obscureText: !_showPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: StyledButton(
                              onPressed: _signInWithEmailAndPassword,
                              text: ref.watch(authStateProvider).isAnonymous
                                  ? 'Sign In / Link Account'
                                  : 'Login',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Move Google sign-in button here - below the Sign In / Link Account button
                    if (ref.watch(authStateProvider).isAnonymous)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: GoogleSignInButton(
                          onPressed: () async {
                            await _signInWithGoogle();
                          },
                          onError: (e) {
                            talker.error(
                                'Google Sign-In error in login page: $e');
                            showThemedSnackBar(
                              context: context,
                              message: 'Google Sign-In failed: ${e.toString()}',
                              isError: true,
                              duration: const Duration(seconds: 10),
                            );
                          },
                          text: 'Continue with Google',
                        ),
                      ),

                    const SizedBox(height: 8), // Reduced spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/profile/register'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            foregroundColor: Theme.of(context)
                                    .extension<ContrastExtension>()
                                    ?.primaryWithContrast ??
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: Text(ref.watch(authStateProvider).isAnonymous
                              ? 'Create a new account'
                              : 'Don\'t have an account? Register'),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () =>
                              context.go('/profile/reset-password'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            foregroundColor: Theme.of(context)
                                    .extension<ContrastExtension>()
                                    ?.primaryWithContrast ??
                                Theme.of(context).colorScheme.primary,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    // Only show the Google button here for non-anonymous users
                    if (!ref.watch(authStateProvider).isAnonymous) ...[
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),
                      GoogleSignInButton(
                        onPressed: () async {
                          await _signInWithGoogle();
                        },
                        onError: (e) {
                          talker
                              .error('Google Sign-In error in login page: $e');
                          showThemedSnackBar(
                            context: context,
                            message: 'Google Sign-In failed: ${e.toString()}',
                            isError: true,
                            duration: const Duration(seconds: 10),
                          );
                        },
                        text: 'Sign in with Google',
                      ),
                    ]
                  ],
                ),
              ),
            ),
    );
  }
}
