import 'package:flutter/material.dart';

/// Factory class for creating consistently styled AppBars throughout the app
class AppBarFactory {
  /// Creates a default AppBar using the app's theme
  static AppBar createAppBar(
    BuildContext context,
    String title, {
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    Widget? leading, // Added leading parameter
  }) {
    // Get the color scheme from the current theme
    final colorScheme = Theme.of(context).colorScheme;

    // Use the theme color for the AppBar
    return AppBar(
      title: Text(title),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading, // Pass leading widget
      bottom: bottom,
      elevation: 1,
    );
  }

  /// Creates an AppBar with a custom background color
  /// Useful for pages like Theme Settings where the AppBar color changes dynamically
  static AppBar createColoredAppBar(
    BuildContext context,
    String title,
    Color backgroundColor, {
    List<Widget>? actions,
    bool automaticallyImplyLeading = true,
    PreferredSizeWidget? bottom,
    Widget? leading, // Added leading parameter
  }) {
    final textColor = _getTextColorForBackground(backgroundColor);
    return AppBar(
      title: Text(title),
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
      iconTheme: IconThemeData(color: textColor),
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading, // Pass leading widget
      bottom: bottom,
      elevation: 1,
    );
  }

  /// Helper method to determine appropriate text color based on background color
  static Color _getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
