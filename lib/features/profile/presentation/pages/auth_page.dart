import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  // Flag to track if sign-in was initiated from this page
  bool _isSigningInWithGoogle = false;
  bool _isSigningInWithEmail = false; // Added for email flow consistency

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    ref.listenManual<AuthState>(authStateProvider, (previous, next) {
      // Ensure listener runs only when mounted
      if (!mounted) return;

      final wasUnauthenticated = previous?.isUnauthenticated ?? true;
      final wasAnonymous = previous?.isAnonymous ?? false;
      final isAuthenticated = next.isAuthenticated;

      talker.debug(
          'Auth Listener: Prev=${previous?.status}, Next=${next.status}, GoogleSignIn=$_isSigningInWithGoogle, EmailSignIn=$_isSigningInWithEmail');

      // Navigate after Google Sign-In initiated from this page
      if (_isSigningInWithGoogle &&
          (wasUnauthenticated || wasAnonymous) &&
          isAuthenticated) {
        talker.debug(
            'Auth Listener: Detected Google Sign-In completion, navigating...');
        _showSuccessAndNavigate('Successfully signed in with Google!');
        _isSigningInWithGoogle = false; // Reset flag
      }
      // Navigate after Email Sign-In initiated from this page (if needed, currently handled differently)
      // else if (_isSigningInWithEmail && (wasUnauthenticated || wasAnonymous) && isAuthenticated) {
      //   talker.debug('Auth Listener: Detected Email Sign-In completion, navigating...');
      //   _showSuccessAndNavigate('Successfully signed in!');
      //   _isSigningInWithEmail = false; // Reset flag
      // }
    });
  }

  void _showSuccessAndNavigate(String message) {
    // Use ScaffoldMessenger to show snackbar safely even if context is changing
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();
      // Use the correct SnackBarHelper method
      SnackBarHelper.showSuccessSnackBar(
        context: context,
        message: message,
      );
    }
    // Navigate after a short delay to allow snackbar to show
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.go('/profile/account');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Corrected _showError method
  void _showError(String message, {bool isError = true}) {
    if (!mounted) return;
    // Use the correct SnackBarHelper methods
    if (isError) {
      SnackBarHelper.showErrorSnackBar(
        context: context,
        message: message,
        duration:
            const Duration(seconds: 10), // Keep longer duration for errors
      );
    } else {
      SnackBarHelper.showSnackBar(
        context: context,
        message: message,
        duration: const Duration(seconds: 4), // Standard duration for info
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
    _isSigningInWithEmail = true; // Set flag
    final currentContext = context; // Capture context

    try {
      final authState = ref.read(authStateProvider);
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (authState.isAnonymous) {
        talker.debug('Auth page: Email/Pass sign-in from anonymous state.');
        ref.read(skipAutoAuthProvider.notifier).state = true;
        await authService.signOut();
        await authService.signInWithEmailAndPassword(email, password);
      } else {
        talker.debug('Auth page: Email/Pass sign-in from non-anonymous state.');
        await authService.signInWithEmailAndPassword(email, password);
      }
      talker
          .debug('Auth page: Email/Pass sign-in successful (Firebase level).');
      // Reset skip flag ONLY on success
      ref.read(skipAutoAuthProvider.notifier).state = false;

      // --- REMOVED EXPLICIT NAVIGATION ---
      // Rely on the listener _setupAuthListener to navigate
    } on AuthException catch (e) {
      _isSigningInWithEmail = false; // Reset flag on error
      ref.read(skipAutoAuthProvider.notifier).state = false; // Reset skip flag
      talker.error(
          'Caught AuthException in auth_page (Email/Password): ${e.code} - ${e.message}');
      if (!currentContext.mounted) return;
      // Handle specific errors like user-not-found dialog
      if (e.code == 'user-not-found') {
        showDialog(
          context: currentContext,
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
                    GoRouter.of(currentContext).go('/profile/register');
                  },
                  child: const Text('Create Account'),
                ),
              ],
            );
          },
        );
      } else {
        _showError(e.message, isError: true); // Use _showError for consistency
      }
    } catch (e) {
      _isSigningInWithEmail = false; // Reset flag on error
      ref.read(skipAutoAuthProvider.notifier).state = false; // Reset skip flag
      talker.error('Non-AuthException error in auth page (Email/Password): $e');
      if (!currentContext.mounted) return;
      _showError('An unexpected error occurred. Please try again.',
          isError: true);
    } finally {
      if (mounted) {
        _setLoading(false);
      }
    }
  }

  // *** FINAL Simplified Google Sign-In Logic - Relying on Listener ***
  Future<void> _signInWithGoogle() async {
    _setLoading(true);
    _isSigningInWithGoogle = true; // Set flag
    final initialContext = context;
    final authService = ref.read(authServiceProvider);
// Track if the core operation succeeded

    // Set skip flag BEFORE attempting sign-in
    ref.read(skipAutoAuthProvider.notifier).state = true;
    talker.debug(
        'Auth page: Set skipAutoAuthProvider=true before Google sign-in attempt.');

    try {
      talker.debug('Auth page: Attempting direct Google Sign-In...');
      // Check mounted before await
      if (!initialContext.mounted) {
        ref.read(skipAutoAuthProvider.notifier).state = false;
        _setLoading(false);
        _isSigningInWithGoogle = false; // Reset flag if exiting early
        return;
      }
      await authService.signInWithGoogle(); // The core operation
// Mark as successful
      talker.debug(
          'Auth page: Direct Google Sign-In successful (Firebase level). Waiting for listener...');

      // Reset skip flag immediately after successful Firebase operation
      ref.read(skipAutoAuthProvider.notifier).state = false;
      talker.debug(
          'Auth page: Reset skipAutoAuthProvider=false after successful Google sign-in attempt.');

      // Invalidate providers AFTER successful operation to trigger state change listener
      ref.invalidate(firebaseUserProvider);
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      talker
          .debug('Auth page: Invalidated auth providers after Google sign-in.');

      // --- REMOVED ---
      // - User reload (handled by listener/sync provider)
      // - Delays
      // - Force refresh trigger (invalidate does this)
      // - Final auth state check (listener does this)
      // - Success snackbar (listener does this)
      // - Explicit navigation (listener does this)
      // --- END REMOVED ---
    } on AuthException catch (e) {
      _isSigningInWithGoogle = false; // Reset flag on error
      ref.read(skipAutoAuthProvider.notifier).state = false; // Reset skip flag
      talker.error(
          'Caught AuthException during direct Google Sign-In: ${e.code} - ${e.message}');
      if (!initialContext.mounted) return; // Exit if disposed during await

      // Handle specific errors like account not found -> offer creation
      if (e.code == 'account-not-found' ||
          e.code == 'google-account-not-found' ||
          e.code == 'user-not-found') {
        talker.warning(
            'Auth page: Google account not found, showing creation dialog.');
        showDialog(
          context: initialContext,
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
                    final currentDialogContext = dialogContext;
                    Navigator.of(currentDialogContext).pop();
                    try {
                      talker.debug(
                          'Auth page: Retrying Google sign-in to create account...');
                      ref.read(skipAutoAuthProvider.notifier).state = true;
                      if (!mounted) return;
                      await authService.signInWithGoogle();
// Mark success if creation works
                      talker.debug(
                          'Auth page: Google Sign-In successful (account created). Waiting for listener...');
                      // Reset skip flag on success inside dialog too
                      ref.read(skipAutoAuthProvider.notifier).state = false;
                      // Invalidate providers to trigger listener
                      ref.invalidate(firebaseUserProvider);
                      ref.invalidate(authStateProvider);
                      ref.invalidate(currentUserProvider);
                    } catch (signInError) {
                      if (!mounted) return;
                      talker.error(
                          'Auth page: Error during Google account creation retry: $signInError');
                      _showError(
                          signInError is AuthException
                              ? signInError.message
                              : 'Failed to create account with Google',
                          isError: true);
                      // Reset skip flag on error here too
                      ref.read(skipAutoAuthProvider.notifier).state = false;
                    }
                  },
                  child: const Text('Create Account'),
                ),
              ],
            );
          },
        );
      } else {
        bool isError = e.code != 'cancelled' && e.code != 'sign-in-cancelled';
        _showError(e.message, isError: isError);
      }
    } catch (e) {
      _isSigningInWithGoogle = false; // Reset flag on error
      ref.read(skipAutoAuthProvider.notifier).state = false; // Reset skip flag
      talker.error('Non-AuthException during direct Google Sign-In: $e');
      if (initialContext.mounted) {
        _showError('An unexpected error occurred: ${e.toString()}',
            isError: true);
      }
    } finally {
      // Reset flag and loading state if still mounted
      if (mounted) {
        // Flag might have been reset already on success/error, but reset again for safety
        _isSigningInWithGoogle = false;
        _setLoading(false);
        // Ensure skip flag is false if somehow missed
        try {
          ref.read(skipAutoAuthProvider.notifier).state = false;
        } catch (_) {}
      }
      talker
          .debug('Auth page: Google sign-in function finally block executed.');
    }
  }
  // *** END FINAL Simplified Google Sign-In Logic ***

  @override
  Widget build(BuildContext context) {
    // No listener here, moved to initState
    final authState =
        ref.watch(authStateProvider); // Still watch for UI updates
    final isAnonymous = authState.isAnonymous;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBarFactory.createAppBar(context, 'Sign In'),
      // Use a conditional loading overlay instead of replacing the whole body
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  // Logo
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

                  // Anonymous user banner
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

                  // Email/Password Form
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
                            // Wrap async call in a non-async lambda
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _signInWithEmailAndPassword();
                                  },
                            text: 'Sign In with Email', // More specific
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Google Sign In Button
                  GoogleSignInButton(
                    isLoading: _isLoading, // Pass loading state
                    onPressed: _isLoading
                        ? null
                        : () async {
                            // Disable if loading
                            await _signInWithGoogle();
                          },
                    // Removed onError handler from button instance
                    text: 'Continue with Google',
                  ),

                  const SizedBox(height: 16),
                  // Other Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => context
                                .go('/profile/register'), // Disable if loading
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
                        onPressed: _isLoading
                            ? null
                            : () => context.go(
                                '/profile/reset-password'), // Disable if loading
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
          // Loading overlay
          if (_isLoading)
            const Positioned.fill(
              child: AbsorbPointer(
                // Prevent interaction with UI below
                child: Center(
                  child: LoadingIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
