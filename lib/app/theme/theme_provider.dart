import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const _themeModeKey = 'theme_mode';

  @override
  ThemeMode build() {
    final box = Hive.box('settings');
    final savedMode = box.get(_themeModeKey, defaultValue: 'system');
    return _stringToThemeMode(savedMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final box = Hive.box('settings');
      await box.put(_themeModeKey, _themeModeToString(mode));
      talker.debug('Theme mode updated to: ${mode.toString()}');
      state = mode;
    } catch (e, stack) {
      talker.error('Error setting theme mode', e, stack);
      rethrow;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }

  ThemeMode _stringToThemeMode(String mode) {
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

@Riverpod(keepAlive: true)
class ThemeColorController extends _$ThemeColorController {
  static const _themeColorKey = 'theme_color';

  @override
  Color build() {
    final box = Hive.box('settings');
    // Default to Material You Purple (0xFF6750A4)
    final savedColor = box.get(_themeColorKey, defaultValue: 0xFF6750A4);
    return Color(savedColor);
  }

  Future<void> setThemeColor(Color color) async {
    final box = Hive.box('settings');
    await box.put(_themeColorKey, _colorToInt(color));
    state = color;
  }

  int _colorToInt(Color color) {
    final a = (color.a * 255).round();
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}

extension ColorUtils on Color {
  int toHexArgb() {
    // Convert double values to integers before bit operations
    final alphaInt = a.toInt();
    final redInt = r.toInt();
    final greenInt = g.toInt();
    final blueInt = b.toInt();

    return (alphaInt << 24) | (redInt << 16) | (greenInt << 8) | blueInt;
  }
}
