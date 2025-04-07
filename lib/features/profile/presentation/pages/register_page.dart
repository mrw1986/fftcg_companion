import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
// Import LinkAccountsDialog to use it directly
import 'package:fftcg_companion/features/profile/presentation/widgets/link_accounts_dialog.dart';
// Import MergeDataDecisionDialog
import 'package:fftcg_companion/features/profile/presentation/widgets/merge_data_decision_dialog.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';
// Import AuthException and skipAutoAuthProvider
import 'package:fftcg_companion/core/services/auth_service.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart'; // Import SnackBarHelper
// Import repositories and merge helpers for data migration
import 'package:fftcg_companion/features/collection/data/repositories/collection_repository.dart';
import 'package:fftcg_companion/features/collection/data/repositories/collection_merge_helper.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:fftcg_companion/features/profile/data/repositories/settings_merge_helper.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

// Removed duplicate showThemedSnackBar, using SnackBarHelper now

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  // bool _showPasswordRequirements = false; // Replaced by FocusNode listener
  bool _showPassword = false;
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
    if (!mounted) return; // Check mounted before setState
    setState(() {
      _isPasswordFocused = _passwordFocusNode.hasFocus;
    });
  }

  // Renamed from _registerWithEmailAndPassword to handle both linking and registration
  Future<void> _submitEmailPasswordForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final currentContext = context; // Capture context before async gap
    bool registrationSuccess = false; // Flag to track success

    try {
      final authService = ref.read(authServiceProvider);
      final authState = ref.read(authStateProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      bool isLinking = authState.isAnonymous; // Check if linking or registering

      if (isLinking) {
        talker.debug(
            'Register page: Linking anonymous account with email/password');
        await authService.linkEmailAndPasswordToAnonymous(email, password);
        talker.debug('Register page: Email/password linking successful');
      } else {
        talker.debug('Register page: Creating new account with email/password');
        await authService.createUserWithEmailAndPassword(email, password);
        talker.debug('Register page: Email/password registration successful');
      }

      registrationSuccess = true; // Mark as successful

      if (!mounted) return;

      // Invalidate providers to ensure state is refreshed
      // The router redirect logic might still handle navigation in some cases,
      // but we'll add explicit navigation after the dialog for reliability.
      ref.invalidate(firebaseUserProvider);
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);

      // Show verification email sent dialog
      // Use currentContext captured before await
      if (!currentContext.mounted) return; // Add mounted check
      await showDialog<void>(
        context: currentContext,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final colorScheme = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.mark_email_read_outlined,
                    color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Verification Email Sent'),
              ],
            ),
            content: Text(
              'A verification email has been sent to $email. Please check your inbox and click the verification link. Until verified, your account has the same limitations as a guest account (e.g., 50 unique card collection limit).',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            actions: <Widget>[
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('OK'),
              ),
            ],
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        },
      );

      // Explicit navigation AFTER dialog is dismissed and IF registration was successful
      if (registrationSuccess && mounted) {
        talker.debug(
            'Register page: Navigating to /profile/account after dialog dismissal.');
        // Use GoRouter.of(context) for navigation if context is still valid
        if (!currentContext.mounted) return; // Add mounted check
        GoRouter.of(currentContext).go('/profile/account');
      }
    } catch (e) {
      registrationSuccess = false; // Mark as failed on error
      if (!mounted) return;

      // Show user-friendly error message as SnackBar
      String errorMessage = 'Failed to complete action'; // Default message
      bool showErrorSnackbar =
          true; // Flag to control showing the final snackbar

      if (e is AuthException) {
        // Catch custom AuthException first
        errorMessage = e.message; // Use the message from AuthException
        talker
            .error('Error during email/pass submit: ${e.code} - ${e.message}');

        // Special handling for email-already-in-use error
        if (e.code == 'email-already-in-use') {
          // Show a dialog with options
          // Use currentContext captured before await
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!currentContext.mounted) return;
            showDialog(
              context: currentContext,
              barrierDismissible: false, // Make this non-dismissible
              builder: (BuildContext dialogContext) {
                final theme = Theme.of(dialogContext);
                final colorScheme = theme.colorScheme;

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    // Added shape
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    // Changed title
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error),
                      const SizedBox(width: 12),
                      const Text('Account Already Exists'),
                    ],
                  ),
                  content: const SingleChildScrollView(
                    // Wrapped content
                    child: Text(
                        'An account with this email address already exists. Would you like to sign in instead?'),
                  ),
                  actions: [
                    TextButton(
                      // Styled Cancel/Try Again
                      style: TextButton.styleFrom(
                        foregroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Try Again'),
                    ),
                    FilledButton(
                      // Changed to FilledButton
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Use currentContext for navigation
                        if (currentContext.mounted) {
                          // Navigate to the top-level /auth route
                          GoRouter.of(currentContext).go('/auth');
                        }
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                  actionsPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12), // Added padding
                );
              },
            );
          });

          showErrorSnackbar =
              false; // Don't show the final snackbar for this case
        }
      } else {
        // Handle non-AuthException errors
        talker.error('Error during email/pass submit: $e');
        errorMessage = 'An unexpected error occurred. Please try again.';
      }

      // Show snackbar only if it wasn't handled by the special 'email-already-in-use' case
      if (showErrorSnackbar && mounted) {
        // Use currentContext for SnackBarHelper
        if (!currentContext.mounted) return; // Add mounted check
        SnackBarHelper.showErrorSnackBar(
          context: currentContext,
          message: errorMessage,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    final currentContext = context; // Capture context

    try {
      talker.debug('Register page: Starting Google Sign-In');
      final authService = ref.read(authServiceProvider);
      final authState = ref.read(authStateProvider);

      // If user is anonymous, link the account
      if (authState.isAnonymous) {
        talker.debug('Register page: Linking anonymous account with Google');
        try {
          // Corrected method call - removed context argument
          await authService.linkGoogleToAnonymous();
          talker.debug('Register page: Google linking successful');

          // Navigate to profile page after successful linking
          if (!mounted) return;

          // Invalidate providers and let router handle navigation
          ref.invalidate(firebaseUserProvider);
          ref.invalidate(authStateProvider);
          ref.invalidate(currentUserProvider);
          // Explicit navigation might be needed here too if router redirect is unreliable
          if (mounted) {
            talker.debug(
                'Register page: Navigating to /profile/account after Google link.');
            if (!currentContext.mounted) return; // Add mounted check
            GoRouter.of(currentContext).go('/profile/account');
          }
        } catch (linkError) {
          if (!mounted) return;

          // Catch AuthException specifically for linking errors handled by AuthService
          if (linkError is AuthException) {
            talker.warning(
                'Register page: Google link failed - ${linkError.code}: ${linkError.message}');

            // Handle the specific 'merge-required' case
            if (linkError.code == 'merge-required') {
              if (!currentContext.mounted) {
                return; // Check context before dialog
              }

              final anonymousUserId =
                  linkError.details?['anonymousUserId'] as String?;
              final signedInCredential =
                  linkError.details?['signedInCredential'] as UserCredential?;

              if (anonymousUserId == null || signedInCredential?.user == null) {
                talker.error(
                    'Merge required error details missing anonymousUserId or signedInCredential.');
                SnackBarHelper.showErrorSnackBar(
                  context: currentContext,
                  message: 'An error occurred during account linking.',
                  duration: const Duration(seconds: 8),
                );
                return; // Exit if details are missing
              }

              final mergeAction =
                  await showMergeDataDecisionDialog(currentContext);
              if (mergeAction != null && currentContext.mounted) {
                final collectionRepo = CollectionRepository();
                final userRepo = UserRepository();
                final toUserId = signedInCredential!.user!
                    .uid; // Add null check for credential as well for safety, then user

                try {
                  setState(
                      () => _isLoading = true); // Show loading during merge
                  switch (mergeAction) {
                    case MergeAction.discard:
                      talker.debug('Discarding anonymous user data');
                      // No data migration needed
                      break;
                    case MergeAction.merge:
                      talker.debug('Merging anonymous user data');
                      await migrateCollectionData(
                        collectionRepository: collectionRepo,
                        fromUserId: anonymousUserId,
                        toUserId: toUserId,
                      );
                      await migrateUserSettings(
                        userRepository: userRepo,
                        fromUserId: anonymousUserId,
                        toUserId: toUserId,
                        overwrite: false,
                      );
                      break;
                    case MergeAction.overwrite:
                      talker.debug('Overwriting with anonymous user data');
                      await migrateCollectionData(
                        collectionRepository: collectionRepo,
                        fromUserId: anonymousUserId,
                        toUserId: toUserId,
                      );
                      await migrateUserSettings(
                        userRepository: userRepo,
                        fromUserId: anonymousUserId,
                        toUserId: toUserId,
                        overwrite: true,
                      );
                      break;
                  }
                  talker.debug('Data migration/handling complete.');

                  // Invalidate and navigate after successful merge/discard
                  if (mounted) {
                    ref.invalidate(firebaseUserProvider);
                    ref.invalidate(authStateProvider);
                    ref.invalidate(currentUserProvider);
                    if (currentContext.mounted) {
                      GoRouter.of(currentContext).go('/profile/account');
                    }
                  }
                } catch (e) {
                  talker.error('Error during data migration: $e');
                  if (mounted) {
                    // Add mounted check for context before showing snackbar
                    if (!currentContext.mounted) return;
                    SnackBarHelper.showErrorSnackBar(
                      context: currentContext,
                      message: 'Error merging data. Please try again.',
                      duration: const Duration(seconds: 8),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              } else {
                // User cancelled the dialog, potentially sign them out or leave as is?
                // For now, just log it. The user is signed in with the Google account.
                talker.debug('Merge data dialog cancelled by user.');
              }
            } else {
              // Show specific message for other AuthExceptions
              if (!currentContext.mounted) return; // Add mounted check
              SnackBarHelper.showErrorSnackBar(
                context: currentContext,
                message: linkError.message,
                duration: const Duration(seconds: 8),
              );
            }
          }
          // Catch potential FirebaseAuthException if not handled by AuthService (less likely now)
          else if (linkError is FirebaseAuthException) {
            talker.error(
                'FirebaseAuthException during Google link: ${linkError.code}');
            final authService = ref.read(authServiceProvider);
            if (!currentContext.mounted) return; // Add mounted check
            SnackBarHelper.showErrorSnackBar(
              context: currentContext,
              message: authService.getReadableAuthError(
                  linkError.code, linkError.message),
              duration: const Duration(seconds: 8),
            );
          } else {
            // Rethrow other non-FirebaseAuthException errors
            talker.error('Unexpected error during Google link: $linkError');
            if (!currentContext.mounted) return; // Add mounted check
            SnackBarHelper.showErrorSnackBar(
              context: currentContext,
              message: 'An unexpected error occurred during linking.',
              duration: const Duration(seconds: 8),
            );
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

          if (!mounted) return;

          // Get the user ID after sign-in
          final afterUserId = FirebaseAuth.instance.currentUser?.uid;

          // If the user ID changed and the user wasn't authenticated before,
          // this is likely a new account creation rather than signing in to an existing account
          final isNewAccount = !wasAuthenticated && beforeUserId != afterUserId;

          // Invalidate providers and let router handle navigation
          ref.invalidate(firebaseUserProvider);
          ref.invalidate(authStateProvider);
          ref.invalidate(currentUserProvider);

          // Explicit navigation for reliability
          if (mounted) {
            talker.debug(
                'Register page: Navigating to /profile/account after Google sign-in/registration.');
            if (!currentContext.mounted) return; // Add mounted check
            GoRouter.of(currentContext).go('/profile/account');
          }

          // Only show success message if this appears to be a new account
          if (isNewAccount && mounted) {
            if (!currentContext.mounted) return; // Add mounted check
            SnackBarHelper.showSuccessSnackBar(
              context: currentContext,
              message: 'Account created successfully with Google',
              duration: const Duration(seconds: 5),
            );
          }
        } catch (signInError) {
          if (!mounted) return;

          // Handle conflict where Google email belongs to existing Email/Password account
          if (signInError is AuthException && // Catch AuthException
              (signInError.code == 'account-exists-with-different-credential' ||
                  signInError.code == 'email-already-in-use')) {
            talker.debug(
                'Register page: Google Sign-In failed - Email already exists with Email/Password.');

            // Show the LinkAccountsDialog
            final emailForDialog =
                _emailController.text.trim(); // Get email from controller
            if (!currentContext.mounted) return; // Add mounted check
            showDialog(
              context: currentContext, // Use captured context
              barrierDismissible: false, // Make non-dismissible
              builder: (BuildContext dialogContext) {
                return LinkAccountsDialog(
                  email: emailForDialog, // Pass the email
                  onComplete: (success) {
                    if (success) {
                      // Invalidate providers and let router handle navigation
                      ref.invalidate(firebaseUserProvider);
                      ref.invalidate(authStateProvider);
                      ref.invalidate(currentUserProvider);
                      // Explicit navigation after successful link
                      if (mounted) {
                        talker.debug(
                            'Register page: Navigating to /profile/account after LinkAccountsDialog success.');
                        GoRouter.of(currentContext).go('/profile/account');
                      }
                    } else {
                      // Handle cancellation or failure if needed
                      talker.debug('LinkAccountsDialog cancelled or failed.');
                    }
                  },
                );
              },
            );
          } else {
            // Rethrow other errors to be caught by the outer catch block
            rethrow;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;

      // Show user-friendly error message as SnackBar
      String errorMessage = 'Failed to sign in with Google';
      // bool isError = true; // Unused variable removed

      if (e is AuthException) {
        // Catch AuthException first
        errorMessage = e.message;
        // isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled'; // Assignment removed
      } else if (e is FirebaseAuthException) {
        // Fallback for direct FirebaseAuthException
        final authService = ref.read(authServiceProvider);
        errorMessage = authService.getReadableAuthError(e.code, e.message);
        // isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled'; // Assignment removed
      } else if (e.toString().contains('sign in was cancelled')) {
        errorMessage = 'Google sign-in was cancelled';
        // isError = false; // Assignment removed
      } else {
        talker.error('Unexpected error during Google Sign-In: $e');
        errorMessage =
            'An unexpected error occurred.'; // Fallback for other errors
      }

      if (!currentContext.mounted) return; // Add mounted check
      SnackBarHelper.showErrorSnackBar(
        // Use Error variant for clarity
        context: currentContext,
        message: errorMessage,
        duration: const Duration(seconds: 10),
      );
    } finally {
      // Ensure loading state is reset even if navigation happens
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                        margin:
                            const EdgeInsets.only(bottom: 16), // Reduced margin
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
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
                            focusNode: _passwordFocusNode, // Assign FocusNode
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
                                color: Theme.of(context).colorScheme.surface,
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
                              onPressed: _isLoading
                                  ? null
                                  : _submitEmailPasswordForm, // Updated onPressed
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
                      isLoading: _isLoading, // Pass loading state
                      onPressed: _isLoading
                          ? null
                          : () async {
                              await _signInWithGoogle();
                            },
                      // onError removed, handled within _signInWithGoogle
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
                            onPressed: _isLoading
                                ? null
                                : () => context
                                    .go('/auth'), // Navigate to top-level /auth
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              foregroundColor:
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
