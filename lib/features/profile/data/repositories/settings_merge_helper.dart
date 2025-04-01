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

    // Initialize merged settings
    Map<String, dynamic> mergedSettings = {};

    // Handle different merge scenarios
    if (fromUser == null) {
      talker.debug('Source user not found, using only target user settings');
      if (toUser != null) {
        mergedSettings = Map.from(toUser.settings);
      }
    } else if (toUser == null) {
      talker.debug('Target user not found, creating with source user settings');
      mergedSettings = Map.from(fromUser.settings);
    } else {
      // Both users exist, handle based on merge action
      if (overwrite) {
        talker.debug('Overwriting target settings with source settings');
        mergedSettings = Map.from(fromUser.settings);
      } else {
        talker.debug('Merging source and target settings');
        // Start with target settings
        mergedSettings = Map.from(toUser.settings);
        // Add source settings, overwriting only if value doesn't exist
        fromUser.settings.forEach((key, value) {
          if (!mergedSettings.containsKey(key)) {
            mergedSettings[key] = value;
          }
        });
      }
    }

    // 3. Update Firestore settings for target user
    if (mergedSettings.isNotEmpty) {
      await userRepository.updateUserSettings(toUserId, mergedSettings);
      talker.debug('Successfully updated target user settings');
    }

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
