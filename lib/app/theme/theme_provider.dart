import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';
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
  static const _recentColorsKey = 'recent_colors';

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

  /// Get the list of recently used colors
  List<Color> getRecentColors() {
    try {
      final box = _getBox();
      if (box == null) return [];

      final recentColorsJson = box.get(_recentColorsKey);
      if (recentColorsJson == null) return [];

      final List<dynamic> colorsList = jsonDecode(recentColorsJson);
      return colorsList.map((colorInt) => Color(colorInt)).toList();
    } catch (e, stack) {
      talker.error('Error getting recent colors', e, stack);
      return [];
    }
  }

  /// Save the list of recently used colors
  Future<void> saveRecentColors(List<Color> colors) async {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.openBox(_boxName);
      }
      final box = Hive.box(_boxName);

      // Convert colors to a list of integers for storage
      final colorInts = colors.map((color) => _colorToInt(color)).toList();

      // Store as JSON string
      await box.put(_recentColorsKey, jsonEncode(colorInts));
      talker.debug('Saved ${colors.length} recent colors');
    } catch (e, stack) {
      talker.error('Error saving recent colors', e, stack);
    }
  }
}

extension ColorUtils on Color {
  /// Convert a Color to an integer representation
  int toHexArgb() {
    return (a.toInt() << 24) | (r.toInt() << 16) | (g.toInt() << 8) | b.toInt();
  }

  /// Get a string representation of the color
  String toHexString() {
    return '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
