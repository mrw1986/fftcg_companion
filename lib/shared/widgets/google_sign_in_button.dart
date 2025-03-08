import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';

/// A button that follows Google's branding guidelines for Sign-In buttons
/// See: https://developers.google.com/identity/branding-guidelines
class GoogleSignInButton extends StatelessWidget {
  /// The callback when the button is pressed
  final VoidCallback onPressed;

  /// The text to display on the button
  final String text;

  /// Creates a Google Sign-In button
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Sign in with Google',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;
    theme.extension<ContrastExtension>();

    // Use SVG files for better scaling and quality - dark for dark mode, neutral for light mode
    final String assetPath = isDark
        ? 'assets/images/google_branding/signin-assets/android_dark_rd_ctn.svg'
        : 'assets/images/google_branding/signin-assets/android_neutral_rd_ctn.svg';

    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: SvgPicture.asset(
          assetPath,
          width: 240, // Fixed width to match our UI
          height: 48, // Standard height for buttons
        ),
      ),
    );
  }
}
