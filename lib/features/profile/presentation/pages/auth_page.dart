import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';
import 'package:fftcg_companion/shared/widgets/themed_logo.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
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

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account not found. Please check your credentials or create a new account.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              );
            }
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
            'Failed to sign in. Please check your credentials and try again.';
        bool isError = true;

        // Log the error for debugging
        talker.error('Error signing in with email/password: $e');

        if (e is FirebaseAuthException) {
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e);

          // Special handling for specific error codes
          switch (e.code) {
            case 'cancelled-by-user':
              isError = false;
              break;
            case 'user-not-found':
              // Show a dialog with options to register or try again
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Account Not Found'),
                    content: const Text(
                        'No account found with this email address. Would you like to create a new account?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Try Again'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/profile/register');
                        },
                        child: const Text('Create Account'),
                      ),
                    ],
                  );
                },
              );
              break;
            case 'wrong-password':
              // Show a dialog with options to reset password or try again
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Incorrect Password'),
                    content: const Text(
                        'The password you entered is incorrect. Would you like to reset your password?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Try Again'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/profile/reset-password');
                        },
                        child: const Text('Reset Password'),
                      ),
                    ],
                  );
                },
              );
              break;
            case 'too-many-requests':
              errorMessage =
                  'Too many sign-in attempts. Please try again later or reset your password.';
              break;
            case 'invalid-credential':
              errorMessage =
                  'Invalid login credentials. Please check your email and password.';
              break;
            case 'network-request-failed':
              errorMessage =
                  'Network error. Please check your internet connection and try again.';
              break;
          }
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: isError
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.primaryContainer,
            duration: isError
                ? const Duration(seconds: 10)
                : const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: isError
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
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
      talker.debug('Auth page: Starting Google Sign-In');
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);

      // If user is anonymous, link the account instead of creating a new one
      if (authState.isAnonymous) {
        try {
          talker.debug('Auth page: Calling authService.linkWithGoogle()');
          await authService.linkWithGoogle();
          talker.debug('Auth page: Google linking successful');

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

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage,
                  style: TextStyle(
                    color: isError
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                backgroundColor: isError
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
                duration: isError
                    ? const Duration(seconds: 10)
                    : const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: isError
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      } else {
        // Normal Google sign in for non-anonymous users
        talker.debug('Auth page: Calling authService.signInWithGoogle()');
        await authService.signInWithGoogle();
        talker.debug('Auth page: Google Sign-In successful');

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

        // Log the error for debugging
        talker.error('Error signing in with Google: $e');

        if (e is FirebaseAuthException) {
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e);

          // Special handling for specific error codes
          switch (e.code) {
            case 'cancelled-by-user':
              isError = false;
              break;
            case 'account-exists-with-different-credential':
              errorMessage =
                  'An account already exists with the same email address but different sign-in credentials. Please sign in using your original provider.';
              break;
            case 'network-request-failed':
              errorMessage =
                  'Network error. Please check your internet connection and try again.';
              break;
          }
        } else if (e.toString().contains('sign in was cancelled')) {
          errorMessage =
              'Sign-in was cancelled. You can try again when you\'re ready.';
          isError = false;
        } else if (e.toString().contains('network_error')) {
          errorMessage =
              'Network error occurred. Please check your internet connection and try again.';
        } else if (e.toString().contains('popup_closed')) {
          errorMessage =
              'Sign-in popup was closed before completing the process. Please try again.';
          isError = false;
        } else {
          errorMessage = e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(
                color: isError
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            backgroundColor: isError
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.primaryContainer,
            duration: isError
                ? const Duration(seconds: 10)
                : const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: isError
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onPrimaryContainer,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBarFactory.createAppBar(context, 'Sign In'),
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
                    const ThemedLogo(height: 120),
                    const SizedBox(height: 16),

                    // Information banner for anonymous users
                    if (isAnonymous)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary,
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
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Link this anonymous account to preserve your current data',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2. Sign in with an existing account (will replace anonymous data)',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Anonymous accounts are deleted after 30 days of inactivity.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onPrimaryContainer,
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
                                  color: colorScheme.primary,
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
                              text: isAnonymous ? 'Sign In' : 'Sign In',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      onPressed: () async {
                        await _signInWithGoogle();
                      },
                      onError: (e) {
                        talker.error('Google Sign-In error: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Google Sign-In failed: ${e.toString()}',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                              ),
                            ),
                            backgroundColor: colorScheme.errorContainer,
                            duration: const Duration(seconds: 10),
                          ),
                        );
                      },
                      text: 'Continue with Google',
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => context.go('/profile/register'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            foregroundColor: colorScheme.primary,
                          ),
                          child: const Text('Create a new account'),
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
                            foregroundColor: colorScheme.primary,
                          ),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
