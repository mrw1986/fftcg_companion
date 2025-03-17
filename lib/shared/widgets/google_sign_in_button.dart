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
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    // Use SVG files for better scaling and quality - dark for dark mode, neutral for light mode
    final String assetPath = isDark
        ? 'assets/images/google_branding/signin-assets/android_dark_rd_ctn.svg'
        : 'assets/images/google_branding/signin-assets/android_neutral_rd_ctn.svg';

    if (_isLoading) {
      return Center(
        child: Container(
          width: 240,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: GestureDetector(
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
            child: SvgPicture.asset(
              assetPath,
              width: 240, // Fixed width to match our UI
              height: 48, // Standard height for buttons
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
