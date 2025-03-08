import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/services/device_id_service.dart';
import 'package:fftcg_companion/core/storage/hive_storage.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Service to persist anonymous authentication across app restarts and reinstalls
class AnonymousAuthPersistence {
  static const String _anonymousUserKey = 'anonymous_user_credentials';
  static const String _deviceIdKey = 'device_id';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final HiveStorage _storage;
  final DeviceIdService _deviceIdService;

  AnonymousAuthPersistence({
    HiveStorage? storage,
    DeviceIdService? deviceIdService,
  })  : _storage = storage ?? HiveStorage(),
        _deviceIdService = deviceIdService ?? DeviceIdService();

  /// Save the current anonymous user credentials
  Future<void> saveAnonymousUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        // Get the user's ID token
        final idToken = await user.getIdToken();

        // Save the user ID and token
        await _storage.put(_anonymousUserKey, {
          'uid': user.uid,
          'token': idToken,
          'createdAt': DateTime.now().toIso8601String(),
        });

        // Also save the device ID for persistence across reinstalls
        final deviceId = await _deviceIdService.getDeviceId();
        await _storage.put(_deviceIdKey, deviceId);

        talker.debug('Saved anonymous user credentials with device ID');
      }
    } catch (e) {
      talker.error('Error saving anonymous user credentials', e);
    }
  }

  /// Check if we have saved anonymous user credentials
  Future<bool> hasSavedAnonymousUser() async {
    try {
      // First check local storage
      final data = await _storage.get(_anonymousUserKey);
      if (data != null) {
        return true;
      }

      // If not in local storage, check if we have a device ID
      final deviceId = await _storage.get(_deviceIdKey);
      if (deviceId != null) {
        return true;
      }

      // If no device ID in storage, try to generate one
      // This will be used for new installations
      final generatedDeviceId = await _deviceIdService.getDeviceId();
      return generatedDeviceId.isNotEmpty;
    } catch (e) {
      talker.error('Error checking for saved anonymous user', e);
      return false;
    }
  }

  /// Clear saved anonymous user credentials
  Future<void> clearSavedAnonymousUser() async {
    try {
      await _storage.delete(_anonymousUserKey);
      await _storage.delete(_deviceIdKey);
      talker.debug('Cleared anonymous user credentials and device ID');
    } catch (e) {
      talker.error('Error clearing anonymous user credentials', e);
    }
  }

  /// Get the saved anonymous user ID
  Future<String?> getSavedAnonymousUserId() async {
    try {
      // First try to get from local storage
      final data = await _storage.get(_anonymousUserKey);
      if (data != null && data['uid'] != null) {
        return data['uid'] as String;
      }

      // If not found, use the device ID as a seed for a consistent anonymous ID
      final deviceId = await _deviceIdService.getDeviceId();
      if (deviceId.isNotEmpty) {
        // We're not returning the device ID directly, but using it as a seed
        // This way, the same device will always generate the same anonymous ID
        return 'anon_${deviceId.substring(0, 20)}';
      }

      return null;
    } catch (e) {
      talker.error('Error getting saved anonymous user ID', e);
      return null;
    }
  }

  /// Get the device ID
  Future<String?> getDeviceId() async {
    try {
      // First try to get from local storage
      final deviceId = await _storage.get(_deviceIdKey);
      if (deviceId != null) {
        return deviceId as String;
      }

      // If not found, generate a new one
      return await _deviceIdService.getDeviceId();
    } catch (e) {
      talker.error('Error getting device ID', e);
      return null;
    }
  }
}
