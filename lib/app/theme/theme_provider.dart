import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  static const _boxName = 'settings';
  static const _themeModeKey = 'theme_mode';

  Box? _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      return null;
    }
    return Hive.box(_boxName);
  }

  @override
  ThemeMode build() {
    final box = _getBox();
    final savedMode =
        box?.get(_themeModeKey, defaultValue: 'system') ?? 'system';
    return _stringToThemeMode(savedMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      final box = Hive.box(_boxName);
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
  static const _boxName = 'settings';
  static const _themeColorKey = 'theme_color';

  Box? _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      return null;
    }
    return Hive.box(_boxName);
  }

  @override
  Color build() {
    final box = _getBox();
    // Default to Material You Purple (0xFF6750A4)
    final savedColor =
        box?.get(_themeColorKey, defaultValue: 0xFF6750A4) ?? 0xFF6750A4;
    return Color(savedColor);
  }

  Future<void> setThemeColor(Color color) async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    final box = Hive.box(_boxName);
    await box.put(_themeColorKey, _colorToInt(color));
    state = color;
  }

  int _colorToInt(Color color) {
    final a = color.a.toInt();
    final r = color.r.toInt();
    final g = color.g.toInt();
    final b = color.b.toInt();

    return (a << 24) | (r << 16) | (g << 8) | b;
  }
}

extension ColorUtils on Color {
  int toHexArgb() {
    return (a.toInt() << 24) | (r.toInt() << 16) | (g.toInt() << 8) | b.toInt();
  }
}
