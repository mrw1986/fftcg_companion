import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _showChangeEmail = false;
  bool _showDeleteConfirmation = false;
  bool _showReauthDialog = false;
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
            user.email!; // Pre-fill the email for re-authentication
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

      // Show success message as SnackBar with action button
      if (mounted) {
        showThemedSnackBar(
            context: context,
            message: 'Profile updated successfully',
            isError: false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message as SnackBar with action button
      if (mounted) {
        showThemedSnackBar(
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
      showThemedSnackBar(
          context: context,
          message: 'Please enter a valid email address',
          isError: true);
      return;
    }

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

      // Show success message as SnackBar with action button
      if (mounted) {
        showThemedSnackBar(
            context: context,
            message:
                'Verification email sent. Please check your email to complete the process.',
            isError: false,
            duration: const Duration(seconds: 10));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Check if the error is related to requiring recent authentication
      if (e.toString().contains('requires-recent-login') ||
          e.toString().contains('recent authentication')) {
        // Show re-authentication dialog for security-sensitive operations
        setState(() {
          _showReauthDialog = true;
        });
      } else {
        // Show error message as SnackBar with action button
        if (mounted) {
          showThemedSnackBar(
              context: context,
              message: e is FirebaseAuthException
                  ? ref.read(authServiceProvider).getReadableAuthError(e)
                  : e.toString(),
              isError: true);
        }
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message as SnackBar with action button
      if (mounted) {
        showThemedSnackBar(
            context: context,
            message: 'Error signing out: ${e.toString()}',
            isError: true);
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await ref.read(authServiceProvider).deleteUser();

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Navigate back to profile page after successful deletion
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Check for requires-recent-login error
      if (e.toString().contains('requires-recent-login') ||
          e.toString().contains('recent authentication')) {
        talker.debug('Account deletion requires re-authentication');

        // Show re-authentication dialog
        setState(() {
          _showReauthDialog = true;
        });
      } else {
        // Show error message
        if (mounted) {
          showThemedSnackBar(
              context: context,
              message: e is FirebaseAuthException
                  ? ref.read(authServiceProvider).getReadableAuthError(e)
                  : e.toString(),
              isError: true);
        }
      }
    }
  }

  Future<void> _reauthenticateAndDeleteAccount() async {
    if (_reauthEmailController.text.isEmpty ||
        _reauthPasswordController.text.isEmpty) {
      showThemedSnackBar(
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

      // Now try to delete the account again
      await ref.read(authServiceProvider).deleteUser();

      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });

      if (mounted) {
        // Navigate back to profile page after successful deletion
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        showThemedSnackBar(
            context: context,
            message: e is FirebaseAuthException
                ? ref.read(authServiceProvider).getReadableAuthError(e)
                : e.toString(),
            isError: true);
      }
    }
  }

  Future<void> _reauthenticateAndContinue() async {
    if (_reauthEmailController.text.isEmpty ||
        _reauthPasswordController.text.isEmpty) {
      showThemedSnackBar(
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

      setState(() {
        _isLoading = false;
        _showReauthDialog = false;
      });

      // Show success message
      if (mounted) {
        showThemedSnackBar(
            context: context,
            message:
                'Authentication successful. You can now continue with your action.',
            isError: false);
      }

      // If we were trying to delete the account, show the confirmation dialog again
      if (_showDeleteConfirmation) {
        setState(() {
          _showDeleteConfirmation = true;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (mounted) {
        showThemedSnackBar(
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
        showThemedSnackBar(
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
        showThemedSnackBar(
            context: context,
            message: e is FirebaseAuthException
                ? ref.read(authServiceProvider).getReadableAuthError(e)
                : e.toString(),
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
        ),
        body: const Center(
          child: Text('You need to be logged in to view this page.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _showReauthDialog
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Re-authenticate',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'For security reasons, please re-enter your credentials to continue.',
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _reauthEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _reauthPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showReauthPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () => setState(() =>
                                      _showReauthPassword =
                                          !_showReauthPassword),
                                  tooltip: _showReauthPassword
                                      ? 'Hide password'
                                      : 'Show password',
                                ),
                              ),
                              obscureText: !_showReauthPassword,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _showReauthDialog = false),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: _showDeleteConfirmation
                                      ? _reauthenticateAndDeleteAccount
                                      : _reauthenticateAndContinue,
                                  child: const Text('Authenticate'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                  title: const Text('Email'),
                                  subtitle: Text(user.email ?? 'No email'),
                                  leading: const Icon(Icons.email_outlined),
                                  trailing: user.providerData.any((element) =>
                                          element.providerId == 'password')
                                      ? TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showChangeEmail =
                                                  !_showChangeEmail;
                                            });
                                          },
                                          child: Text(_showChangeEmail
                                              ? 'Cancel'
                                              : 'Change'),
                                        )
                                      : null,
                                ),
                                if (_showChangeEmail) ...[
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      labelText: 'New Email',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _updateEmail,
                                    child: const Text('Update Email'),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Note: You will receive a verification email to confirm this change.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                ListTile(
                                  title: const Text('Account Type'),
                                  subtitle: Text(_getProviderName(user)),
                                  leading:
                                      const Icon(Icons.account_circle_outlined),
                                ),
                                if (user.isAnonymous)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Anonymous Account',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Your data is only stored on this device. To save your data across devices, upgrade to a permanent account.',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ElevatedButton(
                                                onPressed: () => context
                                                    .go('/profile/register'),
                                                child: const Text(
                                                    'Upgrade to Full Account'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Add Google Sign-In button here for anonymous users
                        if (user.isAnonymous)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: GoogleSignInButton(
                              onPressed: () async {
                                context.go('/profile/login');
                              },
                              text: 'Continue with Google',
                            ),
                          ),

                        if (!user.isAnonymous)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Profile Settings',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _displayNameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Display Name',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _updateProfile,
                                    child: const Text('Update Profile'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!user.isAnonymous && user.providerData.length > 1)
                          Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Linked Providers',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'You can unlink authentication providers from your account. You must keep at least one provider linked.',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...user.providerData.map((provider) {
                                    return ListTile(
                                      title: Text(_getProviderDisplayName(
                                          provider.providerId)),
                                      subtitle:
                                          Text(provider.email ?? 'No email'),
                                      leading: Icon(_getProviderIcon(
                                          provider.providerId)),
                                      trailing: user.providerData.length > 1
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
                              ),
                            ),
                          ),
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                const SizedBox(height: 16),
                                if (!user.isAnonymous &&
                                    user.providerData.any((element) =>
                                        element.providerId == 'password'))
                                  ListTile(
                                    title: const Text('Reset Password'),
                                    subtitle: const Text(
                                        'Send a password reset email to your account'),
                                    leading:
                                        const Icon(Icons.lock_reset_outlined),
                                    onTap: () =>
                                        context.go('/profile/reset-password'),
                                  ),
                                ListTile(
                                  title: const Text('Sign Out'),
                                  subtitle: const Text(
                                      'Sign out of your current account'),
                                  leading: const Icon(Icons.logout_outlined),
                                  onTap: _signOut,
                                ),
                                if (!user.isAnonymous) ...[
                                  const Divider(),
                                  ListTile(
                                    title: const Text('Delete Account'),
                                    subtitle: const Text(
                                        'Permanently delete your account and all associated data'),
                                    leading: const Icon(
                                        Icons.delete_forever_outlined,
                                        color: Colors.red),
                                    onTap: () {
                                      setState(() {
                                        _showDeleteConfirmation = true;
                                      });
                                    },
                                  ),
                                  if (_showDeleteConfirmation) ...[
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Warning: This action cannot be undone. All your data will be permanently deleted.',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => setState(() =>
                                              _showDeleteConfirmation = false),
                                          child: const Text('Cancel'),
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton(
                                          onPressed: _deleteAccount,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Delete Account'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _getProviderName(User user) {
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
}
