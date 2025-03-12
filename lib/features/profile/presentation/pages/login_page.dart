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

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              errorMessage =
                  'No account found with this email address. Please check your email or create a new account.';
              break;
            case 'wrong-password':
              errorMessage =
                  'Incorrect password. Please try again or use the "Forgot Password" option below.';
              break;
            case 'invalid-email':
              errorMessage = 'Please enter a valid email address.';
              break;
            case 'user-disabled':
              errorMessage =
                  'This account has been disabled. Please contact support for assistance.';
              break;
            case 'too-many-requests':
              errorMessage =
                  'Too many failed login attempts. Please try again later or reset your password.';
              break;
            case 'INVALID_LOGIN_CREDENTIALS':
              errorMessage =
                  'Invalid login credentials. Please check your email and password.';
              break;
            case 'invalid-credential':
              errorMessage =
                  'The authentication credentials are invalid. Please check your email and password.';
              break;
            default:
              if (e.message?.contains('not verified') ?? false) {
                errorMessage =
                    'Your email address has not been verified. A new verification email has been sent. Please check your inbox and spam folder, then try again.';
              } else {
                errorMessage = 'Sign in failed: ${e.message}';
              }
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
          // Handle specific errors for Google linking
          if (linkError is FirebaseAuthException) {
            if (linkError.code == 'credential-already-in-use') {
              setState(() {
                _isLoading = false;
              });
            } else {
              // For other Firebase errors, show the error message
              setState(() {
                _isLoading = false;
              });
            }
          } else {
            // For non-Firebase errors, rethrow
            rethrow;
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

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'account-exists-with-different-credential':
              errorMessage =
                  'An account already exists with the same email address but different sign-in credentials. Please sign in using your original provider.';
              break;
            case 'invalid-credential':
              errorMessage =
                  'The sign-in credential is invalid. Please try again.';
              break;
            case 'operation-not-allowed':
              errorMessage =
                  'Google sign-in is not enabled for this project. Please contact support.';
              break;
            case 'user-disabled':
              errorMessage =
                  'This account has been disabled. Please contact support for assistance.';
              break;
            case 'user-not-found':
              errorMessage =
                  'No account found with this email address. Please check your email or create a new account.';
              break;
            case 'wrong-password':
              errorMessage =
                  'Incorrect password. Please try again or use the "Forgot Password" option.';
              break;
            case 'invalid-verification-code':
              errorMessage =
                  'The verification code is invalid. Please try again with a new code.';
              break;
            case 'invalid-verification-id':
              errorMessage =
                  'The verification ID is invalid. Please restart the verification process.';
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
