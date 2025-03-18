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

  void _navigateToProfile() {
    if (!mounted) return;
    context.go('/profile');
  }

  void _showError(String message, {bool isError = true}) {
    if (!mounted) return;
    showThemedSnackBar(
      context: context,
      message: message,
      isError: isError,
      duration:
          isError ? const Duration(seconds: 10) : const Duration(seconds: 3),
    );
  }

  void _setLoading(bool loading) {
    if (!mounted) return;
    setState(() {
      _isLoading = loading;
    });
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoading(true);

    try {
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // If user is anonymous, we need to handle both linking and sign-in cases
      if (authState.isAnonymous) {
        try {
          // Try to sign in directly with the existing account
          await authService.signInWithEmailAndPassword(email, password);

          // If we get here, the account exists, so sign out and sign in again
          await authService.signOut();
          await authService.signInWithEmailAndPassword(email, password);
          _navigateToProfile();
          return;
        } catch (signInError) {
          // If the error is user-not-found, try to link the account
          if (signInError is FirebaseAuthException &&
              signInError.code == 'user-not-found') {
            try {
              // Create the credential for linking
              final credential = EmailAuthProvider.credential(
                  email: email, password: password);

              // Attempt to link the account
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser == null) {
                throw FirebaseAuthException(
                    code: 'no-current-user',
                    message: 'No user is currently signed in.');
              }

              // Check if provider is already linked
              final providerData = currentUser.providerData;
              final isPasswordLinked = providerData.any(
                  (info) => info.providerId == EmailAuthProvider.PROVIDER_ID);

              if (isPasswordLinked) {
                throw FirebaseAuthException(
                    code: 'provider-already-linked',
                    message:
                        'This authentication provider is already linked to your account.');
              }

              await currentUser.linkWithCredential(credential);
              _navigateToProfile();
            } catch (linkError) {
              if (linkError is FirebaseAuthException) {
                switch (linkError.code) {
                  case 'credential-already-in-use':
                  case 'email-already-in-use':
                    // Account exists, sign out anonymous user and sign in with existing account
                    await authService.signOut();
                    await authService.signInWithEmailAndPassword(
                        email, password);
                    _navigateToProfile();
                    break;
                  case 'provider-already-linked':
                    // Show a more user-friendly error message
                    throw FirebaseAuthException(
                        code: 'provider-already-linked',
                        message:
                            'This email is already linked to your account. You can sign in directly.');
                  case 'invalid-credential':
                    throw FirebaseAuthException(
                        code: 'invalid-credential',
                        message:
                            'The provided email/password combination is incorrect.');
                  case 'weak-password':
                    throw FirebaseAuthException(
                        code: 'weak-password',
                        message:
                            'The password must be at least 6 characters long.');
                  case 'account-exists-with-different-credential':
                    // Instead of checking sign-in methods, provide a generic message
                    throw FirebaseAuthException(
                        code: 'account-exists-with-different-credential',
                        message:
                            'An account already exists with this email. Please sign in with your existing account.');
                  default:
                    rethrow;
                }
              } else {
                rethrow;
              }
            }
          } else {
            // For other errors, rethrow
            rethrow;
          }
        }
      } else {
        // Normal sign in for non-anonymous users
        try {
          await authService.signInWithEmailAndPassword(email, password);
          _navigateToProfile();
        } catch (signInError) {
          if (signInError is FirebaseAuthException) {
            switch (signInError.code) {
              case 'user-not-found':
                throw FirebaseAuthException(
                    code: 'user-not-found',
                    message:
                        'No account found with this email. Please check the email or create an account.');
              case 'wrong-password':
                throw FirebaseAuthException(
                    code: 'wrong-password',
                    message:
                        'Incorrect password. Please try again or use the "Forgot password" option.');
              case 'invalid-credential':
                throw FirebaseAuthException(
                    code: 'invalid-credential',
                    message:
                        'The provided email/password combination is incorrect.');
              case 'too-many-requests':
                throw FirebaseAuthException(
                    code: 'too-many-requests',
                    message:
                        'Too many sign-in attempts. Please try again later or reset your password.');
              default:
                rethrow;
            }
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
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

        // Log the error for debugging
        talker.error('Error in login page: ${e.code} - ${e.message}');
      } else {
        errorMessage = e.toString();
        talker.error('Non-Firebase error in login page: $e');
      }

      _showError(errorMessage, isError: isError);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInWithGoogle() async {
    _setLoading(true);

    try {
      talker.debug('Login page: Starting Google Sign-In');
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);

      // If user is anonymous, link the account instead of creating a new one
      if (authState.isAnonymous) {
        try {
          // Check if provider is already linked
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            throw FirebaseAuthException(
                code: 'no-current-user',
                message: 'No user is currently signed in.');
          }

          final providerData = currentUser.providerData;
          final isGoogleLinked = providerData
              .any((info) => info.providerId == GoogleAuthProvider.PROVIDER_ID);

          if (isGoogleLinked) {
            throw FirebaseAuthException(
                code: 'provider-already-linked',
                message: 'Google sign-in is already linked to your account.');
          }

          talker.debug('Login page: Calling authService.linkWithGoogle()');
          await authService.linkWithGoogle();
          talker.debug('Login page: Google linking successful');
          _navigateToProfile();
        } catch (linkError) {
          if (linkError is FirebaseAuthException) {
            switch (linkError.code) {
              case 'credential-already-in-use':
                // Account exists, sign out anonymous user and sign in with Google
                await authService.signOut();
                await authService.signInWithGoogle();
                _navigateToProfile();
                break;
              case 'account-exists-with-different-credential':
                throw FirebaseAuthException(
                    code: 'account-exists-with-different-credential',
                    message:
                        'An account already exists with this email. Please sign in with your existing account.');
              case 'provider-already-linked':
                // Show a more user-friendly error message
                throw FirebaseAuthException(
                    code: 'provider-already-linked',
                    message:
                        'Google sign-in is already linked to your account.');
              default:
                rethrow;
            }
          } else {
            String errorMessage = 'Failed to sign in with Google';
            bool isError = true;

            if (linkError.toString().contains('sign in was cancelled')) {
              errorMessage =
                  'Sign-in was cancelled. You can try again when you\'re ready.';
              isError = false;
              talker
                  .debug('Showing cancellation message for non-Firebase error');
            } else {
              errorMessage = linkError.toString();
              talker.debug('Showing non-Firebase error: $errorMessage');
            }

            _showError(errorMessage, isError: isError);
          }
        }
      } else {
        // Normal Google sign in for non-anonymous users
        talker.debug('Login page: Calling authService.signInWithGoogle()');
        await authService.signInWithGoogle();
        talker.debug('Login page: Google Sign-In successful');
        _navigateToProfile();
      }
    } catch (e) {
      String errorMessage = 'Failed to sign in with Google';
      bool isError = true;

      if (e is FirebaseAuthException) {
        final authService = ref.read(authServiceProvider);
        errorMessage = authService.getReadableAuthError(e);

        // Don't show cancellation as an error
        if (e.code == 'cancelled-by-user') {
          isError = false;
        }

        // Log the error for debugging
        talker.error('Google sign-in error: ${e.code} - ${e.message}');
      } else if (e.toString().contains('sign in was cancelled')) {
        errorMessage =
            'Sign-in was cancelled. You can try again when you\'re ready.';
        isError = false;
      } else {
        errorMessage = e.toString();
        talker.error('Non-Firebase Google sign-in error: $e');
      }

      _showError(errorMessage, isError: isError);
    } finally {
      _setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarFactory.createAppBar(context,
          ref.watch(authStateProvider).isAnonymous ? 'Account' : 'Login'),
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
                                    ? Theme.of(context).colorScheme.onSurface
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
                                    ? Theme.of(context).colorScheme.onSurface
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
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Anonymous accounts are deleted after 30 days of inactivity.',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
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
                            _showError(
                                'Google Sign-In failed: ${e.toString()}');
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
                            foregroundColor:
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
                            foregroundColor:
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
                          _showError('Google Sign-In failed: ${e.toString()}');
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
