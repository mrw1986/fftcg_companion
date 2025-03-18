import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provides theme data for the application
class AppTheme {
  /// Default light theme
  static ThemeData get light {
    // Default primary color - Material You Purple
    const primaryColor = Color(0xFF6750A4);

    // Create a color scheme using the default primary color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    );

    // Create and return the theme data
    return _createThemeData(colorScheme);
  }

  /// Default dark theme
  static ThemeData get dark {
    // Default primary color - Material You Purple
    const primaryColor = Color(0xFF6750A4);

    // Create a color scheme using the default primary color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    );

    // Create and return the theme data
    return _createThemeData(colorScheme);
  }

  /// Light theme with custom primary color
  static ThemeData lightCustomColor(Color color) {
    // Create a color scheme using the provided color
    final colorScheme = ColorScheme.light(
      primary: color,
      onPrimary: _getTextColorForBackground(color),
      primaryContainer: color.withAlpha(204), // 0.8 * 255 = 204
      onPrimaryContainer: _getTextColorForBackground(color.withAlpha(204)),
      secondary: color,
      onSecondary: _getTextColorForBackground(color),
      secondaryContainer: color.withAlpha(204), // 0.8 * 255 = 204
      onSecondaryContainer: _getTextColorForBackground(color.withAlpha(204)),
      brightness: Brightness.light,
    );

    // Create and return the theme data
    return _createThemeData(colorScheme);
  }

  /// Dark theme with custom primary color
  static ThemeData darkCustomColor(Color color) {
    // Create a color scheme using the provided color
    final colorScheme = ColorScheme.dark(
      primary: color,
      onPrimary: _getTextColorForBackground(color),
      primaryContainer: color.withAlpha(204), // 0.8 * 255 = 204
      onPrimaryContainer: _getTextColorForBackground(color.withAlpha(204)),
      secondary: color,
      onSecondary: _getTextColorForBackground(color),
      secondaryContainer: color.withAlpha(204), // 0.8 * 255 = 204
      onSecondaryContainer: _getTextColorForBackground(color.withAlpha(204)),
      brightness: Brightness.dark,
    );

    // Create and return the theme data
    return _createThemeData(colorScheme);
  }

  /// Creates a ThemeData from a ColorScheme
  static ThemeData _createThemeData(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      primaryColor: colorScheme.primary, // Ensure primary color is set
      useMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 1,
        color: colorScheme.surface, // Ensure card color is set
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.primary,
        indicatorColor: colorScheme.onPrimary.withAlpha(51), // 0.2 * 255 = 51
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimary);
          }
          return IconThemeData(
              color: colorScheme.onPrimary.withAlpha(179)); // 0.7 * 255 = 179
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(color: colorScheme.onPrimary);
          }
          return TextStyle(
              color: colorScheme.onPrimary.withAlpha(179)); // 0.7 * 255 = 179
        }),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Pill-shaped button
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
        actionsPadding: const EdgeInsets.all(16),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        actionTextColor: colorScheme.primary,
      ),

      // Popup menu theme
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: TextStyle(color: colorScheme.onSurface),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        modalBackgroundColor: colorScheme.surface,
        modalElevation: 4,
        modalBarrierColor: Colors.black.withAlpha(153), // 0.6 * 255 = 153
      ),

      // Tooltip theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(color: colorScheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}

/// Helper method to determine text color based on background color
Color _getTextColorForBackground(Color backgroundColor) {
  // Calculate the luminance of the background color
  final luminance = backgroundColor.computeLuminance();

  // Use white text on dark backgrounds, black text on light backgrounds
  return luminance > 0.5 ? Colors.black : Colors.white;
}
