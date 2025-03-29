import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';
// Import skipAutoAuthProvider and AuthException
import 'package:fftcg_companion/core/providers/auto_auth_provider.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';

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

  void _navigateToProfile() {
    if (!mounted) return;
    context.go('/profile');
  }

  void _showError(String message, {bool isError = true}) {
    if (!mounted) return;
    if (isError) {
      SnackBarHelper.showErrorSnackBar(
        context: context,
        message: message,
        duration: const Duration(seconds: 10),
      );
    } else {
      SnackBarHelper.showSnackBar(
        context: context,
        message: message,
        duration: const Duration(seconds: 3),
      );
    }
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

      // If user is anonymous, sign them out first, then sign in with credentials
      if (authState.isAnonymous) {
        talker.debug(
            'Auth page: Anonymous user signing in with Email/Password. Setting skip flag and signing out anonymous first.');
        // Set flag to prevent auto anonymous sign-in immediately after sign out
        ref.read(skipAutoAuthProvider.notifier).state = true;
        await authService.signOut(); // Sign out anonymous user

        // Now sign in with the provided credentials
        await authService.signInWithEmailAndPassword(email, password);
        talker.debug(
            'Auth page: Successfully signed in with Email/Password after anonymous sign out.');
        _navigateToProfile();
      } else {
        // Normal sign in for non-anonymous users
        talker.debug('Auth page: Non-anonymous user signing in.');
        await authService.signInWithEmailAndPassword(email, password);
        _navigateToProfile();
      }
      // Catch the custom AuthException thrown by AuthService
    } on AuthException catch (e) {
      talker.error(
          'Caught AuthException in auth_page (Email/Password): ${e.code} - ${e.message}');

      // Special dialogs for common errors based on the code from AuthException
      if (mounted) {
        if (e.code == 'user-not-found') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Account Not Found'),
                content: const Text(
                    'No account found with this email address. Would you like to create a new account?'),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Try Again'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
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
        } else if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          // Show SnackBar for incorrect credentials using the message from AuthException
          _showError(e.message, isError: true);
          // Optionally show reset password dialog
          /* ... dialog code ... */
        } else {
          // Show generic error SnackBar for other AuthExceptions
          _showError(e.message, isError: true);
        }
      }
    } catch (e) {
      // Handle other non-AuthException errors
      talker.error('Non-AuthException error in auth page (Email/Password): $e');
      if (mounted) {
        _showError('An unexpected error occurred. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    _setLoading(true);

    try {
      talker.debug('Auth page: Starting Google Sign-In');
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);

      // If user is anonymous, try to link the account first
      if (authState.isAnonymous) {
        try {
          talker.debug(
              'Auth page: Anonymous user linking with Google. Setting skip flag.');
          // Set flag to prevent auto anonymous sign-in after sign out
          ref.read(skipAutoAuthProvider.notifier).state = true;

          talker
              .debug('Auth page: Calling authService.linkGoogleToAnonymous()');
          await authService.linkGoogleToAnonymous(context);
          talker.debug('Auth page: Google linking successful');
          _navigateToProfile();
        } catch (linkError) {
          // If linking fails because user is NOT anonymous (timing issue after sign out?)
          if (linkError is AuthException && linkError.code == 'not-anonymous') {
            talker.warning(
                'Auth page: Attempted to link Google, but user was not anonymous. Falling back to standard sign-in.');
            // Fallback: Try standard sign-in instead
            await authService.signInWithGoogle();
            talker.debug(
                'Auth page: Fallback Google Sign-In successful after link failure.');
            _navigateToProfile();
          }
          // Handle other linking errors (like account already exists with different credential)
          else if (linkError is AuthException) {
            talker.warning(
                'Auth page: Google link failed - ${linkError.code}: ${linkError.message}');
            if (mounted) {
              _showError(linkError.message, isError: true);
            }
          } else if (linkError is FirebaseAuthException) {
            talker.error(
                'FirebaseAuthException during Google link: ${linkError.code}');
            if (mounted) {
              _showError(
                  authService.getReadableAuthError(
                      linkError.code, linkError.message),
                  isError: true);
            }
          } else {
            // Rethrow other unexpected errors
            rethrow;
          }
        }
      } else {
        // Normal Google sign in for non-anonymous users
        talker.debug('Auth page: Calling authService.signInWithGoogle()');
        await authService.signInWithGoogle();
        talker.debug('Auth page: Google Sign-In successful');
        _navigateToProfile(); // Navigate after successful sign-in
      }
      // Catch AuthException from sign-in attempts (including fallback)
    } on AuthException catch (e) {
      talker.error(
          'Caught AuthException in auth_page (Google): ${e.code} - ${e.message}');
      bool isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled';
      if (mounted) {
        _showError(e.message, isError: isError);
      }
    } catch (e) {
      // Catch any other unexpected errors
      String errorMessage = 'Failed to sign in with Google';
      bool isError = true;

      // Check if it's a cancellation message string (less reliable)
      if (e.toString().contains('sign in was cancelled')) {
        errorMessage =
            'Sign-in was cancelled. You can try again when you\'re ready.';
        isError = false;
      } else {
        errorMessage = e.toString();
        talker.error('Non-AuthException Google sign-in error: $e');
      }

      if (mounted) {
        _showError(errorMessage, isError: isError);
      }
    } finally {
      if (mounted) {
        _setLoading(false);
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
                    // Logo with rounded rectangle container using primary color
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo_transparent.png',
                          height: 200,
                          width: 200,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
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
                              text: isAnonymous
                                  ? 'Sign In'
                                  : 'Sign In', // Keep label simple
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

                        // Show a user-friendly error message
                        String errorMessage = 'Failed to sign in with Google';
                        bool isError = true;

                        // Catch AuthException first
                        if (e is AuthException) {
                          errorMessage = e.message;
                          isError = e.code != 'cancelled' &&
                              e.code != 'sign-in-cancelled';
                        }
                        // Fallback for other types or string messages
                        else if (e
                            .toString()
                            .contains('sign in was cancelled')) {
                          errorMessage = 'Google sign-in was cancelled';
                          isError = false;
                        } else {
                          errorMessage = e.toString();
                        }

                        if (mounted) {
                          _showError(errorMessage, isError: isError);
                        }
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
