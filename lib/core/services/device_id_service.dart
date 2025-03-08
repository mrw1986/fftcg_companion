import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:flutter/foundation.dart';

/// Service for generating a consistent device identifier
/// This ID will remain the same across app reinstallations on the same device
class DeviceIdService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Get a unique device identifier that persists across app reinstalls
  /// Returns a SHA-256 hash of device-specific information
  Future<String> getDeviceId() async {
    try {
      String deviceData = '';

      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceData = _getWebIdentifier(webInfo);
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = _getAndroidIdentifier(androidInfo);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = _getIOSIdentifier(iosInfo);
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceData = windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        deviceData = macOsInfo.systemGUID ?? macOsInfo.computerName;
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceData = linuxInfo.machineId ?? linuxInfo.id;
      }

      // Add a salt to make the hash more secure
      // This should be a constant value that doesn't change
      const salt = 'fftcg_companion_device_id_salt';
      deviceData = '$deviceData:$salt';

      // Generate a SHA-256 hash of the device data
      final bytes = utf8.encode(deviceData);
      final digest = sha256.convert(bytes);

      return digest.toString();
    } catch (e, stack) {
      talker.error('Error getting device ID', e, stack);
      // Fallback to a random ID if we can't get a device ID
      // This will be different each time the app is reinstalled
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  /// Get a unique identifier for Android devices
  String _getAndroidIdentifier(AndroidDeviceInfo info) {
    // Combine multiple identifiers to create a more stable ID
    // Android ID can change on factory reset, but combined with other values
    // it provides a more stable identifier
    return [
      info.id,
      info.brand,
      info.device,
      info.model,
      info.product,
      info.hardware,
      info.fingerprint,
    ].join(':');
  }

  /// Get a unique identifier for iOS devices
  String _getIOSIdentifier(IosDeviceInfo info) {
    // Use identifierForVendor which remains the same as long as the user has
    // at least one app from the same vendor installed
    return [
      info.identifierForVendor ?? '',
      info.model,
      info.name,
      info.systemName,
      info.systemVersion,
    ].join(':');
  }

  /// Get a unique identifier for web browsers
  String _getWebIdentifier(WebBrowserInfo info) {
    // Web is tricky because browsers limit fingerprinting
    // This is a best-effort approach
    return [
      info.browserName.name,
      info.platform ?? '',
      info.language ?? '',
      info.userAgent ?? '',
      info.vendor ?? '',
    ].join(':');
  }
}
