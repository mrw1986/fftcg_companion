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

  // Note: This function implicitly uses context. Ensure it's called only when mounted.
  void _navigateToProfile() {
    if (!mounted) return;
    // Use goNamed for potentially better stack management if needed
    context.goNamed('profile');
  }

  // Note: This function uses context. Ensure it's called only when mounted.
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
    // Capture context before async gap
    final currentContext = context;

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
        // Check mounted after await before navigation
        if (!mounted) return;
        _navigateToProfile();
        // Reset skip flag after successful sign-in
        ref.read(skipAutoAuthProvider.notifier).state = false;
      } else {
        // Normal sign in for non-anonymous users
        talker.debug('Auth page: Non-anonymous user signing in.');
        await authService.signInWithEmailAndPassword(email, password);
        // Check mounted after await before navigation
        if (!mounted) return;
        _navigateToProfile();
        // Reset skip flag after successful sign-in
        ref.read(skipAutoAuthProvider.notifier).state = false;
      }
      // Catch the custom AuthException thrown by AuthService
    } on AuthException catch (e) {
      talker.error(
          'Caught AuthException in auth_page (Email/Password): ${e.code} - ${e.message}');

      // Use captured context after async gap, checking mounted status
      if (!currentContext.mounted) return;
      if (e.code == 'user-not-found') {
        showDialog(
          context: currentContext, // Use captured context
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Account Not Found'),
              content: const Text(
                  'No account found with this email address. Would you like to create a new account?'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(currentContext).colorScheme.primary,
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Try Again'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(currentContext).colorScheme.primary,
                  ),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Use captured context for navigation
                    GoRouter.of(currentContext).go('/profile/register');
                  },
                  child: const Text('Create Account'),
                ),
              ],
            );
          },
        );
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // Show SnackBar for incorrect credentials using the message from AuthException
        // Use captured context for SnackBar
        SnackBarHelper.showErrorSnackBar(
            context: currentContext, message: e.message);
        // Optionally show reset password dialog
        /* ... dialog code ... */
      } else {
        // Show generic error SnackBar for other AuthExceptions
        // Use captured context for SnackBar
        SnackBarHelper.showErrorSnackBar(
            context: currentContext, message: e.message);
      }
    } catch (e) {
      // Handle other non-AuthException errors
      talker.error('Non-AuthException error in auth page (Email/Password): $e');
      // Use captured context after async gap, checking mounted status
      if (!currentContext.mounted) return;
      SnackBarHelper.showErrorSnackBar(
          context: currentContext,
          message: 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  // *** REVISED Google Sign-In Logic ***
  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    // Capture context before any async gaps
    final initialContext = context;
    final authService = ref.read(authServiceProvider);

    // Set skip flag BEFORE attempting sign-in to prevent auto-anonymous
    // if this flow is cancelled or fails early.
    ref.read(skipAutoAuthProvider.notifier).state = true;
    talker.debug(
        'Auth page: Set skipAutoAuthProvider=true before Google sign-in attempt.');

    try {
      talker.debug('Auth page: Attempting direct Google Sign-In...');
      // Check mounted before await
      if (!initialContext.mounted) return;
      await authService.signInWithGoogle();
      talker.debug('Auth page: Direct Google Sign-In successful');

      // Force refresh the auth state to ensure it's up to date
      ref.read(forceRefreshAuthProvider.notifier).state = true;
      talker.debug('Auth page: Forced auth state refresh after Google sign-in');

      // Add a delay to allow auth state to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Reload current user to ensure auth state is fresh
      await FirebaseAuth.instance.currentUser?.reload();
      talker.debug('Auth page: Reloaded Firebase user after Google sign-in');

      // Check mounted after await before navigation
      if (!initialContext.mounted) return;

      // Get current auth state to add diagnostic info
      final updatedAuthState = ref.read(authStateProvider);
      talker.debug(
          'Auth page: Current auth state before navigation: ${updatedAuthState.status}');

      // Show success feedback
      if (initialContext.mounted) {
        SnackBarHelper.showSuccessSnackBar(
          context: initialContext,
          message: 'Successfully signed in with Google!',
        );
      }

      // Navigate to profile
      _navigateToProfile();

      // Reset skip flag ONLY after successful sign-in
      ref.read(skipAutoAuthProvider.notifier).state = false;
      talker.debug(
          'Auth page: Reset skipAutoAuthProvider=false after successful Google sign-in.');
    } on AuthException catch (e) {
      talker.error(
          'Caught AuthException during direct Google Sign-In: ${e.code} - ${e.message}');

      // Check mounted after await before showing dialog/snackbar
      if (!initialContext.mounted) return;

      // Handle specific errors like account not found -> offer creation
      if (e.code == 'account-not-found' || // Firebase might throw this
          e.code == 'google-account-not-found' || // Custom code might be used
          e.code == 'user-not-found') {
        talker.warning(
            'Auth page: Google account not found, showing creation dialog.');
        showDialog(
          context: initialContext, // Use captured context
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Create New Account?'),
              content: const Text(
                  'No account found with this Google profile. Would you like to create a new account?'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(initialContext)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.8),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        Theme.of(initialContext).colorScheme.primary,
                    foregroundColor:
                        Theme.of(initialContext).colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    // Capture dialog context before async gap
                    final currentDialogContext = dialogContext;
                    Navigator.of(currentDialogContext).pop();
                    // Try standard Google sign-in again, which should now create the account
                    // (Firebase handles this implicitly if the user doesn't exist)
                    try {
                      talker.debug(
                          'Auth page: Retrying Google sign-in to create account...');
                      // Ensure skip flag is still true before this attempt
                      ref.read(skipAutoAuthProvider.notifier).state = true;
                      // Check mounted before await
                      if (!mounted) return;
                      await authService.signInWithGoogle();
                      talker.debug(
                          'Auth page: Google Sign-In successful (account created).');

                      // Force refresh, delay, reload
                      ref.read(forceRefreshAuthProvider.notifier).state = true;
                      await Future.delayed(const Duration(milliseconds: 500));
                      await FirebaseAuth.instance.currentUser?.reload();

                      // Check mounted after await before navigation
                      if (!mounted) return;
                      _navigateToProfile(); // Uses state's context, safe here
                      // Reset skip flag after successful creation/sign-in
                      ref.read(skipAutoAuthProvider.notifier).state = false;
                    } catch (signInError) {
                      // Check mounted after await before showing error
                      if (!mounted) return;
                      talker.error(
                          'Auth page: Error during Google account creation retry: $signInError');
                      _showError(
                          signInError is AuthException
                              ? signInError.message
                              : 'Failed to create account with Google',
                          isError: true);
                    }
                  },
                  child: const Text('Create Account'),
                ),
              ],
            );
          },
        );
      } else {
        // Handle other AuthExceptions (e.g., cancelled, network error)
        bool isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled';
        _showError(e.message, isError: isError);
      }
    } catch (e) {
      // Catch any other unexpected errors
      talker.error('Non-AuthException during direct Google Sign-In: $e');
      if (initialContext.mounted) {
        _showError('An unexpected error occurred: ${e.toString()}',
            isError: true);
      }
    } finally {
      // Ensure loading indicator is turned off if mounted
      if (mounted) {
        _setLoading(false);
      }
      // DO NOT reset skip flag here, only on success.
    }
  }
  // *** END REVISED Google Sign-In Logic ***

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
                              'You are currently signed in as a guest.', // Simplified message
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in with Email/Password or Google to save your data permanently.', // Clearer call to action
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Note: Guest data is temporary and may be lost.', // Simplified warning
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
                              text: 'Sign In with Email', // More specific
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
                        talker.error('Google Sign-In button onError: $e');
                        // This onError is primarily for the button's internal state,
                        // main error handling is in _signInWithGoogle now.
                        // We can still show a generic message here if needed.
                        if (mounted) {
                          _showError('An error occurred during Google Sign-In.',
                              isError: true);
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
