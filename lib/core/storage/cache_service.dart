import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CacheService {
  static const String _cardsBoxName = 'cards';
  static const String _searchCacheBoxName = 'search_cache';
  static const String _metaBoxName = 'cache_meta';
  static const String _filterOptionsBoxName = 'filter_options';
  static const int _currentVersion = 1;

  // Disk cache
  late Box<Map> _cardsBox;
  late Box<List> _searchCacheBox;
  late Box<Map> _filterOptionsBox;
  late Box<dynamic> _metaBox;

  // Memory cache (cleared when app closes)
  final Map<String, List<Card>> _memorySearchCache = {};
  final Map<String, dynamic> _memoryFilterOptions = {};
  List<Card>? _memoryCards;

  Future<void> initialize() async {
    talker.debug('Initializing unified cache service');
    try {
      // Open meta box first to check version
      _metaBox = await Hive.openBox(_metaBoxName);
      final cachedVersion = _metaBox.get('version') as int?;

      // If version mismatch or no version, update version but keep cache
      if (cachedVersion != _currentVersion) {
        talker.warning('Cache version updated to $_currentVersion');
        await _metaBox.put('version', _currentVersion);
      }

      // Open boxes
      _cardsBox = await Hive.openBox<Map>(_cardsBoxName);
      _searchCacheBox = await Hive.openBox<List>(_searchCacheBoxName);
      _filterOptionsBox = await Hive.openBox<Map>(_filterOptionsBoxName);

      talker.debug('Cache service initialized successfully');
    } catch (e, stack) {
      talker.error('Failed to initialize cache service', e, stack);
      // Attempt recovery
      await _handleCorruptedBoxes();
    }
  }

  Future<void> _handleCorruptedBoxes() async {
    try {
      talker.warning('Attempting to recover from corrupted cache boxes');
      await Future.wait([
        Hive.deleteBoxFromDisk(_cardsBoxName),
        Hive.deleteBoxFromDisk(_searchCacheBoxName),
        Hive.deleteBoxFromDisk(_filterOptionsBoxName),
        Hive.deleteBoxFromDisk(_metaBoxName),
      ]);

      await initialize();
    } catch (e, stack) {
      talker.error('Failed to recover from corrupted cache', e, stack);
      // Let the app continue without cache
    }
  }

  Future<void> dispose() async {
    // Clear memory cache
    _memorySearchCache.clear();
    _memoryFilterOptions.clear();
    _memoryCards = null;

    // Close disk cache boxes
    await _cardsBox.close();
    await _searchCacheBox.close();
    await _filterOptionsBox.close();
    await _metaBox.close();
  }

  // Card caching methods
  Future<void> cacheCards(List<Card> cards) async {
    try {
      // Update memory cache
      _memoryCards = cards;

      // Update disk cache in batches to avoid memory issues
      await _cardsBox.clear();

      final batch = <String, Map>{};
      for (final card in cards) {
        batch[card.productId.toString()] = card.toJson();

        // Commit batch every 100 cards to avoid memory issues
        if (batch.length >= 100) {
          await _cardsBox.putAll(batch);
          batch.clear();
        }
      }

      // Commit any remaining cards
      if (batch.isNotEmpty) {
        await _cardsBox.putAll(batch);
      }

      // Update last modified timestamp
      await setLastSyncTime(DateTime.now());

      talker.debug('Cached ${cards.length} cards');
    } catch (e, stack) {
      talker.error('Failed to cache cards', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getCachedCards() async {
    try {
      // Check memory cache first
      if (_memoryCards != null) {
        talker.debug('Using in-memory card cache');
        return _memoryCards!;
      }

      // Fall back to disk cache
      talker.debug('Using disk card cache');
      final cards = _cardsBox.values
          .map((data) => Card.fromJson(Map<String, dynamic>.from(data)))
          .toList();

      // Update memory cache
      _memoryCards = cards;
      return cards;
    } catch (e, stack) {
      talker.error('Failed to get cached cards', e, stack);
      return [];
    }
  }

  // Search cache methods
  Future<void> cacheSearchResults(String query, List<Card> results) async {
    try {
      // Update memory cache
      _memorySearchCache[query] = results;

      // Update disk cache with timestamp for debugging
      final cacheData = [
        DateTime.now().toIso8601String(),
        ...results.map((card) => card.toJson())
      ];
      await _searchCacheBox.put(query, cacheData);

      talker.debug(
          'Cached search results for query: $query (${results.length} results)');
    } catch (e, stack) {
      talker.error('Failed to cache search results', e, stack);
    }
  }

  Future<List<Card>?> getCachedSearchResults(String query) async {
    try {
      // Check memory cache first
      if (_memorySearchCache.containsKey(query)) {
        talker.debug('Using in-memory search cache for query: $query');
        return _memorySearchCache[query];
      }

      // Fall back to disk cache
      final cached = _searchCacheBox.get(query);
      if (cached == null || cached.isEmpty) return null;

      // Rest of elements are card data (skip timestamp)
      final results = cached.skip(1).map((data) {
        final cardData = Map<String, dynamic>.from(data as Map);
        return Card.fromJson(cardData);
      }).toList();

      // Update memory cache
      _memorySearchCache[query] = results;

      talker.debug(
          'Retrieved cached search results for query: $query (${results.length} results)');
      return results;
    } catch (e, stack) {
      talker.error('Failed to get cached search results', e, stack);
      return null;
    }
  }

  // Filter options caching
  Future<void> cacheFilterOptions(Map<String, dynamic> options) async {
    try {
      // Update memory cache
      _memoryFilterOptions.clear();
      _memoryFilterOptions.addAll(options);

      // Update disk cache with timestamp for debugging
      await _filterOptionsBox.put('filter_options', {
        'timestamp': DateTime.now().toIso8601String(),
        'data': options,
      });

      talker.debug('Cached filter options');
    } catch (e, stack) {
      talker.error('Failed to cache filter options', e, stack);
    }
  }

  Future<Map<String, dynamic>?> getCachedFilterOptions() async {
    try {
      // Check memory cache first
      if (_memoryFilterOptions.isNotEmpty) {
        talker.debug('Using in-memory filter options cache');
        return Map<String, dynamic>.from(_memoryFilterOptions);
      }

      // Fall back to disk cache
      final cached = _filterOptionsBox.get('filter_options');
      if (cached == null) return null;

      final options = Map<String, dynamic>.from(cached['data'] as Map);

      // Update memory cache
      _memoryFilterOptions.addAll(options);

      talker.debug('Retrieved cached filter options');
      return options;
    } catch (e, stack) {
      talker.error('Failed to get cached filter options', e, stack);
      return null;
    }
  }

  // Memory cache management
  Future<void> clearMemoryCache() async {
    // Only clear memory cache
    _memoryCards = null;
    _memorySearchCache.clear();
    _memoryFilterOptions.clear();

    talker.debug('Cleared memory cache');
  }

  // Full cache clearing
  Future<void> clearAllCache() async {
    try {
      // Clear memory cache
      clearMemoryCache();

      // Clear disk cache
      await _cardsBox.clear();
      await _searchCacheBox.clear();
      await _filterOptionsBox.clear();

      // Keep version in meta box
      final version = await getVersion();
      await _metaBox.clear();
      if (version != null) {
        await _metaBox.put('version', version);
      }

      talker.debug('Cleared all cache');
    } catch (e, stack) {
      talker.error('Failed to clear all cache', e, stack);
    }
  }

  // Versioning methods
  Future<int?> getVersion() async {
    return _metaBox.get('version') as int?;
  }

  Future<void> setVersion(int version) async {
    await _metaBox.put('version', version);
    talker.debug('Set cache version to $version');
  }

  // Last sync time methods
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = _metaBox.get('lastSync') as String?;
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    await _metaBox.put('lastSync', time.toIso8601String());
    talker.debug('Set last sync time to ${time.toIso8601String()}');
  }

  // Data versioning methods
  Future<int?> getDataVersion() async {
    return _metaBox.get('dataVersion') as int?;
  }

  Future<void> setDataVersion(int version) async {
    await _metaBox.put('dataVersion', version);
    talker.debug('Set data version to $version');
  }

  // Query key generation
  String generateQueryKey(Map<String, dynamic> params) {
    final normalized = Map<String, dynamic>.from(params)
      ..remove('timestamp')
      ..remove('validity');

    final jsonString = json.encode(normalized);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
