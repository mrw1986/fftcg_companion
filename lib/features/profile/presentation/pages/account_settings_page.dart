import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_display_name.dart'
    as display_name;
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_reauth_dialog.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/profile_auth_methods.dart';

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
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
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
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
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
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
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

  Widget _buildProfileHeader(User? user, ColorScheme colorScheme) {
    if (user == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            display_name.ProfileDisplayName(
              displayNameController: _displayNameController,
              onUpdateProfile: _updateProfile,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo(
      User? user, ColorScheme colorScheme, bool isEmailNotVerified) {
    if (user == null) return const SizedBox.shrink();

    final providers = user.providerData.map((e) => e.providerId).toList();
    final hasPassword = providers.contains('password');
    providers.contains('google.com');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

            // Email with verification status
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(user.email ?? 'No email'),
                  ),
                  if (isEmailNotVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Unverified',
                          style: TextStyle(
                              color: colorScheme.onError, fontSize: 12)),
                    ),
                ],
              ),
              trailing: user.email != null &&
                      !user.isAnonymous &&
                      !isEmailNotVerified &&
                      hasPassword
                  ? TextButton(
                      onPressed: () {
                        setState(() {
                          _showChangeEmail = !_showChangeEmail;
                        });
                      },
                      child: Text(_showChangeEmail ? 'Cancel' : 'Change',
                          style: TextStyle(color: Colors.green)),
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

            // Authentication Methods section
            const SizedBox(height: 8),
            const Text(
              'Authentication Methods',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Use ProfileAuthMethods instead of duplicating authentication logic
            ProfileAuthMethods(
              user: user,
              onUnlinkProvider: _unlinkProvider,
              onLinkWithGoogle: _linkWithGoogle,
              onLinkWithEmailPassword: (email, password) {
                ref
                    .read(authServiceProvider)
                    .linkWithEmailAndPassword(email, password);
              },
              onShowLinkEmailPasswordDialog: () {
                setState(() {
                  _showChangeEmail = !_showChangeEmail;
                });
              },
            ),

            // Reset password option for password users
            if (!user.isAnonymous && hasPassword)
              ListTile(
                title: const Text('Reset Password'),
                subtitle: const Text('Send a password reset email'),
                leading: const Icon(Icons.lock_reset_outlined),
                onTap: () => context.go('/profile/reset-password'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions(User? user, ColorScheme colorScheme) {
    if (user == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Sign Out'),
              subtitle: const Text('Sign out of your current account'),
              leading: const Icon(Icons.logout_outlined),
              onTap: _signOut,
            ),
            if (!user.isAnonymous) ...[
              const Divider(),
              ListTile(
                title: const Text('Delete Account'),
                subtitle: const Text(
                    'Permanently delete your account and all associated data'),
                leading: const Icon(Icons.delete_forever_outlined,
                    color: Colors.red),
                onTap: _deleteAccount,
              ),
            ],
          ],
        ),
      ),
    );
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
        ),
      );
    }

    return Scaffold(
      appBar: AppBarFactory.createAppBar(context, 'Account Settings'),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : ListView(
              children: [
                // Profile Header with display name
                _buildProfileHeader(authState.user, colorScheme),

                // Account Information
                _buildAccountInfo(
                    authState.user, colorScheme, authState.isEmailNotVerified),

                // Account Actions
                _buildAccountActions(authState.user, colorScheme),
              ],
            ),
    );
  }
}

Future<bool> showSignOutConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sign Out'),
            content: const Text(
                'Are you sure you want to sign out of your account?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Sign Out'),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<bool> showEmailUpdateConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Email Update'),
            content: const Text(
                'After updating your email, you will need to verify the new email address and sign in again. You will be signed out after this operation. Continue?'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<void> showEmailUpdateCompletedDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Email Update Initiated'),
        content: const Text(
            'A verification email has been sent to your new email address. Please check your inbox and verify your email. You will be signed out now and need to sign in again after verification.'),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Account Deletion'),
            content: const Text(
                'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Delete Account'),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<bool> showReauthRequiredDialog(BuildContext context,
    {bool isForDeletion = true}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Authentication Required'),
            content: Text(
                'For security reasons, you need to re-authenticate before ${isForDeletion ? 'deleting your account' : 'updating your email'}.'),
            actions: <Widget>[
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      ) ??
      false;
}
