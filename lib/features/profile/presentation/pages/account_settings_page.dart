import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';

import 'package:fftcg_companion/core/routing/app_router.dart'; // Import for rootNavigatorKeyProvider
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
// Import the new provider
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_completion_provider.dart';

// NEW: Provider to store the original email during the update process
final originalEmailForUpdateCheckProvider = StateProvider<String>((ref) => '');

class AccountSettingsPage extends ConsumerStatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  ConsumerState<AccountSettingsPage> createState() =>
      _AccountSettingsPageState();
}

// NEW: Add WidgetsBindingObserver mixin
class _AccountSettingsPageState extends ConsumerState<AccountSettingsPage>
    with WidgetsBindingObserver {
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

  // Keep track if controllers have been initialized to prevent unnecessary updates
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    // NEW: Add observer
    WidgetsBinding.instance.addObserver(this);
    // Initial read might get null if provider is still loading
    // We'll primarily rely on the build method for initialization now.
  }

  // Initialize controllers based on user data
  void _initializeUserDataFromState(User? user) {
    if (user != null) {
      // For display name:
      String? currentDisplayName = _displayNameController.text;
      String? newDisplayName = user.displayName;

      // Try Google provider name if Firebase display name is empty
      if (newDisplayName == null || newDisplayName.isEmpty) {
        try {
          final googleProvider = user.providerData.firstWhere(
            (element) => element.providerId == 'google.com',
          );
          newDisplayName = googleProvider.displayName;
        } catch (_) {
          // No Google provider found
        }
      }

      // Update controller only if needed
      if (newDisplayName != null &&
          newDisplayName.isNotEmpty &&
          currentDisplayName != newDisplayName) {
        _displayNameController.text = newDisplayName;
        talker.debug('Initialized display name controller: $newDisplayName');
      }

      // For email:
      String? currentEmail = _emailController.text;
      String? newUserEmail = user.email;

      if (newUserEmail != null && currentEmail != newUserEmail) {
        _emailController.text = newUserEmail;
        talker.debug('Initialized email controller: $newUserEmail');
        // Also update reauth email only if different
        if (_reauthEmailController.text != newUserEmail) {
          _reauthEmailController.text = newUserEmail;
          talker.debug('Initialized reauth email controller: $newUserEmail');
        }
      }
      // Mark as initialized
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    // NEW: Remove observer
    WidgetsBinding.instance.removeObserver(this);
    _displayNameController.dispose();
    _emailController.dispose();
    _reauthEmailController.dispose();
    _reauthPasswordController.dispose();
    super.dispose();
  }

  // NEW: Implement didChangeAppLifecycleState
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    talker.debug('App lifecycle state changed: $state');

    if (state == AppLifecycleState.resumed) {
      talker.debug('App resumed, checking for pending email update...');
      // Check if an email update is pending
      final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
      final originalEmail = ref.read(originalEmailForUpdateCheckProvider);

      talker.debug(
          'Lifecycle Check: PendingEmail=$pendingEmail, OriginalEmail=$originalEmail');

      if (pendingEmail != null &&
          pendingEmail.isNotEmpty &&
          originalEmail.isNotEmpty) {
        talker.debug(
            'Lifecycle Check: Pending update detected. Original: $originalEmail, Pending: $pendingEmail');
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          try {
            talker.debug('Lifecycle Check: Reloading user...');
            await user.reload();
            final reloadedUser = FirebaseAuth.instance.currentUser;
            final currentEmail = reloadedUser?.email;
            talker.debug(
                'Lifecycle Check: User reloaded. Current Email: $currentEmail');

            if (currentEmail != null &&
                currentEmail.isNotEmpty &&
                currentEmail != originalEmail) {
              talker.info(
                  'Lifecycle Check: Email change detected! Original: $originalEmail, Current: $currentEmail. Invalidating auth provider.');
              // Invalidate the main auth provider to trigger state update
              ref.invalidate(authNotifierProvider);
              // Reset the original email provider to prevent re-checking
              ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
              talker.debug(
                  'Lifecycle Check: Reset originalEmailForUpdateCheckProvider.');
            } else {
              talker.debug(
                  'Lifecycle Check: Email has not changed or is null/empty.');
            }
          } catch (e, s) {
            talker.error('Lifecycle Check: Error reloading user', e, s);
            // Handle specific errors like token expiration if necessary
            if (e is FirebaseAuthException &&
                (e.code == 'user-token-expired' ||
                    e.code == 'user-disabled' ||
                    e.code == 'user-not-found')) {
              talker.warning(
                  'Lifecycle Check: User token expired or user invalid during reload. Invalidating auth provider.');
              ref.invalidate(authNotifierProvider);
              // Reset the original email provider as the check failed
              ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
            }
            // Optionally show a generic error to the user?
            // SnackBarHelper.showErrorSnackBar(context: context, message: 'Failed to check for email update. Please try signing out and back in.');
          }
        } else {
          talker.debug('Lifecycle Check: No current user found.');
        }
      } else {
        talker.debug(
            'Lifecycle Check: No pending email update or original email not stored.');
      }
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
    final newEmail = _emailController.text.trim();
    if (newEmail.isEmpty) {
      if (!mounted) return;
      display_name.showThemedSnackBar(
          context: context,
          message: 'Please enter a valid email address',
          isError: true);
      return;
    }

    // Show confirmation dialog
    if (!mounted) return;
    final shouldProceed = await showEmailUpdateConfirmationDialog(context);
    if (!shouldProceed) return;

    // Get the original email BEFORE starting the update process
    final originalEmail = ref.read(firebaseUserProvider).value?.email;
    if (originalEmail == null) {
      if (!mounted) return;
      display_name.showThemedSnackBar(
          context: context,
          message: 'Could not determine current email. Please try again.',
          isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Store original email for lifecycle check
      ref.read(originalEmailForUpdateCheckProvider.notifier).state =
          originalEmail;
      talker.info('Stored original email for lifecycle check: $originalEmail');

      // Send verification email
      await ref.read(authServiceProvider).verifyBeforeUpdateEmail(newEmail);

      // Update pending email state
      ref.read(emailUpdateNotifierProvider.notifier).setPendingEmail(newEmail);
      talker.info('Verification email sent for email update.');

      setState(() {
        _isLoading = false;
        _showChangeEmail = false;
      });

      // Show confirmation dialog with appropriate message
      if (mounted) {
        final hasGoogleAuth = ref
                .read(authNotifierProvider)
                .user
                ?.providerData
                .any((userInfo) => userInfo.providerId == 'google.com') ??
            false;

        if (hasGoogleAuth) {
          await showEmailUpdateInitiatedDialog(context, newEmail,
              'You will remain logged in since you have Google authentication.');
        } else {
          await showEmailUpdateInitiatedDialog(context, newEmail,
              'You will be logged out after verifying the email change.');
        }
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
      // **NEW:** Clear pending email state before signing out
      ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
      // **NEW:** Clear original email state before signing out
      ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
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
      // Add mounted check before setState
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Show error message
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Error signing out: ${e.toString()}',
            isError: true);
      }
    }
  }

  // Helper function for successful deletion cleanup
  Future<void> _handleSuccessfulDeletion() async {
    talker.info(
        'Account deletion successful, showing confirmation and signing out.');
    // Get the root navigator context BEFORE the async gap of signOut
    final rootContext = ref.read(rootNavigatorKeyProvider).currentContext;

    // **NEW:** Clear pending email state before signing out
    ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
    // **NEW:** Clear original email state before signing out
    ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';

    // Add mounted check before showing snackbar and navigating
    if (mounted && rootContext != null) {
      // Show success snackbar using the root context
      display_name.showThemedSnackBar(
          context: rootContext, // Use root context here
          message: 'Account deleted successfully.',
          isError: false);

      // Sign out, skipping the dialog trigger
      await ref
          .read(authServiceProvider)
          .signOut(); // Removed skipAccountLimitsDialog argument

      // Add another mounted check immediately before using context after await
      if (mounted) {
        context.go('/profile');
      }
    } else {
      talker.debug(
          'Widget not mounted after successful deletion, skipping snackbar/navigation.');
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

      // Call the helper function for cleanup
      await _handleSuccessfulDeletion();

      // No need for setState or navigation here anymore, handled by helper
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
        talker.debug(
            'Proceeding with account deletion after Google re-authentication');
        // Retry deletion after successful Google re-auth
        try {
          await ref.read(authServiceProvider).deleteUser();
          // Call the helper function for cleanup
          await _handleSuccessfulDeletion();
        } catch (deleteError) {
          // Handle potential errors during the deletion *after* re-auth
          talker.error(
              'Error deleting account after Google re-authentication: $deleteError');
          if (mounted) {
            display_name.showThemedSnackBar(
                context: context,
                message: deleteError is AuthException
                    ? deleteError.message
                    : 'Failed to delete account after re-authentication.',
                isError: true);
          }
          // Ensure loading state is reset even on secondary failure
          if (mounted) {
            setState(() {
              _isLoading = false;
              _showReauthDialog = false; // Close re-auth dialog on error too
            });
          }
        }
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
      // Add mounted check before showing snackbar
      if (mounted) {
        display_name.showThemedSnackBar(
            context: context,
            message: 'Please enter your email and password',
            isError: true,
            duration: const Duration(seconds: 5));
      }
      return;
    }
    // Removed duplicated duration line and moved setState inside try block

    try {
      // Moved setState inside the try block and added mounted check
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      } else {
        // If not mounted, don't proceed with the operation
        talker.debug(
            'Widget not mounted, aborting reauthenticateAndDeleteAccount');
        return;
      }
      await ref.read(authServiceProvider).reauthenticateWithEmailAndPassword(
            _reauthEmailController.text.trim(),
            _reauthPasswordController.text,
          );
      talker.debug(
          'Re-authentication successful, proceeding with account deletion');

      // Retry deletion
      await ref.read(authServiceProvider).deleteUser();

      // Call the helper function for cleanup
      await _handleSuccessfulDeletion();

      // No need for setState or navigation here anymore, handled by helper
    } catch (e) {
      // Ensure mounted check exists before setState
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showReauthDialog = true; // Keep dialog open on error
        });
      }
      talker.error('Error during re-authentication or account deletion: $e');
      // Ensure mounted check exists before showing dialog
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
          final newEmail = _emailController.text.trim(); // Store new email
          // Get the original email BEFORE starting the update process
          final originalEmail = ref.read(firebaseUserProvider).value?.email;

          await ref.read(authServiceProvider).verifyBeforeUpdateEmail(
                newEmail,
              );
          // **NEW:** Update the pending email provider on success
          ref
              .read(emailUpdateNotifierProvider.notifier)
              .setPendingEmail(newEmail);
          // **NEW:** Store the original email for the lifecycle check
          if (originalEmail != null) {
            ref.read(originalEmailForUpdateCheckProvider.notifier).state =
                originalEmail;
            talker.info(
                'Stored original email for lifecycle check (after re-auth): $originalEmail');
          } else {
            talker.warning(
                'Original email was null, cannot store for lifecycle check (after re-auth).');
          }
          // **REMOVED:** Polling start

          setState(() {
            _isLoading = false;
            _showChangeEmail = false;
          });
          if (mounted) {
            await showEmailUpdateInitiatedDialog(context, newEmail);
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
    // Capture contexts before async gap
    final rootContext = ref.read(rootNavigatorKeyProvider).currentContext;
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    Object? error; // Variable to capture potential errors

    try {
      // Call unlink and wait for the provider to complete
      await ref.read(unlinkProviderProvider(providerId).future);
      talker.debug('unlinkProviderProvider future completed for $providerId.');

      // After success, explicitly navigate to stay on the account settings page
      if (mounted) {
        // Removed Navigator.of(context).pushReplacement(...)
      }
    } catch (e) {
      error = e; // Capture the error
      talker.error('Error during unlink provider $providerId: $e');
    } finally {
      // Reset loading state AFTER await completes or fails
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Show SnackBar using root context AFTER state is reset and potential rebuild
    if (mounted && rootContext != null && rootContext.mounted) {
      if (error != null) {
        display_name.showThemedSnackBar(
            context: rootContext, // Use root context
            message: error is AuthException ? error.message : error.toString(),
            isError: true);
      } else {
        // Show success message
        display_name.showThemedSnackBar(
            context: rootContext, // Use root context
            message:
                'Successfully unlinked ${_getProviderDisplayName(providerId)}',
            isError: false);
        // Force rebuild after success to update UI
        if (mounted) {
          setState(() {});
          talker.debug('Forced rebuild via setState after successful unlink.');
        }
      }
    }
  }

  /// Link the current account with Google
  Future<void> _linkWithGoogle() async {
    // Get root context and capture local context before async operations
    final rootContext = ref.read(rootNavigatorKeyProvider).currentContext;
// Capture local context

    // Set loading state
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    Object? error;

    try {
      await ref.read(linkGoogleToEmailPasswordProvider.future);
      // REMOVED explicit invalidation from provider.
      // **NEW:** Reload user data and invalidate provider
      talker.debug('Google link successful, reloading user data...');
      await FirebaseAuth.instance.currentUser?.reload();
      talker.debug('User data reloaded, invalidating authNotifierProvider.');
      ref.invalidate(authNotifierProvider);
      // **NEW:** Add delay and force rebuild
      await Future.delayed(const Duration(milliseconds: 50)); // Small delay
      if (mounted) {
        setState(() {});
        talker.debug('Forced rebuild via delayed setState after Google link.');
      }
    } catch (e) {
      error = e; // Capture error
    } finally {
      // Reset loading state AFTER await completes or fails
      // Important: Do this BEFORE potential invalidation/setState below
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Removed Navigator.of(context).pushReplacement(...)

    // Show SnackBar using root context AFTER state is reset
    // Check State mounted AND rootContext mounted
    if (mounted && rootContext != null && rootContext.mounted) {
      if (error != null) {
        display_name.showThemedSnackBar(
            context: rootContext, // Use root context
            message: error is AuthException ? error.message : error.toString(),
            isError: true);
      } else {
        // Check State mounted AND rootContext mounted before showing success SnackBar
        if (mounted && rootContext.mounted) {
          display_name.showThemedSnackBar(
              context: rootContext, // Use root context
              message: 'Successfully linked with Google',
              isError: false);
          // Force rebuild after success to update UI
          // This might be redundant now due to invalidation, but keep for safety
          // if (mounted) {
          //   setState(() {});
          //   talker.debug(
          //       'Forced rebuild via setState after successful Google link.');
          // }
        }
      }
    }
  }

  /// Link the current account with Email/Password
  Future<void> _linkWithEmailPassword(String email, String password) async {
    // Get root context and capture local context before async operations
    final rootContext = ref.read(rootNavigatorKeyProvider).currentContext;
// Capture local context

    // Set loading state
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    String? successMessage;
    Object? error;

    try {
      final user = ref.read(authNotifierProvider).user;
      final hasGoogleProvider = user?.providerData.any(
            (element) => element.providerId == 'google.com',
          ) ??
          false;

      if (hasGoogleProvider && user != null && !user.isAnonymous) {
        await ref.read(linkEmailPasswordToGoogleProvider(
                EmailPasswordCredentials(email: email, password: password))
            .future);
        successMessage = 'Successfully added Email/Password authentication';
      } else {
        // Assuming this case is for linking to anonymous, which might have different logic
        // For now, keep the original call but adjust message/error handling if needed
        await ref.read(authServiceProvider).linkEmailAndPasswordToAnonymous(
              email,
              password,
            );
        successMessage =
            'Successfully linked Email/Password'; // Adjust if needed
      }
      // Auth state invalidation is handled by the providers themselves

      // **NEW:** Reload user data and invalidate provider
      talker.debug('Email/Password link successful, reloading user data...');
      await FirebaseAuth.instance.currentUser?.reload();
      talker.debug('User data reloaded, invalidating authNotifierProvider.');
      ref.invalidate(authNotifierProvider);
      // **NEW:** Add delay and force rebuild
      await Future.delayed(const Duration(milliseconds: 50)); // Small delay
      if (mounted) {
        setState(() {});
        talker.debug(
            'Forced rebuild via delayed setState after Email/Password link.');
      }
    } catch (e) {
      error = e; // Capture error
    } finally {
      // Reset loading state AFTER await completes or fails
      // Important: Do this BEFORE potential invalidation/setState below
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Removed Navigator.of(context).pushReplacement(...)

    // Show SnackBar using root context AFTER state is reset
    // Check State mounted AND rootContext mounted
    if (mounted && rootContext != null && rootContext.mounted) {
      if (error != null) {
        display_name.showThemedSnackBar(
            context: rootContext, // Use root context
            message: error is AuthException ? error.message : error.toString(),
            isError: true);
      } else if (successMessage != null) {
        // Check State mounted AND rootContext mounted before showing success SnackBar
        if (mounted && rootContext.mounted) {
          display_name.showThemedSnackBar(
              context: rootContext, // Use root context
              message: successMessage,
              isError: false);
          // Force rebuild after success to update UI
          // This might be redundant now due to invalidation, but keep for safety
          // if (mounted) {
          //   setState(() {});
          //   talker.debug(
          //       'Forced rebuild via setState after successful Email/Password link.');
          // }
        }
      }
    }
  }

  /// Show the update password dialog
  void _showUpdatePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Added this line
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
    // Use a fallback text if email is null
    final emailText = user.email ?? 'your email address';
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
            'Please check $emailText and click the verification link. Until verified, your account has the same limitations as a guest account (e.g., 50 unique card collection limit).', // Updated text with fallback
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                // Capture context before async gap
                final capturedContext = context;
                // Resend verification email
                final scaffoldMessenger = ScaffoldMessenger.of(capturedContext);
                SnackBarHelper.showSnackBar(
                  context: capturedContext,
                  message: 'Sending verification email...',
                  duration: const Duration(seconds: 2),
                );

                try {
                  await ref.read(authServiceProvider).sendEmailVerification();
                  // Add mounted check *after* await
                  if (mounted) {
                    scaffoldMessenger.clearSnackBars();
                    // Use the same fallback for the dialog
                    if (!mounted) return; // Check state mounted
                    if (!capturedContext.mounted) {
                      return; // Check captured context mounted
                    }
                    await showVerificationEmailSentDialog(
                        capturedContext,
                        user.email ??
                            'your email address'); // Use captured context
                  }
                } catch (error) {
                  talker.error('Error sending verification email', error);

                  // Add mounted check *after* await
                  if (mounted) {
                    scaffoldMessenger.clearSnackBars();

                    String errorMessage =
                        'Failed to resend verification email. Please try again later.';

                    if (error is FirebaseAuthException) {
                      if (error.code == 'too-many-requests') {
                        errorMessage =
                            'Too many requests. We have temporarily blocked email sending due to unusual activity. Please try again later.';
                      }
                    }

                    // Add mounted check before snackbar
                    if (!mounted) return; // Check state mounted
                    if (!capturedContext.mounted) {
                      return; // Check captured context mounted
                    }
                    SnackBarHelper.showErrorSnackBar(
                      context: capturedContext, // Use captured context
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
    // Watch the email update completion provider and force rebuild on changes
    ref.listen(emailUpdateCompletionProvider, (previous, next) {
      if (mounted) {
        setState(() {
          // Force rebuild to reflect email update changes
          talker.debug('Forcing rebuild after email update completion');
        });
      }
    });

    final authState = ref.watch(authNotifierProvider);
    // **REMOVED:** Watch the base stream provider directly
    // final currentUserAsyncValue = ref.watch(firebaseUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // **NEW:** Watch the immediate verification detection provider
    final verificationDetected = ref.watch(emailVerificationDetectedProvider);
    // **NEW:** Watch the pending email update provider
    final emailUpdateState = ref.watch(emailUpdateNotifierProvider);
    final pendingEmail = emailUpdateState.pendingEmail;

    // Determine the user object to use for the UI
    // **CHANGED:** Rely solely on the user object from AuthNotifier's state
    final userForUI = authState.user;

    // Initialize controllers *inside* build when user data is available
    if (userForUI != null && !_controllersInitialized) {
      _initializeUserDataFromState(userForUI);
    }
    // Handle case where user signs out - reset controllers and flag
    else if (userForUI == null && _controllersInitialized) {
      _displayNameController.clear();
      _emailController.clear();
      _reauthEmailController.clear();
      _controllersInitialized = false;
      talker.debug('User signed out, controllers cleared.');
    }

    // Handle loading state based on the AuthNotifier state
    if (authState.status == AuthStatus.loading) {
      return Scaffold(
        appBar: AppBarFactory.createAppBar(context, 'Account Settings'),
        body: const Center(child: LoadingIndicator()),
      );
    }

    // **REMOVED:** Error handling block that used authState.error

    // Handle data state (user can be null here if signed out)
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
    // ** REVISED LOGIC: Show only if the user has ONLY password provider and it's unverified **
    final bool showVerificationBanner = userForUI != null &&
        userForUI.providerData.length == 1 &&
        userForUI.providerData.first.providerId == 'password' &&
        !userForUI.emailVerified &&
        !verificationDetected;

    // Determine if the AccountInfoCard should show the "Email Not Verified" text/chip
    // ** REVISED LOGIC: Hide chip if verificationDetected is true **
    final bool showUnverifiedChip =
        authState.emailNotVerified && !verificationDetected;
    // ** CORRECTED LOG V2 **
    talker.debug(
        'showUnverifiedChip determined by: authState.emailNotVerified (${authState.emailNotVerified}) && !verificationDetected ($verificationDetected) = $showUnverifiedChip');

    return PopScope(
      canPop: false, // Prevent default pop
      // Use onPopInvokedWithResult instead of the deprecated onPopInvoked
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // If the pop was prevented, handle it manually
        if (!didPop) {
          talker.debug(
              'AccountSettingsPage: PopScope intercepted back gesture, navigating to /profile');
          context.go('/profile');
        }
      },
      child: Scaffold(
        // Use AppBarFactory and provide a custom leading widget for back navigation
        appBar: AppBarFactory.createAppBar(
          context,
          'Account Settings',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              talker.debug(
                  'AccountSettingsPage: AppBar back button pressed, navigating to /profile');
              context.go('/profile');
            },
          ),
        ),
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
                    // --- Conditionally show Verification Banner ---
                    // Use the updated showVerificationBanner logic
                    if (showVerificationBanner) // Added null check for safety
                      _buildVerificationBanner(context, colorScheme,
                          userForUI), // Removed unnecessary null assertion
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
                      // **REMOVED:** user parameter
                      // Use the revised logic for showing the unverified state chip
                      isEmailNotVerified: showUnverifiedChip,
                      // **NEW:** Pass pending email
                      pendingEmail: pendingEmail,
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
            content: Text(
              message,
              style: TextStyle(color: colorScheme.onSurface),
            ),
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
    BuildContext context, String newEmail,
    [String? customMessage]) async {
  final colorScheme = Theme.of(context).colorScheme;
  final message = customMessage ??
      'A verification email has been sent to $newEmail. Please check your inbox and click the link to finalize the email change.';

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
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onSurface),
        ),
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

// Helper function to show verification email sent dialog
Future<void> showVerificationEmailSentDialog(
    BuildContext context, String email) async {
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
            const Text('Verification Email Sent'),
          ],
        ),
        content: Text(
          'A verification email has been sent to $email. Please check your inbox and click the link to finalize the email verification. Until verified, your account has the same limitations as a guest account.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
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
