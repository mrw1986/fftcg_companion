import 'package:flutter/material.dart';

/// Extension to ensure text has sufficient contrast against its background
class ContrastExtension extends ThemeExtension<ContrastExtension> {
  /// Text color that ensures readability on primary color backgrounds
  final Color onPrimaryWithContrast;

  /// Text color that ensures readability on surface color backgrounds
  final Color onSurfaceWithContrast;

  /// Text color that ensures readability on background color
  final Color onBackgroundWithContrast;

  /// Primary color with guaranteed contrast against surface
  final Color primaryWithContrast;

  ContrastExtension({
    required this.onPrimaryWithContrast,
    required this.onSurfaceWithContrast,
    required this.onBackgroundWithContrast,
    required this.primaryWithContrast,
  });

  /// Create a contrast extension from a color scheme
  factory ContrastExtension.fromColorScheme(ColorScheme colorScheme) {
    // Calculate contrast-guaranteed colors
    final primaryWithContrast = _ensureContrast(
      colorScheme.primary,
      colorScheme.surface,
      colorScheme.brightness,
    );

    final onPrimaryWithContrast = _ensureContrast(
      colorScheme.onPrimary,
      colorScheme.primary,
      colorScheme.brightness,
      invertIfNeeded: true,
    );

    final onSurfaceWithContrast = _ensureContrast(
      colorScheme.onSurface,
      colorScheme.surface,
      colorScheme.brightness,
      invertIfNeeded: true,
    );

    final onBackgroundWithContrast = _ensureContrast(
      colorScheme.onSurface,
      colorScheme.surface,
      colorScheme.brightness,
      invertIfNeeded: true,
    );

    return ContrastExtension(
      onPrimaryWithContrast: onPrimaryWithContrast,
      onSurfaceWithContrast: onSurfaceWithContrast,
      onBackgroundWithContrast: onBackgroundWithContrast,
      primaryWithContrast: primaryWithContrast,
    );
  }

  @override
  ThemeExtension<ContrastExtension> copyWith({
    Color? onPrimaryWithContrast,
    Color? onSurfaceWithContrast,
    Color? onBackgroundWithContrast,
    Color? primaryWithContrast,
  }) {
    return ContrastExtension(
      onPrimaryWithContrast:
          onPrimaryWithContrast ?? this.onPrimaryWithContrast,
      onSurfaceWithContrast:
          onSurfaceWithContrast ?? this.onSurfaceWithContrast,
      onBackgroundWithContrast:
          onBackgroundWithContrast ?? this.onBackgroundWithContrast,
      primaryWithContrast: primaryWithContrast ?? this.primaryWithContrast,
    );
  }

  @override
  ThemeExtension<ContrastExtension> lerp(
    covariant ThemeExtension<ContrastExtension>? other,
    double t,
  ) {
    if (other is! ContrastExtension) {
      return this;
    }

    return ContrastExtension(
      onPrimaryWithContrast: Color.lerp(
        onPrimaryWithContrast,
        other.onPrimaryWithContrast,
        t,
      )!,
      onSurfaceWithContrast: Color.lerp(
        onSurfaceWithContrast,
        other.onSurfaceWithContrast,
        t,
      )!,
      onBackgroundWithContrast: Color.lerp(
        onBackgroundWithContrast,
        other.onBackgroundWithContrast,
        t,
      )!,
      primaryWithContrast: Color.lerp(
        primaryWithContrast,
        other.primaryWithContrast,
        t,
      )!,
    );
  }

  /// Ensure a color has sufficient contrast against a background
  static Color _ensureContrast(
    Color color,
    Color background,
    Brightness brightness, {
    bool invertIfNeeded = false,
  }) {
    // Calculate relative luminance
    final colorLuminance = color.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    // Calculate contrast ratio
    final ratio = (max(colorLuminance, backgroundLuminance) + 0.05) /
        (min(colorLuminance, backgroundLuminance) + 0.05);

    // WCAG recommends a contrast ratio of at least 4.5:1 for normal text
    const minContrastRatio = 4.5;

    if (ratio >= minContrastRatio) {
      return color; // Already has sufficient contrast
    }

    // If contrast is insufficient and invertIfNeeded is true, invert the color
    if (invertIfNeeded) {
      return brightness == Brightness.dark
          ? Colors.white.withAlpha(240) // Light text on dark background
          : Colors.black.withAlpha(240); // Dark text on light background
    }

    // Otherwise, adjust the color to increase contrast
    final hsl = HSLColor.fromColor(color);

    if (brightness == Brightness.dark) {
      // In dark mode, make colors brighter for better visibility
      return hsl.withLightness(min(0.8, hsl.lightness + 0.3)).toColor();
    } else {
      // In light mode, make colors darker for better visibility
      return hsl.withLightness(max(0.3, hsl.lightness - 0.3)).toColor();
    }
  }
}

/// Helper methods for contrast extension
extension ContrastExtensionHelpers on ThemeData {
  /// Get the contrast extension
  ContrastExtension get contrast => extension<ContrastExtension>()!;
}

/// Helper function to get the maximum of two doubles
double max(double a, double b) => a > b ? a : b;

/// Helper function to get the minimum of two doubles
double min(double a, double b) => a < b ? a : b;
