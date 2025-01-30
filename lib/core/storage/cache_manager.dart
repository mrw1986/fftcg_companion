// lib/core/storage/cache_manager.dart
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class CacheManager {
  static const cacheValidityDuration = Duration(hours: 24);

  static Future<bool> isCacheValid(String key) async {
    final metadataBox = Hive.box('cache_metadata');
    final lastUpdate = metadataBox.get(key) as DateTime?;

    if (lastUpdate == null) return false;

    return DateTime.now().difference(lastUpdate) < cacheValidityDuration;
  }

  static Future<void> clearAllCaches() async {
    try {
      talker.debug('Clearing all cache boxes');
      await Future.wait([
        Hive.box<Card>('cards').clear(),
        Hive.box<Price>('prices').clear(),
        Hive.box<HistoricalPrice>('historical_prices').clear(),
        Hive.box('cache_metadata').clear(),
      ]);
      talker.info('✅ Cache cleared successfully');
    } catch (e, stack) {
      talker.error('Error clearing caches', e, stack);
      rethrow;
    }
  }
}
