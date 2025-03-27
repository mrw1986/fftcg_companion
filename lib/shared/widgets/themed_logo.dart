import 'package:flutter/material.dart';

/// A widget that displays the app logo with appropriate theming
/// In dark mode, it shows the white logo
/// In light mode, it applies a color filter to make the logo visible
class ThemedLogo extends StatelessWidget {
  /// The height of the logo
  final double height;

  /// Creates a themed logo widget
  const ThemedLogo({
    super.key,
    this.height = 500, // Increased from 150 to make logo larger
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Create the image widget based on the theme
    Widget logoImage = isDark
        // In dark mode, use the logo as is (white logo on dark background)
        ? Image.asset(
            'assets/images/logo_transparent.png',
            height: height,
            fit: BoxFit.contain, // Ensure proper scaling
          )
        // In light mode, apply a color filter to make the logo black
        : ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              -1, 0, 0, 0, 255, // Red channel inverted
              0, -1, 0, 0, 255, // Green channel inverted
              0, 0, -1, 0, 255, // Blue channel inverted
              0, 0, 0, 1, 0, // Alpha channel unchanged
            ]),
            child: Image.asset(
              'assets/images/logo_transparent.png',
              height: height,
              fit: BoxFit.contain, // Ensure proper scaling
            ),
          );

    // Wrap in a container with explicit constraints to ensure the size is applied
    return Container(
      constraints: BoxConstraints(
        maxHeight: height,
        minHeight: height,
      ),
      child: logoImage,
    );
  }
}
