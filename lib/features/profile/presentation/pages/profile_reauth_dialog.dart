import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class ProfileReauthDialog extends ConsumerStatefulWidget {
  const ProfileReauthDialog({
    super.key,
    required this.reauthEmailController,
    required this.reauthPasswordController,
    required this.showReauthPassword,
    required this.isAccountDeletion,
    required this.isLoading,
    required this.onTogglePasswordVisibility,
    required this.onCancel,
    required this.onAuthenticate,
    required this.onGoogleAuthenticate,
  });

  final TextEditingController reauthEmailController;
  final TextEditingController reauthPasswordController;
  final bool showReauthPassword;
  final bool isAccountDeletion;
  final bool isLoading;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onCancel;
  final VoidCallback onAuthenticate;
  final Future<void> Function() onGoogleAuthenticate;

  @override
  ConsumerState<ProfileReauthDialog> createState() =>
      _ProfileReauthDialogState();
}

class _ProfileReauthDialogState extends ConsumerState<ProfileReauthDialog> {
  List<String> _providers = [];
  bool _isLoadingProviders = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _isLoadingProviders = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final providerData = user.providerData;
        _providers =
            providerData.map((userInfo) => userInfo.providerId).toList();

        // Log the providers for debugging
        talker.debug('Available auth providers: $_providers');
      }
    } catch (e) {
      talker.error('Error loading providers: $e');
      // If there's an error, default to showing all options
      _providers = ['password', 'google.com'];
    } finally {
      // Ensure setState runs even if the widget is disposed during the async gap
      if (mounted) {
        setState(() {
          _isLoadingProviders = false;
        });
      }
    }
  }

  bool get _hasGoogleProvider => _providers.contains('google.com');
  bool get _hasPasswordProvider => _providers.contains('password');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
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
                Text(
                  'For security reasons, please re-authenticate ${widget.isAccountDeletion ? 'before deleting your account' : 'to continue'}.',
                ),
                const SizedBox(height: 16),
                if (_isLoadingProviders)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  // Show Google Sign-In button if the user has a Google provider
                  if (_hasGoogleProvider) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GoogleSignInButton(
                        onPressed: widget.isLoading
                            ? null
                            : widget.onGoogleAuthenticate,
                        onError: (e) {
                          SnackBarHelper.showErrorSnackBar(
                            context: context,
                            message:
                                'Error authenticating with Google: ${e.toString()}',
                          );
                        },
                        text: 'Continue with Google',
                      ),
                    ),
                    if (_hasPasswordProvider)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Divider(),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // Show Email/Password fields if the user has a password provider
                  if (_hasPasswordProvider) ...[
                    TextField(
                      controller: widget.reauthEmailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !widget.isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.reauthPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            widget.showReauthPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: widget.onTogglePasswordVisibility,
                          tooltip: widget.showReauthPassword
                              ? 'Hide password'
                              : 'Show password',
                        ),
                      ),
                      obscureText: !widget.showReauthPassword,
                      enabled: !widget.isLoading,
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.isLoading ? null : widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    if (_hasPasswordProvider)
                      FilledButton(
                        onPressed:
                            widget.isLoading ? null : widget.onAuthenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                        child: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Authenticate'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
