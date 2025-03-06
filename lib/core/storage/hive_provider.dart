import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/storage/hive_storage.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

// Create a singleton instance of HiveStorage
final _hiveStorage = HiveStorage();
bool _initialized = false;
bool _initializationFailed = false;

// Provider that exposes the HiveStorage instance
final hiveStorageProvider = Provider<HiveStorage>((ref) {
  // Initialize only once
  if (!_initialized) {
    _initialized = true;

    // Initialize asynchronously but don't block provider creation
    _hiveStorage.initialize().then((_) {
      talker.info('Hive storage initialized successfully');
      _initializationFailed = false;
    }).catchError((e, stack) {
      talker.error('Error initializing Hive storage in provider', e, stack);
      _initializationFailed = true;

      // Try to initialize again after a delay
      Future.delayed(Duration(seconds: 2), () {
        if (_initializationFailed) {
          talker.info('Attempting to reinitialize Hive storage after failure');
          _hiveStorage.initialize().then((_) {
            talker.info('Hive storage reinitialized successfully');
            _initializationFailed = false;
          }).catchError((e, stack) {
            talker.error('Error reinitializing Hive storage', e, stack);
            // The storage will continue with memory cache only
          });
        }
      });
    });
  }

  return _hiveStorage;
});
