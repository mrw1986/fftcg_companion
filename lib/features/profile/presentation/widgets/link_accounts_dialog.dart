import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter

/// Dialog for linking accounts when a Google account's email is already in use
class LinkAccountsDialog extends ConsumerStatefulWidget {
  final String email;
  final Function(bool success) onComplete;

  const LinkAccountsDialog({
    super.key,
    required this.email,
    required this.onComplete,
  });

  @override
  ConsumerState<LinkAccountsDialog> createState() => _LinkAccountsDialogState();
}

class _LinkAccountsDialogState extends ConsumerState<LinkAccountsDialog> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _linkAccounts() async {
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      talker.debug('Attempting to link accounts with email/password');

      // First sign in with email/password
      final authService = ref.read(authServiceProvider);

      // Sign out of the anonymous account (if any, though this dialog is usually shown after a failed Google sign-in attempt, implying the user might not be anonymous anymore)
      // Let's ensure we are signed out before signing in with email/pass
      await authService.signOut();

      // Sign in with email/password
      await authService.signInWithEmailAndPassword(
        widget.email,
        _passwordController.text,
      );

      talker.debug('Successfully signed in with email/password');

      // Now try to link with Google
      try {
        // Corrected method call
        await authService.linkGoogleToEmailPassword();
        talker.debug('Successfully linked with Google');

        if (mounted) {
          context.pop(); // Use context.pop()
          widget.onComplete(true);
        }
      } catch (linkError) {
        talker
            .error('Error linking with Google after email sign-in: $linkError');

        if (mounted) {
          setState(() {
            _isLoading = false;
            if (linkError is FirebaseAuthException) {
              _errorMessage = authService.getReadableAuthError(
                  linkError.code, linkError.message);
            } else {
              _errorMessage =
                  'Failed to link with Google. Please try again later.';
            }
          });
          // Don't pop the dialog on failure, let the user see the error
          // widget.onComplete(false); // Let the user decide to cancel
        }
      }
    } catch (e) {
      talker.error('Error signing in with email/password: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (e is FirebaseAuthException) {
            final authService = ref.read(authServiceProvider);
            _errorMessage = authService.getReadableAuthError(e.code, e.message);
            // Specific messages for sign-in failure
            if (e.code == 'wrong-password') {
              _errorMessage = 'Incorrect password. Please try again.';
            } else if (e.code == 'user-not-found') {
              // This shouldn't happen if the dialog logic is correct, but handle it
              _errorMessage = 'No account found with this email.';
            }
          } else {
            _errorMessage =
                'An error occurred during sign-in. Please try again.';
          }
        });
        // Don't pop the dialog on failure
        // widget.onComplete(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        'Link Your Accounts',
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An account already exists with the email ${widget.email}. Enter your password to link your Google account with your existing account.',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.primary,
                  ),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                ),
              ),
              obscureText: !_showPassword,
              onSubmitted: (_) => _linkAccounts(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  context.pop(); // Use context.pop()
                  widget.onComplete(false); // Indicate cancellation/failure
                },
          child: const Text('Cancel'),
        ),
        _isLoading
            ? Container(
                margin: const EdgeInsets.only(right: 16),
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            : TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                onPressed: _linkAccounts,
                child: const Text('Link Accounts'),
              ),
      ],
    );
  }
}
