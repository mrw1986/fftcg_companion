import 'dart:convert';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Keys for settings stored in Hive
class SettingsKeys {
  static const String boxName = 'settings';
  static const String themeMode = 'theme_mode';
  static const String themeColor = 'theme_color';
  static const String recentColors = 'recent_colors';
}

/// Keys for settings stored in Firestore user.settings
class FirestoreSettingsKeys {
  static const String themeMode = 'theme_mode';
  static const String themeColor = 'theme_color';
  static const String recentColors = 'recent_colors';
}

/// Migrates all user settings from one user to another.
/// This includes both local settings (Hive) and remote settings (Firestore).
Future<void> migrateUserSettings({
  required UserRepository userRepository,
  required String fromUserId,
  required String toUserId,
  bool overwrite = false, // If true, overwrites existing settings
}) async {
  try {
    // 1. Get both users' Firestore settings
    final fromUser = await userRepository.getUserById(fromUserId);
    final toUser = await userRepository.getUserById(toUserId);

    if (fromUser == null) {
      talker.error('Source user not found during settings migration');
      return;
    }

    // 2. Merge Firestore settings
    final Map<String, dynamic> mergedSettings = {};

    // If not overwriting, start with target user's settings
    if (!overwrite && toUser != null) {
      mergedSettings.addAll(toUser.settings);
    }

    // Add or overwrite with source user's settings
    mergedSettings.addAll(fromUser.settings);

    // 3. Update Firestore settings for target user
    await userRepository.updateUserSettings(toUserId, mergedSettings);

    // 4. Get local settings from Hive
    if (!Hive.isBoxOpen(SettingsKeys.boxName)) {
      await Hive.openBox(SettingsKeys.boxName);
    }
    final box = Hive.box(SettingsKeys.boxName);

    // 5. Get theme mode
    final themeMode = box.get(SettingsKeys.themeMode);
    if (themeMode != null) {
      mergedSettings[FirestoreSettingsKeys.themeMode] = themeMode;
    }

    // 6. Get theme color
    final themeColor = box.get(SettingsKeys.themeColor);
    if (themeColor != null) {
      mergedSettings[FirestoreSettingsKeys.themeColor] = themeColor;
    }

    // 7. Get recent colors
    final recentColorsJson = box.get(SettingsKeys.recentColors);
    if (recentColorsJson != null) {
      try {
        final recentColors = jsonDecode(recentColorsJson);
        mergedSettings[FirestoreSettingsKeys.recentColors] = recentColors;
      } catch (e) {
        talker.error('Error decoding recent colors during migration: $e');
      }
    }

    // 8. Update Firestore with all merged settings
    await userRepository.updateUserSettings(toUserId, mergedSettings);

    talker.info(
        'Successfully migrated user settings from $fromUserId to $toUserId');
  } catch (e, stack) {
    talker.error('Error during settings migration', e, stack);
    rethrow;
  }
}
