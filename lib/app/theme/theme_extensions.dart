import 'package:flutter/material.dart';

extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;
}

extension ColorSchemeExtension on ColorScheme {
  Color get dividerColor => brightness == Brightness.light
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF424242);
}
