import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// A button that follows Google's branding guidelines for Sign-In buttons
/// See: https://developers.google.com/identity/branding-guidelines
class GoogleSignInButton extends StatelessWidget {
  /// The callback when the button is pressed
  final Future<void> Function()? onPressed;

  /// The text to display on the button (not used with SVG logos)
  final String text;

  /// Optional error handler (less critical now, handled in parent)
  final Function(Exception)? onError;

  /// Flag to indicate if the parent process is loading
  final bool isLoading;

  /// Creates a Google Sign-In button
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue with Google', // Keep for potential future use
    this.onError,
    this.isLoading = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use the specified Google logo assets (contained version)
    final String logoAssetPath = isDark
        ? 'assets/images/google_branding/signin-assets/android_dark_rd_ctn.svg'
        : 'assets/images/google_branding/signin-assets/android_neutral_rd_ctn.svg';

    // Show loading indicator if isLoading is true
    if (isLoading) {
      return Center(
        child: Container(
          width: double.infinity, // Match button width
          height: 48, // Match button height
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

    // Show the actual button if not loading
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Disable onTap if already loading (handled by parent now) or no onPressed provided
        onTap: (isLoading || onPressed == null)
            ? null
            : () async {
                try {
                  talker.debug('Google Sign-In button tapped');
                  await onPressed!();
                } catch (e) {
                  talker.error('Error caught in GoogleSignInButton onTap: $e');
                  // Propagate error via onError callback if provided
                  if (e is Exception && onError != null) {
                    onError!(e);
                  }
                  // No internal state update needed here
                }
                // No finally block needed to set loading state
              },
        borderRadius: BorderRadius.circular(8),
        child: SvgPicture.asset(
          logoAssetPath,
          height: 48, // Consistent height
        ),
      ),
    );
  }
}
