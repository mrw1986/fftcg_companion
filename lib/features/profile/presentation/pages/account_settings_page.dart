import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_display_name.dart'
    as display_name;
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_reauth_dialog.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/account_info_card.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/account_actions_card.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/update_password_dialog.dart';
// Import AuthException
import 'package:fftcg_companion/core/services/auth_service.dart';
// Import SnackBarHelper
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showChangeEmail = false;
  bool _showReauthDialog = false;
  bool _isAccountDeletion = false; // Flag for deletion re-auth
  bool _isPasswordChange = false; // Flag for password change re-auth
  final _reauthEmailController = TextEditingController();
  bool _showReauthPassword = false;
  final _reauthPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial population might still happen here, but build method will override
    _initializeUserDataFromState(ref.read(authStateProvider).user);
  }

  // Initialize controllers based on user data
  void _initializeUserDataFromState(User? user) {
    if (user != null) {
      // For display name:
      // 1. If current display name is empty, try to get it from:
      //    a. User's display name
      //    b. Google provider's display name
      if (_displayNameController.text.isEmpty) {
        String? newDisplayName = user.displayName;

        if (newDisplayName == null || newDisplayName.isEmpty) {
          // Try to get display name from Google provider
          try {
            final googleProvider = user.providerData.firstWhere(
              (element) => element.providerId == 'google.com',
            );
            newDisplayName = googleProvider.displayName;
          } catch (_) {
            // No Google provider found, continue with null display name
          }
        }

        if (newDisplayName != null && newDisplayName.isNotEmpty) {
          _displayNameController.text = newDisplayName;
        }
      }
      // Otherwise, only update if the text is different to avoid cursor jumps
      else if (user.displayName != null &&
          _displayNameController.text != user.displayName) {
        _displayNameController.text = user.displayName!;
      }

      // For email:
      if (user.email != null && _emailController.text != user.email) {
        _emailController.text = user.email!;
        // Also update reauth email only if different
        if (_reauthEmailController.text != user.email) {
          _reauthEmailController.text = user.email!;
        }
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

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).updateProfile(
            displayName: _displayNameController.text.trim(),
          );
      // No need to manually update controllers, watch will trigger rebuild
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
            message: e is AuthException // Catch custom AuthException
                ? e.message // Use message from AuthException
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

    // Show confirmation dialog (updated message)
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
        _showChangeEmail = false; // Hide the input field after initiating
      });

      // Show confirmation dialog (updated message)
      if (mounted) {
        await showEmailUpdateInitiatedDialog(
            context, _emailController.text.trim());
      }
    } on AuthException catch (e) {
      // Catch custom AuthException
      setState(() {
        _isLoading = false;
      });

      talker.debug('Caught AuthException with code: ${e.code}');
      if (e.code == 'requires-recent-login') {
        talker.debug('Email update requires re-authentication');
        if (mounted) {
          final shouldReauth =
              await showReauthRequiredDialog(context, isForDeletion: false);
          if (shouldReauth) {
            setState(() {
              _showReauthDialog = true;
              _isAccountDeletion = false; // Ensure deletion flag is false
              _isPasswordChange = false; // Ensure password change flag is false
            });
          }
        }
        return;
      } else {
        talker.error('Error updating email: $e');
        // Show error message from AuthException
        if (mounted) {
          display_name.showThemedSnackBar(
            context: context,
            message: e.message,
            isError: true,
          );
        }
      }
    } catch (e) {
      // Catch other potential errors
      setState(() {
        _isLoading = false;
      });

      talker.error('Unexpected error during email update: $e');

      // Check if the error message indicates re-authentication needed (less reliable)
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
              _isPasswordChange = false;
            });
          }
        }
        return;
      }

      // Show generic error message
      if (mounted) {
        display_name.showThemedSnackBar(
          context: context,
          message: 'An unexpected error occurred while updating email.',
          isError: true,
        );
      }
    }
  }

  // Sign out without showing confirmation dialog
  Future<void> _signOutWithoutConfirmation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).signOut();
      // UI will update via provider watch

      setState(() {
        _isLoading = false;
      });

      // Navigate back to profile page
      if (mounted) {
        context.go('/profile');
      }
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

  Future<void> _signOut() async {
    // Show confirmation dialog
    final shouldSignOut = await showSignOutConfirmationDialog(context);
    if (!shouldSignOut) return;

    await _signOutWithoutConfirmation();
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
      await ref.read(authServiceProvider).signOut(); // Sign out after deletion

      setState(() {
        _isLoading = false;
      });
      talker.info('Account deleted successfully');

      // Navigate back to profile page after successful deletion
      if (mounted) {
        context.go('/profile');
      }
    } on AuthException catch (e) {
      // Catch custom AuthException
      setState(() {
        _isLoading = false;
      });

      talker.debug('Caught AuthException with code: ${e.code}');

      // Handle specific error codes
      if (e.code == 'requires-recent-login' || e.code == 'user-token-expired') {
        talker.debug('Account deletion requires re-authentication: ${e.code}');
        if (mounted) {
          final shouldReauth = await showReauthRequiredDialog(context);
          if (shouldReauth) {
            setState(() {
              _showReauthDialog = true;
              _isAccountDeletion = true; // Set deletion flag
              _isPasswordChange = false; // Ensure password change flag is false
            });
          }
        }
        return;
      } else {
        talker.error('Error deleting account: $e');
        if (mounted) {
          showDialog<void>(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              final colorScheme = Theme.of(context).colorScheme;
              String errorMessage = e.message;
              if (errorMessage.contains('An unexpected error occurred')) {
                errorMessage =
                    'An error occurred while deleting your account. Please try again or contact support if the problem persists.';
              }
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  const Text('Error')
                ]),
                content: Text(errorMessage,
                    style: TextStyle(color: colorScheme.onSurface)),
                actions: [
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'))
                ],
                actionsPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              );
            },
          );
        }
      }
    } catch (e) {
      // Catch other unexpected errors
      setState(() {
        _isLoading = false;
      });
      talker.error('Unexpected error during account deletion: $e');
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
              _isPasswordChange = false;
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
            final colorScheme = Theme.of(context).colorScheme;
            String errorMessage =
                'An unexpected error occurred. Please try again or contact support if the problem persists.';
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(children: [
                Icon(Icons.error_outline, color: colorScheme.error),
                const SizedBox(width: 12),
                const Text('Error')
              ]),
              content: Text(errorMessage,
                  style: TextStyle(color: colorScheme.onSurface)),
              actions: [
                FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'))
              ],
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            );
          },
        );
      }
    }
  }

  Future<void> _reauthenticateWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      talker.debug('Starting Google re-authentication from account settings');
      await ref.read(authServiceProvider).reauthenticateWithGoogle();
      talker.debug('Google re-authentication successful');
      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });
      if (_isAccountDeletion) {
        talker
            .debug('Proceeding with account deletion after re-authentication');
        await _deleteAccount();
      } else if (_showChangeEmail) {
        talker.debug('Proceeding with email update after re-authentication');
        await _updateEmail();
      } else if (_isPasswordChange) {
        talker.debug('Proceeding with password change after re-authentication');
        if (mounted) {
          _showUpdatePasswordDialog();
        }
      } else {
        if (mounted) {
          display_name.showThemedSnackBar(
              context: context,
              message: 'Authentication successful',
              isError: false);
        }
      }
    } catch (e) {
      talker.error('Error during Google re-authentication: $e');
      setState(() {
        _isLoading = false;
      });
      if (e is AuthException && e.code == 'wrong-account') {
        if (mounted) {
          display_name.showThemedSnackBar(
              context: context,
              message: e.message,
              isError: true,
              duration: const Duration(seconds: 5));
        }
        return;
      }
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is AuthException ? e.message : e.toString(),
            isError: true);
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
      await ref.read(authServiceProvider).reauthenticateWithEmailAndPassword(
            _reauthEmailController.text.trim(),
            _reauthPasswordController.text,
          );
      talker.debug(
          'Re-authentication successful, proceeding with account deletion');
      await ref.read(authServiceProvider).deleteUser();
      await ref.read(authServiceProvider).signOut();
      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });
      if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _showReauthDialog = true;
      });
      talker.error('Error during re-authentication or account deletion: $e');
      if (mounted) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              final colorScheme = Theme.of(context).colorScheme;
              return AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Row(children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  const Text('Authentication Error')
                ]),
                content: Text(
                    e is AuthException
                        ? e.message
                        : 'An error occurred during authentication. Please check your credentials and try again.',
                    style: TextStyle(color: colorScheme.onSurface)),
                actions: [
                  FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'))
                ],
                actionsPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      await ref.read(authServiceProvider).reauthenticateWithEmailAndPassword(
            _reauthEmailController.text.trim(),
            _reauthPasswordController.text,
          );
      talker.debug('Re-authentication successful');
      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });
      if (!_isAccountDeletion && !_isPasswordChange && _showChangeEmail) {
        talker.debug('Proceeding with email update after re-authentication');
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
          if (mounted) {
            await showEmailUpdateInitiatedDialog(
                context, _emailController.text.trim());
          }
        } catch (emailError) {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            display_name.showThemedSnackBar(
                context: context,
                message: emailError is AuthException
                    ? emailError.message
                    : emailError.toString(),
                isError: true);
          }
        }
      } else if (_isPasswordChange) {
        talker.debug('Proceeding with password change after re-authentication');
        if (mounted) {
          _showUpdatePasswordDialog();
        }
      } else {
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
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is AuthException ? e.message : e.toString(),
            isError: true);
      }
    }
  }

  Future<void> _unlinkProvider(String providerId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call unlink and wait for the reloaded user
      await ref.read(unlinkProviderProvider(providerId).future); // Use .future
      // Invalidation is handled by the provider now, state will update via watch

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
            message: e is AuthException // Catch custom AuthException
                ? e.message // Use message from AuthException
                : e.toString(),
            isError: true);
      }
    }
  }

  /// Link the current account with Google
  Future<void> _linkWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(linkGoogleToEmailPasswordProvider.future);
      // Explicitly invalidate providers to ensure UI updates
      ref.invalidate(currentUserProvider);
      ref.invalidate(authStateProvider);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Successfully linked with Google',
            isError: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is AuthException ? e.message : e.toString(),
            isError: true);
      }
    }
  }

  /// Link the current account with Email/Password
  Future<void> _linkWithEmailPassword(String email, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).user;
      final hasGoogleProvider = user?.providerData.any(
            (element) => element.providerId == 'google.com',
          ) ??
          false;

      if (hasGoogleProvider && !user!.isAnonymous) {
        await ref.read(linkEmailPasswordToGoogleProvider(
                EmailPasswordCredentials(email: email, password: password))
            .future);
      } else {
        await ref.read(authServiceProvider).linkEmailAndPasswordToAnonymous(
              email,
              password,
            );
      }
      // Invalidation handled by provider
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Successfully added Email/Password authentication',
            isError: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: e is AuthException ? e.message : e.toString(),
            isError: true);
      }
    }
  }

  /// Show the update password dialog
  void _showUpdatePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => UpdatePasswordDialog(
        onUpdatePassword: (newPassword) async {
          await _updatePassword(newPassword);
        },
      ),
    );
  }

  /// Update the user's password
  Future<void> _updatePassword(String newPassword) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(authServiceProvider).updatePassword(newPassword);
      // Invalidation handled by provider
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Password updated successfully.',
            isError: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message:
                e is AuthException ? e.message : 'Failed to update password.',
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

  // --- NEW: Verification Banner Widget ---
  Widget _buildVerificationBanner(
      BuildContext context, ColorScheme colorScheme, User user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
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
              Icon(Icons.warning_amber_rounded, color: colorScheme.error),
              const SizedBox(width: 8),
              Text(
                'Email Not Verified',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.error,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your email (${user.email}) and click the verification link. Until verified, your account has the same limitations as a guest account (e.g., 50 unique card limit).',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Resend verification email
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                SnackBarHelper.showSnackBar(
                  context: context,
                  message: 'Sending verification email...',
                  duration: const Duration(seconds: 2),
                );

                try {
                  await ref.read(authServiceProvider).sendEmailVerification();
                  if (context.mounted) {
                    scaffoldMessenger.clearSnackBars();
                    SnackBarHelper.showSuccessSnackBar(
                      context: context,
                      message:
                          'Verification email resent. Please check your inbox.',
                    );
                  }
                } catch (error) {
                  talker.error('Error sending verification email', error);

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

                    SnackBarHelper.showErrorSnackBar(
                      context: context,
                      message: errorMessage,
                    );
                  }
                }
              },
              icon: const Icon(Icons.email_outlined),
              label: const Text('Resend Verification Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    colorScheme.surface, // Use surface for contrast
                foregroundColor: colorScheme.error, // Keep error color for text
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- END: Verification Banner Widget ---

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    // Watch currentUserProvider to trigger rebuilds on user data changes (like unlink)
    final currentUserAsyncValue = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Update controllers whenever currentUser changes
    // Use addPostFrameCallback to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Ensure widget is still mounted
        _initializeUserDataFromState(currentUserAsyncValue.value);
      }
    });

    // Determine the user object to use for the UI
    // Prioritize the direct user stream value if available, fallback to authState
    final userForUI = currentUserAsyncValue.value ?? authState.user;

    // Handle loading state more robustly
    if (authState.isLoading ||
        (authState.isAuthenticated && userForUI == null)) {
      // Show loading if authState is loading OR if we expect an authenticated user but don't have one yet
      return Scaffold(
        appBar: AppBarFactory.createAppBar(context, 'Account Settings'),
        body: const Center(child: LoadingIndicator()),
      );
    }

    // Show re-authentication dialog if needed
    if (_showReauthDialog) {
      return Scaffold(
        appBar: AppBarFactory.createAppBar(context, 'Re-authenticate'),
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
              ? _reauthenticateAndDeleteAccount // Handles deletion
              : _reauthenticateAndContinue, // Handles email update or password change trigger
          onGoogleAuthenticate:
              _reauthenticateWithGoogle, // Handles Google re-auth
        ),
      );
    }

    // Determine if the email verification banner should be shown
    final bool showVerificationBanner =
        userForUI != null && !userForUI.emailVerified;

    return Scaffold(
      appBar: AppBarFactory.createAppBar(context, 'Account Settings'),
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // --- NEW: Conditionally show Verification Banner ---
                  if (showVerificationBanner)
                    _buildVerificationBanner(context, colorScheme,
                        userForUI), // Removed unnecessary '!'
                  // --- END: Verification Banner ---

                  // Profile Header with display name
                  ProfileHeaderCard(
                    user: userForUI, // Use userForUI
                    displayNameController: _displayNameController,
                    onUpdateProfile: _updateProfile,
                    isLoading: _isLoading,
                  ),

                  // Account Information
                  AccountInfoCard(
                    user: userForUI, // Pass userForUI down
                    isEmailNotVerified: showVerificationBanner, // Pass the flag
                    emailController: _emailController,
                    showChangeEmail: _showChangeEmail,
                    onToggleChangeEmail: () {
                      setState(() {
                        _showChangeEmail = !_showChangeEmail;
                      });
                    },
                    onUpdateEmail: _updateEmail,
                    onUnlinkProvider: _unlinkProvider,
                    onLinkWithGoogle: _linkWithGoogle,
                    onLinkWithEmailPassword: _linkWithEmailPassword,
                    onChangePassword: () async {
                      final shouldReauth = await showReauthRequiredDialog(
                          context,
                          isForDeletion: false,
                          actionText: 'changing your password');
                      if (shouldReauth) {
                        setState(() {
                          _showReauthDialog = true;
                          _isAccountDeletion = false;
                          _isPasswordChange = true;
                        });
                      }
                    },
                    isLoading: _isLoading,
                  ),

                  // Account Actions
                  AccountActionsCard(
                    user: userForUI, // Use userForUI
                    onSignOut: _signOut,
                    onDeleteAccount: _deleteAccount,
                  ),
                ],
              ),
            ),
    );
  }
}

// ... (Dialog functions remain the same) ...

// Updated Dialog: User stays logged in
Future<bool> showEmailUpdateConfirmationDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  final user = FirebaseAuth.instance.currentUser;

  // Check if user has Google auth (a verified method)
  final hasGoogleAuth = user?.providerData
          .any((userInfo) => userInfo.providerId == 'google.com') ??
      false;

  // Determine the appropriate message
  final message = hasGoogleAuth
      ? 'A verification link will be sent to your new email address. Please click the link to confirm the change.'
      : 'A verification link will be sent to your new email address. Please click the link to confirm the change. You will be logged out after updating your email.';

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.email_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Confirm Email Update'),
              ],
            ),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                    'Send Verification Email'), // Updated button text
              ),
            ],
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        },
      ) ??
      false;
}

// Renamed Dialog: Confirms email *sending*, not completion/logout
Future<void> showEmailUpdateInitiatedDialog(
    BuildContext context, String newEmail) async {
  final colorScheme = Theme.of(context).colorScheme;
  final user = FirebaseAuth.instance.currentUser;

  // Check if user has Google auth (a verified method)
  final hasGoogleAuth = user?.providerData
          .any((userInfo) => userInfo.providerId == 'google.com') ??
      false;

  // Determine the appropriate message
  final message = hasGoogleAuth
      ? 'A verification email has been sent to $newEmail. Please check your inbox and click the link to finalize the email change. You will remain logged in since you have other verified authentication methods.'
      : 'A verification email has been sent to $newEmail. Please check your inbox and click the link to finalize the email change. You will be logged out after verifying since this is your only authentication method.';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Verification Email Sent'),
          ],
        ),
        content: Text(message),
        actions: <Widget>[
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    },
  );
}

Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_forever_outlined, color: colorScheme.error),
                const SizedBox(width: 12),
                const Text('Confirm Account Deletion'),
              ],
            ),
            content: const Text(
                'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete Account'),
              ),
            ],
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        },
      ) ??
      false;
}

Future<bool> showReauthRequiredDialog(BuildContext context,
    {bool isForDeletion = true,
    String actionText = 'deleting your account'}) async {
  // Added actionText
  final colorScheme = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.security_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Authentication Required'),
              ],
            ),
            content: Text(
                'For security reasons, you need to re-authenticate before $actionText.'), // Use actionText
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        },
      ) ??
      false;
}

// Helper function to show sign-out confirmation dialog
Future<bool> showSignOutConfirmationDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true, // Allow dismissing by tapping outside
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.logout_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Sign Out'),
              ],
            ),
            content: const Text(
                'Are you sure you want to sign out of your account?'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Sign Out'),
              ),
            ],
            actionsPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          );
        },
      ) ??
      false; // Return false if dialog is dismissed
}
