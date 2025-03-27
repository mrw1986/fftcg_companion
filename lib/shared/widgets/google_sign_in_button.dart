import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// A button that follows Google's branding guidelines for Sign-In buttons
/// See: https://developers.google.com/identity/branding-guidelines
class GoogleSignInButton extends StatelessWidget {
  /// The callback when the button is pressed
  final Future<void> Function() onPressed;

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
  final Future<void> Function() onPressed;
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

    // Use the specified Google logo assets
    final String logoAssetPath = isDark
        ? 'assets/images/google_branding/signin-assets/android_dark_rd_na.svg'
        : 'assets/images/google_branding/signin-assets/android_neutral_rd_na.svg';

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
                await widget.onPressed();
              } catch (e) {
                talker.error('Error in Google Sign-In button: $e');
                setState(() {
                  _errorMessage = 'Failed to sign in with Google';
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
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      logoAssetPath,
                      height: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
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
