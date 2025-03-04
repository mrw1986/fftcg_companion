// lib/features/profile/presentation/providers/splash_screen_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'splash_screen_provider.g.dart';

@riverpod
class SplashScreenPreferences extends _$SplashScreenPreferences {
  static const _boxName = 'settings';
  static const _enabledKey = 'splash_screen_enabled';
  static const _durationKey = 'splash_screen_duration';

  Box? _getBox() {
    if (!Hive.isBoxOpen(_boxName)) {
      try {
        return Hive.box(_boxName);
      } catch (e) {
        return null;
      }
    }
    return Hive.box(_boxName);
  }

  Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  ({bool enabled, int durationInSeconds}) build() {
    final box = _getBox();
    return (
      enabled: box?.get(_enabledKey, defaultValue: true) ?? true,
      durationInSeconds: box?.get(_durationKey, defaultValue: 2) ?? 2,
    );
  }

  Future<void> toggleEnabled() async {
    final box = await _openBox();
    await box.put(_enabledKey, !state.enabled);
    state = (
      enabled: !state.enabled,
      durationInSeconds: state.durationInSeconds,
    );
  }

  Future<void> setDuration(int seconds) async {
    if (seconds < 1 || seconds > 5) {
      return; // Limit duration between 1-5 seconds
    }

    final box = await _openBox();
    await box.put(_durationKey, seconds);
    state = (
      enabled: state.enabled,
      durationInSeconds: seconds,
    );
  }
}
