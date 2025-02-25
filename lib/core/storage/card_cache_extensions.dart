import 'package:fftcg_companion/core/storage/card_cache.dart';
import 'package:fftcg_companion/core/storage/cache_service.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Extension methods for CardCache to provide compatibility with CacheService methods
extension CardCacheExtensions on CardCache {
  /// Get the data version (returns 0 if not a CacheService)
  Future<int?> getDataVersion() async {
    if (this is CacheService) {
      return (this as CacheService).getDataVersion();
    }
    talker.debug('getDataVersion called on CardCache, returning 0');
    return 0;
  }

  /// Set the data version (no-op if not a CacheService)
  Future<void> setDataVersion(int version) async {
    if (this is CacheService) {
      await (this as CacheService).setDataVersion(version);
    } else {
      talker.debug('setDataVersion called on CardCache, ignoring');
    }
  }

  /// Get the last sync time (returns null if not a CacheService)
  Future<DateTime?> getLastSyncTime() async {
    if (this is CacheService) {
      return (this as CacheService).getLastSyncTime();
    }
    talker.debug('getLastSyncTime called on CardCache, returning null');
    return null;
  }

  /// Set the last sync time (no-op if not a CacheService)
  Future<void> setLastSyncTime(DateTime time) async {
    if (this is CacheService) {
      await (this as CacheService).setLastSyncTime(time);
    } else {
      talker.debug('setLastSyncTime called on CardCache, ignoring');
    }
  }

  /// Clear search cache (clears memory cache and disk cache if available)
  Future<void> clearSearchCache() async {
    try {
      // Clear memory cache using the existing method
      clearMemoryCache();
      talker.debug('Cleared memory cache (including search cache)');

      // Clear disk search cache
      try {
        final searchCacheBox = await Hive.openBox<List>('search_cache');
        await searchCacheBox.clear();
        await searchCacheBox.close();
        talker.debug('Cleared disk search cache');
      } catch (e) {
        talker.debug('Could not clear disk search cache: $e');
      }
    } catch (e, stack) {
      talker.error('Error clearing search cache', e, stack);
    }
  }
}
