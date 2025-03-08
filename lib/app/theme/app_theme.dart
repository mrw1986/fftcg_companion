import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';

class AppTheme {
  static final _visualDensity = VisualDensity.adaptivePlatformDensity;

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
      ),
      visualDensity: _visualDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );
  }

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
      ),
      visualDensity: _visualDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.roboto().fontFamily,
    );
  }

  static ThemeData lightCustomColor(Color color) {
    // Ensure the color has appropriate contrast for light mode
    final luminance = color.computeLuminance();
    final safeColor = luminance > 0.9
        ? HSLColor.fromColor(color).withLightness(0.7).toColor()
        : color;

    // Create a color scheme with appropriate contrast

    // Create the base theme
    final baseTheme = FlexThemeData.light(
      colors: FlexSchemeColor.from(primary: safeColor),
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
      tones: FlexTones.jolly(Brightness.light),
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

  static ThemeData darkCustomColor(Color color) {
    // Ensure the color has appropriate contrast for dark mode
    final luminance = color.computeLuminance();
    final safeColor = luminance < 0.1
        ? HSLColor.fromColor(color).withLightness(0.3).toColor()
        : color;

    // Create a color scheme with appropriate contrast

    // Create the base theme
    final baseTheme = FlexThemeData.dark(
      colors: FlexSchemeColor.from(primary: safeColor),
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
      tones: FlexTones.jolly(Brightness.dark),
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
}
