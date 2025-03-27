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
  bool _registrationComplete = false;
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
        talker.debug(
            'Register page: Linking anonymous account with email/password');
        await authService.linkWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        talker.debug('Register page: Email/password linking successful');
      } else {
        // Otherwise create a new account
        talker.debug('Register page: Creating new account with email/password');
        await authService.createUserWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
        talker.debug('Register page: Email/password registration successful');
      }

      if (mounted) {
        // Set registration complete flag to show verification message
        setState(() {
          _isLoading = false;
          _registrationComplete = true;
        });

        // User will stay on this page with verification instructions
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show user-friendly error message as SnackBar
      if (mounted) {
        String errorMessage = 'Failed to create account';

        if (e is FirebaseAuthException) {
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e);

          talker.error('Error creating account: ${e.code} - ${e.message}');

          // Special handling for email-already-in-use error
          if (e.code == 'email-already-in-use') {
            // Set a more specific error message
            errorMessage =
                'An account with this email address already exists. Please sign in instead.';

            // Show the snackbar first
            showThemedSnackBar(
              context: context,
              message: errorMessage,
              isError: true,
              duration: const Duration(seconds: 5),
            );

            // Then show a dialog with options
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;

                    return AlertDialog(
                      title: Text(
                        'Account Already Exists',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                          'An account with this email address already exists. Would you like to sign in instead?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Try Again'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/profile/auth');
                          },
                          child: const Text('Sign In'),
                        ),
                      ],
                    );
                  },
                );
              }
            });

            // Return early to avoid showing the snackbar twice
            return;
          }
        } else {
          talker.error('Error creating account: $e');
        }

        showThemedSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
          duration: const Duration(seconds: 5),
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
        try {
          await authService.linkWithGoogle();
          talker.debug('Register page: Google linking successful');

          // Navigate to profile page after successful linking
          if (mounted) {
            context.go('/profile');
          }
        } catch (linkError) {
          // If the credential is already linked to another account, sign out and sign in with Google
          if (linkError is FirebaseAuthException &&
              (linkError.code == 'credential-already-in-use' ||
                  linkError.code == 'provider-already-linked')) {
            talker.debug(
                'Register page: Google account exists, signing out anonymous user and signing in with existing Google account');
            await authService.signOut();
            await authService.signInWithGoogle();

            // Navigate to profile page after successful sign-in
            if (mounted) {
              context.go('/profile');
            }
          } else {
            // Rethrow other errors
            rethrow;
          }
        }
      } else {
        // Otherwise sign in with Google
        talker.debug(
            'Register page: Checking if user already exists before Google Sign-In');
        final wasAuthenticated = authState.isAuthenticated;

        await authService.signInWithGoogle();
        talker.debug('Register page: Google Sign-In successful');

        // Navigate to profile page after successful sign-in
        if (mounted) {
          context.go('/profile');
        }

        // Show success message only if the user was not previously authenticated
        if (mounted && !wasAuthenticated) {
          showThemedSnackBar(
            context: context,
            message: 'Account created successfully with Google',
            isError: false,
            duration: const Duration(seconds: 5),
          );
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
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e);
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
      appBar: AppBarFactory.createAppBar(
          context, isAnonymous ? 'Complete Registration' : 'Register'),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _registrationComplete
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        const ThemedLogo(height: 120),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.mark_email_read, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Verification Email Sent',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'We\'ve sent a verification email to ${_emailController.text}. Please check your inbox and click the verification link before signing in.\n\nYou will be signed out until you verify your email address.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        StyledButton(
                          onPressed: () {
                            // Force a complete refresh of the auth state
                            // First invalidate the currentUserProvider which authStateProvider depends on
                            ref.invalidate(currentUserProvider);

                            // Then refresh the authStateProvider itself
                            ref.invalidate(authStateProvider);

                            context.go('/profile');
                          },
                          text: 'Return to Profile',
                        ),
                      ],
                    ),
                  ),
                )
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
                            margin: const EdgeInsets.only(
                                bottom: 16), // Reduced margin
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'You\'re currently using the app without an account. Complete your registration to save your collection, decks, and settings.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
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
                                  if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withAlpha(128), // 0.5 * 255 = 128
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Password Requirements:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('• At least 8 characters long'),
                                      Text(
                                          '• At least one uppercase letter (A-Z)'),
                                      Text(
                                          '• At least one lowercase letter (a-z)'),
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
                                      color:
                                          Theme.of(context).colorScheme.primary,
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
                            talker.error(
                                'Google Sign-In error in register page: $e');
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
                                onPressed: () => context.go('/profile/auth'),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  foregroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                child: const Text(
                                    'Already have an account? Login'),
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
