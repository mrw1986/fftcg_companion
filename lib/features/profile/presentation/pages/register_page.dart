import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
// Removed unused import: import 'package:fftcg_companion/features/profile/presentation/widgets/link_accounts_dialog.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';
// Import AuthException and skipAutoAuthProvider
import 'package:fftcg_companion/core/services/auth_service.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

/// Shows a snackbar with a message
void showThemedSnackBar({
  required BuildContext context,
  required String message,
  required bool isError,
  Duration duration = const Duration(seconds: 4),
}) {
  // Ensure context is still valid before showing snackbar
  if (!context.mounted) return;

  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor:
          isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: isError
            ? colorScheme.onErrorContainer
            : colorScheme.onPrimaryContainer,
        onPressed: () {
          // Ensure context is still valid before hiding snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        },
      ),
    ),
  );
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  // bool _showPasswordRequirements = false; // Replaced by FocusNode listener
  bool _showPassword = false;
  bool _registrationComplete = false;
  bool _showConfirmPassword = false;
  final FocusNode _passwordFocusNode = FocusNode(); // Add FocusNode
  bool _isPasswordFocused = false; // State to track focus

  @override
  void initState() {
    super.initState();
    // Add listener to FocusNode
    _passwordFocusNode.addListener(_onPasswordFocusChange);
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
        // Corrected method call
        await authService.linkEmailAndPasswordToAnonymous(
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
        String errorMessage = 'Failed to create account'; // Default message
        bool showErrorSnackbar =
            true; // Flag to control showing the final snackbar

        if (e is AuthException) {
          // Catch custom AuthException first
          errorMessage = e.message; // Use the message from AuthException
          talker.error('Error creating account: ${e.code} - ${e.message}');

          // Special handling for email-already-in-use error
          if (e.code == 'email-already-in-use') {
            // Overwrite message for this specific case (though not strictly needed as dialog shows info)
            // errorMessage =
            //     'An account with this email address already exists. Please sign in instead.';

            // Don't show the snackbar, just show the dialog
            // showThemedSnackBar(
            //   context: context,
            //   message: errorMessage,
            //   isError: true,
            //   duration: const Duration(seconds: 5),
            // );

            // Show a dialog with options
            Future.delayed(const Duration(milliseconds: 100), () {
              // Reduced delay slightly
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

            showErrorSnackbar =
                false; // Don't show the final snackbar for this case
          }
        } else {
          // Handle non-AuthException errors
          talker.error('Error creating account: $e');
          errorMessage = 'An unexpected error occurred. Please try again.';
        }

        // Show snackbar only if it wasn't handled by the special 'email-already-in-use' case
        if (showErrorSnackbar) {
          showThemedSnackBar(
            context: context,
            message: errorMessage,
            isError: true,
            duration: const Duration(seconds: 5),
          );
        }
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
          // Corrected method call
          await authService.linkGoogleToAnonymous(context);
          talker.debug('Register page: Google linking successful');

          // Navigate to profile page after successful linking
          if (mounted) {
            context.go('/profile'); // Navigate after successful link
          }
        } catch (linkError) {
          // Catch AuthException specifically for linking errors handled by AuthService
          if (linkError is AuthException) {
            talker.warning(
                'Register page: Google link failed - ${linkError.code}: ${linkError.message}');
            if (mounted) {
              // Show specific message from AuthException
              showThemedSnackBar(
                context: context,
                message: linkError.message,
                isError: true,
                duration: const Duration(seconds: 8),
              );
              setState(() {
                _isLoading = false;
              });
              return; // Stop further processing
            }
          }
          // Catch potential FirebaseAuthException if not handled by AuthService (less likely now)
          else if (linkError is FirebaseAuthException) {
            talker.error(
                'FirebaseAuthException during Google link: ${linkError.code}');
            if (mounted) {
              final authService = ref.read(authServiceProvider);
              showThemedSnackBar(
                context: context,
                message: authService.getReadableAuthError(
                    linkError.code, linkError.message),
                isError: true,
                duration: const Duration(seconds: 8),
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
          } else {
            // Rethrow other non-FirebaseAuthException errors
            rethrow;
          }
        }
      } else {
        // Otherwise (not anonymous), sign in/register with Google
        talker.debug(
            'Register page: Checking if user already exists before Google Sign-In');
        final wasAuthenticated = authState.isAuthenticated;

        try {
          // Get the current user ID before sign-in to check if this is a new account
          final beforeUserId = FirebaseAuth.instance.currentUser?.uid;

          await authService.signInWithGoogle();
          talker.debug('Register page: Google Sign-In successful');

          // Get the user ID after sign-in
          final afterUserId = FirebaseAuth.instance.currentUser?.uid;

          // If the user ID changed and the user wasn't authenticated before,
          // this is likely a new account creation rather than signing in to an existing account
          final isNewAccount = !wasAuthenticated && beforeUserId != afterUserId;

          // Navigate to profile page after successful sign-in
          if (mounted) {
            context.go(
                '/profile'); // Navigate after successful sign-in/registration

            // Only show success message if this appears to be a new account
            if (isNewAccount) {
              showThemedSnackBar(
                context: context,
                message: 'Account created successfully with Google',
                isError: false,
                duration: const Duration(seconds: 5),
              );
            }
          }
        } catch (signInError) {
          // Handle conflict where Google email belongs to existing Email/Password account
          if (signInError is AuthException && // Catch AuthException
              (signInError.code == 'account-exists-with-different-credential' ||
                  signInError.code == 'email-already-in-use')) {
            talker.debug(
                'Register page: Google Sign-In failed - Email already exists with Email/Password.');

            if (mounted) {
              // Show a dialog explaining the situation and guiding user to sign in
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
                    // Use the specific message from the exception
                    content: Text(signInError.message),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.go('/profile/auth'); // Go to Sign In page
                        },
                        child: const Text('Sign In'),
                      ),
                    ],
                  );
                },
              );
              // Stop loading
              setState(() {
                _isLoading = false;
              });
              return; // Stop further processing
            }
          } else {
            // Rethrow other errors to be caught by the outer catch block
            rethrow;
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show user-friendly error message as SnackBar
      if (mounted) {
        String errorMessage = 'Failed to sign in with Google';
        bool isError = true; // Default to error

        if (e is AuthException) {
          // Catch AuthException first
          errorMessage = e.message;
          isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled';
        } else if (e is FirebaseAuthException) {
          // Fallback for direct FirebaseAuthException
          final authService = ref.read(authServiceProvider);
          errorMessage = authService.getReadableAuthError(e.code, e.message);
          isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled';
        } else if (e.toString().contains('sign in was cancelled')) {
          errorMessage = 'Google sign-in was cancelled';
          isError = false; // Not an error
        } else {
          errorMessage = e.toString(); // Fallback for other errors
        }

        showThemedSnackBar(
          context: context,
          message: errorMessage,
          isError: isError, // Use the flag determined above
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
                                focusNode:
                                    _passwordFocusNode, // Assign FocusNode
                                // onTap removed, focus handled by FocusNode listener
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
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(
                                              alpha: 0.5), // 0.5 * 255 = 128
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

                            // Show a user-friendly error message
                            String errorMessage =
                                'Failed to sign in with Google';
                            bool isError = true; // Default to error

                            if (e is AuthException) {
                              // Catch AuthException first
                              errorMessage = e.message;
                              isError = e.code != 'cancelled' &&
                                  e.code != 'sign-in-cancelled';
                            } else if (e is FirebaseAuthException) {
                              // Fallback for direct FirebaseAuthException
                              final authService = ref.read(authServiceProvider);
                              errorMessage = authService.getReadableAuthError(
                                  e.code, e.message);
                              isError = e.code != 'cancelled' &&
                                  e.code != 'sign-in-cancelled';
                            } else if (e
                                .toString()
                                .contains('sign in was cancelled')) {
                              errorMessage = 'Google sign-in was cancelled';
                              isError = false; // Not an error
                            } else {
                              errorMessage =
                                  e.toString(); // Fallback for other errors
                            }

                            showThemedSnackBar(
                              context: context,
                              message: errorMessage,
                              isError: isError, // Use the flag determined above
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
