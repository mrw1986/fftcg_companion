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
    final colorScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: Brightness.light,
    );

    // Create and return the theme data
    return _createThemeData(colorScheme);
  }

  /// Dark theme with custom primary color
  static ThemeData darkCustomColor(Color color) {
    // Create a color scheme using the provided color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: color,
      brightness: Brightness.dark,
    );

    // Create and return the theme data
    return _createThemeData(colorScheme);
  }

  /// Creates a ThemeData from a ColorScheme
  static ThemeData _createThemeData(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
    );
  }
}
