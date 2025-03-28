import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// A button that follows Google's branding guidelines for Sign-In buttons
/// See: https://developers.google.com/identity/branding-guidelines
class GoogleSignInButton extends StatelessWidget {
  /// The callback when the button is pressed
  final Future<void> Function()? onPressed;

  /// The text to display on the button
  final String text;

  /// Optional error handler
  final Function(Exception)? onError;

  /// Creates a Google Sign-In button
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Sign in with Google',
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return _GoogleSignInButtonState(
      onPressed: onPressed,
      text: text,
      onError: onError,
    );
  }
}

class _GoogleSignInButtonState extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final String text;
  final Function(Exception)? onError;

  const _GoogleSignInButtonState({
    required this.onPressed,
    required this.text,
    this.onError,
  });

  @override
  State<_GoogleSignInButtonState> createState() =>
      _GoogleSignInButtonStateState();
}

class _GoogleSignInButtonStateState extends State<_GoogleSignInButtonState> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use the specified Google logo assets (contained version)
    final String logoAssetPath = isDark
        ? 'assets/images/google_branding/signin-assets/android_dark_rd_ctn.svg'
        : 'assets/images/google_branding/signin-assets/android_neutral_rd_ctn.svg';

    if (_isLoading) {
      return Center(
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color:
                isDark ? colorScheme.surfaceContainerHighest : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              if (_isLoading) return;

              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });

              try {
                talker.debug('Google Sign-In button pressed');
                if (widget.onPressed != null) {
                  await widget.onPressed!();
                }
              } catch (e) {
                talker.error('Error in Google Sign-In button: $e');

                // Handle specific error cases
                String errorMessage = 'Failed to sign in with Google';

                if (e is FirebaseAuthException) {
                  if (e.code == 'requires-recent-login') {
                    errorMessage =
                        'Please sign out and sign in again to continue';
                  } else if (e.code == 'wrong-account') {
                    errorMessage =
                        'Please use the same Google account you originally signed in with';
                  } else if (e.code == 'user-token-expired') {
                    errorMessage =
                        'Your session has expired. Please sign in again';
                  } else if (e.message?.contains('BAD_REQUEST') == true) {
                    errorMessage = 'Authentication error. Please try again';
                  }
                }

                setState(() {
                  _errorMessage = errorMessage;
                  if (e is Exception && widget.onError != null) {
                    widget.onError!(e);
                  }
                });
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: SvgPicture.asset(
              logoAssetPath,
              height: 48, // Increased size for better visibility
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
