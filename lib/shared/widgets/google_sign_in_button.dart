import 'package:flutter/material.dart';

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
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Choose the appropriate asset based on the theme
    final String assetPath = isDark
        ? 'assets/images/google_branding/signin-assets/signin-assets/Android/png@2x/dark/android_dark_rd_SI@2x.png'
        : 'assets/images/google_branding/signin-assets/signin-assets/Android/png@2x/light/android_light_rd_SI@2x.png';

    return Semantics(
      button: true,
      label: text,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 48, // Standard height for buttons
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}
