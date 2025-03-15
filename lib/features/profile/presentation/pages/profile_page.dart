import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_account_actions.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_display_name.dart'
    as display_name;
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_reauth_dialog.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_settings.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/splash_screen_provider.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showChangeEmail = false;
  bool _showReauthDialog = false;
  bool _isAccountDeletion = false;
  final _reauthEmailController = TextEditingController();
  bool _showReauthPassword = false;
  final _reauthPasswordController = TextEditingController();
  bool _showLinkedProviders = false;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final user = ref.read(authStateProvider).user;
    if (user != null) {
      if (user.displayName != null) {
        _displayNameController.text = user.displayName!;
      }
      if (user.email != null) {
        _emailController.text = user.email!;
        _reauthEmailController.text =
            user.email!; // Pre-fill for re-authentication
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _reauthEmailController.dispose();
    _reauthPasswordController.dispose();
    super.dispose();
  }

  String _getAccountType(User user) {
    if (user.isAnonymous) {
      return 'Anonymous';
    }

    final providers = user.providerData.map((e) => e.providerId).toList();

    if (providers.contains('google.com')) {
      return 'Google';
    } else if (providers.contains('password')) {
      return 'Email/Password';
    } else {
      return 'Unknown';
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).updateProfile(
            displayName: _displayNameController.text.trim(),
          );
      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Profile updated successfully',
            isError: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is FirebaseAuthException
                ? ref.read(authServiceProvider).getReadableAuthError(e)
                : e.toString(),
            isError: true);
      }
    }
  }

  Future<void> _updateEmail() async {
    if (_emailController.text.trim().isEmpty) {
      display_name.showThemedSnackBar(
          context: context,
          message: 'Please enter a valid email address',
          isError: true);
      return;
    }

    // Show confirmation dialog to inform user they'll be logged out
    final shouldProceed = await showEmailUpdateConfirmationDialog(context);

    if (!shouldProceed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).verifyBeforeUpdateEmail(
            _emailController.text.trim(),
          );
      setState(() {
        _isLoading = false;
        _showChangeEmail = false;
      });

      // Show final logout confirmation dialog
      if (mounted) {
        await showEmailUpdateCompletedDialog(context);

        // Log out the user and redirect to profile page
        await _signOut();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      talker.debug('Caught FirebaseAuthException with code: ${e.code}');
      if (e.code == 'requires-recent-login') {
        talker.debug('Email update requires re-authentication');
        if (mounted) {
          final shouldReauth =
              await showReauthRequiredDialog(context, isForDeletion: false);
          if (shouldReauth) {
            setState(() {
              _showReauthDialog = true;
              _isAccountDeletion = false;
            });
          }
        }
        return;
      } else {
        talker.error('Error updating email: $e');

        // Show error message
        if (mounted) {
          display_name.showThemedSnackBar(
            context: context,
            message: ref.read(authServiceProvider).getReadableAuthError(e),
            isError: true,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      talker.error('Unexpected error during email update: $e');

      // Check if the error message contains "requires-recent-login" or "recent authentication"
      if (e.toString().contains('requires-recent-login') ||
          e.toString().contains('recent authentication')) {
        talker.debug(
            'Detected re-authentication requirement from generic exception');
        if (mounted) {
          final shouldReauth =
              await showReauthRequiredDialog(context, isForDeletion: false);
          if (shouldReauth) {
            setState(() {
              _showReauthDialog = true;
              _isAccountDeletion = false;
            });
          }
        }
        return;
      }

      // Show error message
      if (mounted) {
        display_name.showThemedSnackBar(
          context: context,
          message: e.toString(),
          isError: true,
        );
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Error signing out: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final shouldDelete = await showDeleteConfirmationDialog(context);
    if (!shouldDelete) return;

    try {
      setState(() {
        talker.debug('Starting account deletion');
        _isLoading = true;
      });

      await ref.read(authServiceProvider).deleteUser();

      setState(() {
        _isLoading = false;
      });
      talker.info('Account deleted successfully');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      talker.debug('Caught FirebaseAuthException with code: ${e.code}');

      // Handle specific error codes
      if (e.code == 'requires-recent-login' || e.code == 'user-token-expired') {
        talker.debug('Account deletion requires re-authentication: ${e.code}');
        if (mounted) {
          final shouldReauth = await showReauthRequiredDialog(context);
          if (shouldReauth) {
            setState(() {
              _showReauthDialog = true;
              _isAccountDeletion = true;
            });
          }
        }
        return;
      } else {
        talker.error('Error deleting account: $e');

        // Show a themed dialog instead of a snackbar
        if (mounted) {
          showDialog<void>(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              String errorMessage =
                  ref.read(authServiceProvider).getReadableAuthError(e);

              // Make the error message more user-friendly
              if (errorMessage.contains('An unexpected error occurred')) {
                errorMessage =
                    'An error occurred while deleting your account. Please try again or contact support if the problem persists.';
              }

              return AlertDialog(
                title: Text('Error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                content: Text(
                  errorMessage,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      talker.error('Unexpected error during account deletion: $e');

      // Check if the error message contains "requires-recent-login", "user-token-expired", or "recent authentication"
      if (e.toString().contains('requires-recent-login') ||
          e.toString().contains('user-token-expired') ||
          e.toString().contains('recent authentication') ||
          e.toString().contains('session has expired')) {
        talker.debug(
            'Detected re-authentication requirement from generic exception');
        if (mounted) {
          final shouldReauth = await showReauthRequiredDialog(context);
          if (shouldReauth) {
            setState(() {
              _showReauthDialog = true;
              _isAccountDeletion = true;
            });
          }
        }
        return;
      }

      if (mounted) {
        showDialog<void>(
          barrierDismissible: false,
          context: context,
          builder: (BuildContext context) {
            String errorMessage =
                'An unexpected error occurred. Please try again or contact support if the problem persists.';

            // Try to provide a more specific error message if possible
            if (e.toString().contains('requires-recent-login') ||
                e.toString().contains('user-token-expired') ||
                e.toString().contains('recent authentication') ||
                e.toString().contains('session has expired')) {
              errorMessage =
                  'For security reasons, this operation requires recent authentication. Please sign in again to continue.';
            }

            return AlertDialog(
              title: Text('Error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              content: Text(
                errorMessage,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary)),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<void> _reauthenticateAndDeleteAccount() async {
    if (_reauthEmailController.text.isEmpty ||
        _reauthPasswordController.text.isEmpty) {
      talker.debug('Email or password empty in reauthentication dialog');
      display_name.showThemedSnackBar(
          context: context,
          message: 'Please enter your email and password',
          isError: true,
          duration: const Duration(seconds: 5));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Re-authenticate the user
      await ref.read(authServiceProvider).reauthenticateWithEmailAndPassword(
            _reauthEmailController.text.trim(),
            _reauthPasswordController.text,
          );
      talker.debug(
          'Re-authentication successful, proceeding with account deletion');

      // Now try to delete the account again
      await ref.read(authServiceProvider).deleteUser();

      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Keep the dialog open on error
        _showReauthDialog = true;
      });

      talker.error('Error during re-authentication or account deletion: $e');

      // Show error message in a dialog
      if (mounted) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Authentication Error',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                content: Text(
                  e is FirebaseAuthException
                      ? ref.read(authServiceProvider).getReadableAuthError(e)
                      : 'An error occurred during authentication. Please check your credentials and try again.',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              );
            });
      }
    }
  }

  Future<void> _reauthenticateAndContinue() async {
    if (_reauthEmailController.text.isEmpty ||
        _reauthPasswordController.text.isEmpty) {
      display_name.showThemedSnackBar(
          context: context,
          message: 'Please enter your email and password',
          isError: true,
          duration: const Duration(seconds: 5));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Re-authenticate the user
      await ref.read(authServiceProvider).reauthenticateWithEmailAndPassword(
            _reauthEmailController.text.trim(),
            _reauthPasswordController.text,
          );

      talker.debug('Re-authentication successful');

      // Close the re-auth dialog
      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });

      // If this was for email update, try to update the email now
      if (!_isAccountDeletion && _showChangeEmail) {
        talker.debug('Proceeding with email update after re-authentication');

        // Show a loading indicator while updating email
        setState(() {
          _isLoading = true;
        });

        try {
          await ref.read(authServiceProvider).verifyBeforeUpdateEmail(
                _emailController.text.trim(),
              );

          setState(() {
            _isLoading = false;
            _showChangeEmail = false;
          });

          // Show final logout confirmation dialog
          if (mounted) {
            await showEmailUpdateCompletedDialog(context);

            // Log out the user
            await _signOut();
          }
        } catch (emailError) {
          setState(() {
            _isLoading = false;
          });

          // Show error message
          if (mounted) {
            display_name.showThemedSnackBar(
                context: context,
                message: emailError is FirebaseAuthException
                    ? ref
                        .read(authServiceProvider)
                        .getReadableAuthError(emailError)
                    : emailError.toString(),
                isError: true);
          }
        }
      } else {
        // Just show a general success message
        if (mounted) {
          display_name.showThemedSnackBar(
              context: context,
              message:
                  'Authentication successful. You can now continue with your action.',
              isError: false);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is FirebaseAuthException
                ? ref.read(authServiceProvider).getReadableAuthError(e)
                : e.toString(),
            isError: true);
      }
    }
  }

  Future<void> _unlinkProvider(String providerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).unlinkProvider(providerId);

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message:
                'Successfully unlinked ${_getProviderDisplayName(providerId)}',
            isError: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is FirebaseAuthException
                ? ref.read(authServiceProvider).getReadableAuthError(e)
                : e.toString(),
            isError: true);
      }
    }
  }

  String _getProviderDisplayName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email/Password';
      default:
        return 'Unknown Provider';
    }
  }

  IconData _getProviderIcon(String providerId) {
    switch (providerId) {
      case 'google.com':
        return Icons.g_mobiledata;
      case 'password':
        return Icons.email_outlined;
      default:
        return Icons.account_circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.watch(splashScreenPreferencesProvider); // Used for reactivity
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contrast = theme.extension<ContrastExtension>();

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    // Show re-authentication dialog if needed
    if (_showReauthDialog) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Re-authenticate'),
        ),
        body: ProfileReauthDialog(
          reauthEmailController: _reauthEmailController,
          reauthPasswordController: _reauthPasswordController,
          showReauthPassword: _showReauthPassword,
          isAccountDeletion: _isAccountDeletion,
          isLoading: _isLoading,
          onTogglePasswordVisibility: () {
            setState(() {
              _showReauthPassword = !_showReauthPassword;
            });
          },
          onCancel: () {
            setState(() {
              _showReauthDialog = false;
            });
          },
          onAuthenticate: _isAccountDeletion
              ? _reauthenticateAndDeleteAccount
              : _reauthenticateAndContinue,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : ListView(
              children: [
                // Authentication section for unauthenticated users
                if (!authState.isAuthenticated &&
                    !authState.isEmailNotVerified &&
                    !authState.isAnonymous)
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in to your account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: contrast?.onSurfaceWithContrast ??
                                  colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to save your collection, decks, and settings across devices.',
                            style: TextStyle(
                              fontSize: 16,
                              color: contrast?.onSurfaceWithContrast ??
                                  colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => context.go('/profile/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        contrast?.primaryWithContrast ??
                                            colorScheme.primary,
                                    foregroundColor:
                                        contrast?.onPrimaryWithContrast ??
                                            colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: const Text('Sign In'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () =>
                                      context.go('/profile/register'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        contrast?.primaryWithContrast ??
                                            colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: contrast?.primaryWithContrast ??
                                          colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Email verification warning if needed
                if (authState.isEmailNotVerified)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: colorScheme.error),
                            const SizedBox(width: 8),
                            Text(
                              'Email Not Verified',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please check your email and verify your account. A verification email has been sent to ${authState.user!.email}. You will be signed out until you verify your email.',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Resend verification email
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Sending verification email...'),
                                  duration: Duration(seconds: 2),
                                ),
                              );

                              try {
                                await ref
                                    .read(authServiceProvider)
                                    .sendEmailVerification();
                                if (context.mounted) {
                                  scaffoldMessenger.clearSnackBars();
                                  display_name.showThemedSnackBar(
                                    context: context,
                                    message:
                                        'Verification email resent. Please check your inbox.',
                                    isError: false,
                                  );
                                }
                              } catch (error) {
                                talker.error(
                                    'Error sending verification email', error);

                                if (context.mounted) {
                                  scaffoldMessenger.clearSnackBars();

                                  String errorMessage =
                                      'Failed to resend verification email. Please try again later.';

                                  if (error is FirebaseAuthException) {
                                    if (error.code == 'too-many-requests') {
                                      errorMessage =
                                          'Too many requests. We have temporarily blocked email sending due to unusual activity. Please try again later.';
                                    }
                                  }

                                  display_name.showThemedSnackBar(
                                    context: context,
                                    message: errorMessage,
                                    isError: true,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Resend Verification Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Account Information Card
                if (authState.isAuthenticated ||
                    authState.isEmailNotVerified ||
                    authState.isAnonymous)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            leading: const Icon(Icons.email_outlined),
                            title: const Text('Email'),
                            subtitle: Text(authState.user?.email ?? 'No email'),
                            trailing: authState.user != null &&
                                    !authState.user!.isAnonymous &&
                                    authState.user!.providerData.any(
                                        (element) =>
                                            element.providerId == 'password')
                                ? TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showChangeEmail = !_showChangeEmail;
                                      });
                                    },
                                    child: Text(
                                        _showChangeEmail ? 'Cancel' : 'Change'),
                                  )
                                : null,
                          ),
                          if (_showChangeEmail) ...[
                            const SizedBox(height: 16),
                            ProfileEmailUpdate(
                              emailController: _emailController,
                              onUpdateEmail: _updateEmail,
                              isLoading: _isLoading,
                            ),
                          ],
                          ListTile(
                            leading: const Icon(Icons.account_circle_outlined),
                            title: const Text('Account Type'),
                            subtitle: Text(authState.user != null
                                ? _getAccountType(authState.user!)
                                : 'Unknown'),
                          ),
                          if (authState.isAnonymous)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Anonymous Account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your data is only stored on this device. To save your data across devices, upgrade to a permanent account.',
                                    style: TextStyle(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.white
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              context.go('/profile/login'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                contrast?.primaryWithContrast ??
                                                    colorScheme.primary,
                                            foregroundColor: contrast
                                                    ?.onPrimaryWithContrast ??
                                                colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text('Sign In'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              context.go('/profile/register'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                contrast?.primaryWithContrast ??
                                                    colorScheme.primary,
                                            foregroundColor: contrast
                                                    ?.onPrimaryWithContrast ??
                                                colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text('Create Account'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Profile Settings for authenticated users
                if (authState.isAuthenticated || authState.isEmailNotVerified)
                  display_name.ProfileDisplayName(
                    displayNameController: _displayNameController,
                    onUpdateProfile: _updateProfile,
                    isLoading: _isLoading,
                  ),

                // Linked Providers section for authenticated users with multiple providers
                if (authState.isAuthenticated &&
                    !authState.isAnonymous &&
                    authState.user!.providerData.length > 1)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Linked Providers',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(_showLinkedProviders
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                                onPressed: () {
                                  setState(() {
                                    _showLinkedProviders =
                                        !_showLinkedProviders;
                                  });
                                },
                                tooltip: _showLinkedProviders
                                    ? 'Hide providers'
                                    : 'Show providers',
                              ),
                            ],
                          ),
                          if (_showLinkedProviders) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'You can unlink authentication providers from your account. You must keep at least one provider linked.',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...authState.user!.providerData.map((provider) {
                              return ListTile(
                                title: Text(_getProviderDisplayName(
                                    provider.providerId)),
                                subtitle: Text(provider.email ?? 'No email'),
                                leading:
                                    Icon(_getProviderIcon(provider.providerId)),
                                trailing:
                                    authState.user!.providerData.length > 1
                                        ? IconButton(
                                            icon: const Icon(Icons.link_off),
                                            onPressed: () => _unlinkProvider(
                                                provider.providerId),
                                            tooltip: 'Unlink provider',
                                          )
                                        : null,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),

                // Account Actions for authenticated users
                if (authState.isAuthenticated || authState.isEmailNotVerified)
                  ProfileAccountActions(
                    onSignOut: _signOut,
                    onDeleteAccount: _deleteAccount,
                    onResetPassword: () =>
                        context.go('/profile/reset-password'),
                  ),

                const Divider(),

                // App settings section
                const ProfileSettings(),
              ],
            ),
    );
  }
}
