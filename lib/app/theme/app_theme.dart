import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';

/// Provides theme data for the application
class AppTheme {
  static final _visualDensity = FlexColorScheme.comfortablePlatformDensity;

  /// Default light theme
  static ThemeData get light {
    return FlexThemeData.light(
      scheme: FlexScheme.deepPurple,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        // Ensure buttons have good contrast
        textButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSchemeColor: SchemeColor.primary,
        outlinedButtonSchemeColor: SchemeColor.primary,
        toggleButtonsSchemeColor: SchemeColor.primary,
        inputDecoratorSchemeColor: SchemeColor.primary,
        fabSchemeColor: SchemeColor.primary,
      ),
      keyColors: FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      tones: FlexTones.material(Brightness.light),
      visualDensity: _visualDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );
  }

  /// Default dark theme
  static ThemeData get dark {
    return FlexThemeData.dark(
      scheme: FlexScheme.deepPurple,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        // Ensure buttons have good contrast
        textButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSchemeColor: SchemeColor.primary,
        outlinedButtonSchemeColor: SchemeColor.primary,
        toggleButtonsSchemeColor: SchemeColor.primary,
        inputDecoratorSchemeColor: SchemeColor.primary,
        fabSchemeColor: SchemeColor.primary,
      ),
      keyColors: FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      tones: FlexTones.material(Brightness.dark),
      visualDensity: _visualDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );
  }

  /// Light theme with custom primary color
  static ThemeData lightCustomColor(Color color) {
    // Create a FlexSchemeColor from the primary color
    final schemeColor = _createSchemeColor(color, Brightness.light);

    // Create the base theme
    final baseTheme = FlexThemeData.light(
      colors: schemeColor,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        textButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSchemeColor: SchemeColor.primary,
        outlinedButtonSchemeColor: SchemeColor.primary,
        toggleButtonsSchemeColor: SchemeColor.primary,
        inputDecoratorSchemeColor: SchemeColor.primary,
        fabSchemeColor: SchemeColor.primary,
      ),
      keyColors: FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      tones: FlexTones.material(Brightness.light),
      visualDensity: _visualDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );

    // Get the updated color scheme from the base theme
    final updatedColorScheme = baseTheme.colorScheme;

    // Create a contrast extension
    final contrastExtension =
        ContrastExtension.fromColorScheme(updatedColorScheme);

    // Return the theme with the contrast extension
    return baseTheme.copyWith(
      // Ensure text has good contrast
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: contrastExtension.onBackgroundWithContrast,
        displayColor: contrastExtension.onBackgroundWithContrast,
      ),
      extensions: [contrastExtension],
    );
  }

  /// Dark theme with custom primary color
  static ThemeData darkCustomColor(Color color) {
    // Create a FlexSchemeColor from the primary color
    final schemeColor = _createSchemeColor(color, Brightness.dark);

    // Create the base theme
    final baseTheme = FlexThemeData.dark(
      colors: schemeColor,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        textButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSchemeColor: SchemeColor.primary,
        outlinedButtonSchemeColor: SchemeColor.primary,
        toggleButtonsSchemeColor: SchemeColor.primary,
        inputDecoratorSchemeColor: SchemeColor.primary,
        fabSchemeColor: SchemeColor.primary,
      ),
      keyColors: FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      tones: FlexTones.material(Brightness.dark),
      visualDensity: _visualDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );

    // Get the updated color scheme from the base theme
    final updatedColorScheme = baseTheme.colorScheme;

    // Create a contrast extension
    final contrastExtension =
        ContrastExtension.fromColorScheme(updatedColorScheme);

    // Return the theme with the contrast extension
    return baseTheme.copyWith(
      // Ensure text has good contrast
      textTheme: GoogleFonts.robotoTextTheme().apply(
        bodyColor: contrastExtension.onBackgroundWithContrast,
        displayColor: contrastExtension.onBackgroundWithContrast,
      ),
      extensions: [contrastExtension],
    );
  }

  /// Creates a FlexSchemeColor from a primary color
  static FlexSchemeColor _createSchemeColor(
      Color color, Brightness brightness) {
    // Ensure the color has appropriate contrast for the given brightness
    Color safeColor = color;
    final luminance = color.computeLuminance();

    if (brightness == Brightness.light && luminance > 0.9) {
      // If too light in light mode, adjust to a safer color
      safeColor = HSLColor.fromColor(color)
          .withLightness(0.7) // Reduce lightness to ensure readability
          .toColor();
    } else if (brightness == Brightness.dark && luminance < 0.1) {
      // If too dark in dark mode, adjust to a safer color
      safeColor = HSLColor.fromColor(color)
          .withLightness(0.3) // Increase lightness to ensure readability
          .toColor();
    }

    // Generate a complete scheme from the primary color
    return FlexSchemeColor.from(
      primary: safeColor,
      brightness: brightness,
    );
  }
}
