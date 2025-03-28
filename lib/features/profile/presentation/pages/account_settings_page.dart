import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool _isAccountDeletion = false;
  final _reauthEmailController = TextEditingController();
  bool _showReauthPassword = false;
  final _reauthPasswordController = TextEditingController();

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

        // Log out the user and redirect to profile page without confirmation
        await _signOutWithoutConfirmation();
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

  // Sign out without showing confirmation dialog
  Future<void> _signOutWithoutConfirmation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).signOut();
      // The UI will automatically update due to the authStateProvider

      // Set loading to false after successful sign-out
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

      // Sign out to reset the authentication state
      await ref.read(authServiceProvider).signOut();

      setState(() {
        _isLoading = false;
      });
      talker.info('Account deleted successfully');

      // Navigate back to profile page after successful deletion
      if (mounted) {
        context.go('/profile');
      }
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
              final colorScheme = Theme.of(context).colorScheme;
              String errorMessage =
                  ref.read(authServiceProvider).getReadableAuthError(e);

              // Make the error message more user-friendly
              if (errorMessage.contains('An unexpected error occurred')) {
                errorMessage =
                    'An error occurred while deleting your account. Please try again or contact support if the problem persists.';
              }

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    const Text('Error'),
                  ],
                ),
                content: Text(
                  errorMessage,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                actions: [
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
            final colorScheme = Theme.of(context).colorScheme;
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  const Text('Error'),
                ],
              ),
              content: Text(
                errorMessage,
                style: TextStyle(color: colorScheme.onSurface),
              ),
              actions: [
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
    }
  }

  Future<void> _reauthenticateWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      talker.debug('Starting Google re-authentication from account settings');

      // Re-authenticate with Google using the improved method
      await ref.read(authServiceProvider).reauthenticateWithGoogle();

      talker.debug('Google re-authentication successful');

      // Close the re-auth dialog
      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });

      // If this was for account deletion, proceed with deletion
      if (_isAccountDeletion) {
        talker
            .debug('Proceeding with account deletion after re-authentication');
        await _deleteAccount();
      }
      // If this was for email update, proceed with email update
      else if (_showChangeEmail) {
        talker.debug('Proceeding with email update after re-authentication');
        await _updateEmail();
      }
      // Otherwise just show a success message
      else {
        if (mounted) {
          display_name.showThemedSnackBar(
            context: context,
            message: 'Authentication successful',
            isError: false,
          );
        }
      }
    } catch (e) {
      talker.error('Error during Google re-authentication: $e');

      setState(() {
        _isLoading = false;
      });

      // Handle specific error cases
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-account') {
          // Special handling for wrong Google account
          if (mounted) {
            display_name.showThemedSnackBar(
              context: context,
              message:
                  'Please use the same Google account you originally signed in with.',
              isError: true,
              duration: const Duration(seconds: 5),
            );
          }
          return;
        }
      }

      // Show general error message
      if (mounted) {
        display_name.showThemedSnackBar(
          context: context,
          message: e is FirebaseAuthException
              ? ref.read(authServiceProvider).getReadableAuthError(e)
              : e.toString(),
          isError: true,
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

      // Sign out to reset the authentication state
      await ref.read(authServiceProvider).signOut();

      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });

      // Navigate back to profile page after successful deletion
      if (mounted) {
        context.go('/profile');
      }
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
              final colorScheme = Theme.of(context).colorScheme;
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error),
                    const SizedBox(width: 12),
                    const Text('Authentication Error'),
                  ],
                ),
                content: Text(
                  e is FirebaseAuthException
                      ? ref.read(authServiceProvider).getReadableAuthError(e)
                      : 'An error occurred during authentication. Please check your credentials and try again.',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                actions: [
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

            // Log out the user without confirmation
            await _signOutWithoutConfirmation();
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

  /// Link the current account with Google
  Future<void> _linkWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).linkWithGoogle();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        display_name.showThemedSnackBar(
          context: context,
          message: 'Successfully linked with Google',
          isError: false,
        );
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
          isError: true,
        );
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
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
              ? _reauthenticateAndDeleteAccount
              : _reauthenticateAndContinue,
          onGoogleAuthenticate: _reauthenticateWithGoogle,
        ),
      );
    }

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
                  // Profile Header with display name
                  ProfileHeaderCard(
                    user: authState.user,
                    displayNameController: _displayNameController,
                    onUpdateProfile: _updateProfile,
                    isLoading: _isLoading,
                  ),

                  // Account Information
                  AccountInfoCard(
                    user: authState.user,
                    isEmailNotVerified: authState.isEmailNotVerified,
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
                    onLinkWithEmailPassword: (email, password) {
                      ref
                          .read(authServiceProvider)
                          .linkWithEmailAndPassword(email, password);
                    },
                    isLoading: _isLoading,
                  ),

                  // Account Actions
                  AccountActionsCard(
                    user: authState.user,
                    onSignOut: _signOut,
                    onDeleteAccount: _deleteAccount,
                  ),
                ],
              ),
            ),
    );
  }
}

Future<bool> showSignOutConfirmationDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
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
      false;
}

Future<bool> showEmailUpdateConfirmationDialog(BuildContext context) async {
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
                Icon(Icons.email_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Confirm Email Update'),
              ],
            ),
            content: const Text(
                'After updating your email, you will need to verify the new email address and sign in again. You will be signed out after this operation. Continue?'),
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

Future<void> showEmailUpdateCompletedDialog(BuildContext context) async {
  final colorScheme = Theme.of(context).colorScheme;
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
            const Text('Email Update Initiated'),
          ],
        ),
        content: const Text(
            'A verification email has been sent to your new email address. Please check your inbox and verify your email. You will be signed out now and need to sign in again after verification.'),
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
    {bool isForDeletion = true}) async {
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
                'For security reasons, you need to re-authenticate before ${isForDeletion ? 'deleting your account' : 'updating your email'}.'),
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
