import 'package:flutter/material.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';

/// A styled button that matches the app's design language
/// This button has a consistent style with the Google Sign-In button
class StyledButton extends StatelessWidget {
  /// The callback when the button is pressed
  final VoidCallback onPressed;

  /// The text to display on the button
  final String text;

  /// The background color of the button (defaults to primary color)
  final Color? backgroundColor;

  /// The text color of the button (defaults to on-primary color)
  final Color? textColor;

  /// Whether to use an outlined style instead of filled
  final bool outlined;

  /// Creates a styled button
  const StyledButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get the contrast extension
    final contrast = theme.extension<ContrastExtension>();

    // Use the provided colors or default to theme colors with guaranteed contrast
    final bgColor = backgroundColor ??
        (contrast?.primaryWithContrast ?? theme.colorScheme.primary);
    final txtColor = textColor ??
        (contrast?.onPrimaryWithContrast ?? theme.colorScheme.onPrimary);

    return Center(
      child: SizedBox(
        width: 280, // Fixed width to match Google button
        height: 48, // Standard height for buttons
        child: outlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: bgColor),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(24), // Pill-shaped button
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: bgColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bgColor,
                  foregroundColor: txtColor,
                  elevation: 1, // Slight elevation for depth
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(24), // Pill-shaped button
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ),
    );
  }
}
