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
// Import AuthException and AuthService
import 'package:fftcg_companion/core/services/auth_service.dart';
// Import Merge Dialog and helpers
import 'package:fftcg_companion/features/profile/presentation/widgets/merge_data_decision_dialog.dart';
import 'package:fftcg_companion/features/collection/data/repositories/collection_repository.dart';
import 'package:fftcg_companion/features/collection/data/repositories/collection_merge_helper.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:fftcg_companion/features/profile/data/repositories/settings_merge_helper.dart';
// Import SnackBarHelper (assuming it's needed, based on register_page)
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';

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
    // Use SnackBarHelper for consistency
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

      // If user is anonymous, we need to handle both linking and sign-in cases
      if (authState.isAnonymous) {
        try {
          // If the user is anonymous, we should try to link the account with email/password
          // This preserves the user's data since the user ID remains the same
          talker.debug(
              'Login page: Linking anonymous account with email/password');

          // Use the correct linking method for anonymous users
          await authService.linkEmailAndPasswordToAnonymous(email, password);

          talker.debug('Login page: Email/password linking successful');
          _navigateToProfile();
          return;
        } catch (signInError) {
          // Handle specific errors during linking
          if (signInError is FirebaseAuthException) {
            switch (signInError.code) {
              case 'email-already-in-use':
              case 'credential-already-in-use':
                // Account exists, sign out anonymous user and sign in with existing account
                talker.debug(
                    'Login page: Account exists, signing out anonymous user and signing in with existing account');
                await authService.signOut();
                await authService.signInWithEmailAndPassword(email, password);
                _navigateToProfile();
                return;
              default:
                // For other errors, rethrow
                rethrow;
            }
          } else {
            // For non-Firebase errors, rethrow
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
        // Corrected call to getReadableAuthError
        errorMessage = authService.getReadableAuthError(e.code, e.message);

        // Don't show cancellation as an error
        if (e.code == 'cancelled-by-user' || e.code == 'cancelled') {
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
    final currentContext = context; // Capture context

    try {
      talker.debug('Login page: Starting Google Sign-In');
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);

      // If user is anonymous, link the account instead of creating a new one
      if (authState.isAnonymous) {
        try {
          // Link the anonymous account with Google
          // This preserves the user's data since the user ID remains the same
          talker.debug('Login page: Linking anonymous account with Google');
          // Corrected method call - removed context argument
          await authService.linkGoogleToAnonymous();

          talker.debug('Login page: Google linking successful');
          _navigateToProfile();
        } catch (linkError) {
          // Handle specific errors during linking
          if (linkError is AuthException) {
            talker.warning(
                'Login page: Google link failed - ${linkError.code}: ${linkError.message}');

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
                _showError('An error occurred during account linking.');
                return; // Exit if details are missing
              }

              final mergeAction =
                  await showMergeDataDecisionDialog(currentContext);
              if (mergeAction != null && currentContext.mounted) {
                final collectionRepo = CollectionRepository();
                final userRepo = UserRepository();
                // Add null assertion here
                final toUserId = signedInCredential!.user!.uid;

                try {
                  _setLoading(true); // Show loading during merge
                  switch (mergeAction) {
                    case MergeAction.discard:
                      talker.debug('Discarding anonymous user data');
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
                    _navigateToProfile(); // Navigate after merge
                  }
                } catch (e) {
                  talker.error('Error during data migration: $e');
                  _showError('Error merging data. Please try again.');
                } finally {
                  _setLoading(false); // Hide loading after merge attempt
                }
              } else {
                talker.debug('Merge data dialog cancelled by user.');
                // User cancelled, they are now signed in with the Google account.
                // Navigate to profile as the state is now authenticated.
                _navigateToProfile();
              }
            } else {
              // Show specific message for other AuthExceptions
              _showError(linkError.message);
            }
          } else if (linkError is FirebaseAuthException) {
            // Fallback for direct FirebaseAuthException (less likely)
            talker.error(
                'FirebaseAuthException during Google link: ${linkError.code}');
            final readableError = authService.getReadableAuthError(
                linkError.code, linkError.message);
            _showError(readableError);
          } else {
            // Handle other errors generically
            talker.error('Unexpected error during Google link: $linkError');
            _showError('An unexpected error occurred during linking.');
          }
        }
      } else {
        // Normal Google sign in for non-anonymous users
        talker.debug('Login page: Calling authService.signInWithGoogle()');
        await authService.signInWithGoogle();
        talker.debug('Login page: Google Sign-In successful');
        // _navigateToProfile(); // Rely on router redirect via authStateProvider
      }
    } catch (e) {
      String errorMessage = 'Failed to sign in with Google';
      bool isError = true;

      if (e is FirebaseAuthException) {
        final authService = ref.read(authServiceProvider);
        // Corrected call to getReadableAuthError
        errorMessage = authService.getReadableAuthError(e.code, e.message);

        // Don't show cancellation as an error
        if (e.code == 'cancelled-by-user' || e.code == 'cancelled') {
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
                    if (ref.watch(authStateProvider).isAnonymous)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin:
                            const EdgeInsets.only(bottom: 16), // Reduced margin
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.2), // 0.2 * 255 = 51
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
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
