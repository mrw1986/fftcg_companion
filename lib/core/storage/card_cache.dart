import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/core/utils/logger.dart';

class CardCache {
  static const String _cardsBoxName = 'cards';
  static const String _searchCacheBoxName = 'search_cache';
  static const String _filterOptionsBoxName = 'filter_options';
  static const String _metaBoxName = 'cache_meta';
  static const int _currentVersion =
      1; // Increment when cache structure changes

  // Disk cache
  Box<Map>? _cardsBox;
  Box<List>? _searchCacheBox;
  Box<Map>? _filterOptionsBox;
  Box<dynamic>? _metaBox;

  // Memory cache (cleared when app closes)
  final Map<String, List<models.Card>> _memorySearchCache = {};
  final Map<String, dynamic> _memoryFilterOptions = {};
  List<models.Card>? _memoryCards;

  Future<void> initialize() async {
    talker.debug('Initializing card cache');
    try {
      // Open meta box first to check version
      _metaBox = await Hive.openBox(_metaBoxName);
      final cachedVersion = _metaBox?.get('version') as int?;

      // If version mismatch or no version, update version but keep cache
      if (cachedVersion != _currentVersion) {
        talker.warning('Cache version updated to $_currentVersion');
        await _metaBox?.put('version', _currentVersion);
      }

      // Open boxes
      _cardsBox = await Hive.openBox<Map>(_cardsBoxName);
      _searchCacheBox = await Hive.openBox<List>(_searchCacheBoxName);
      _filterOptionsBox = await Hive.openBox<Map>(_filterOptionsBoxName);
    } catch (e, stack) {
      talker.error('Failed to initialize card cache boxes', e, stack);
      rethrow;
    }
  }

  Future<void> dispose() async {
    // Clear memory cache
    _memorySearchCache.clear();
    _memoryFilterOptions.clear();
    _memoryCards = null;

    // Close disk cache boxes
    await _cardsBox?.close();
    await _searchCacheBox?.close();
    await _filterOptionsBox?.close();
  }

  Future<void> cacheCards(List<models.Card> cards) async {
    if (_cardsBox == null) return;

    try {
      // Update memory cache
      _memoryCards = cards;

      // Update disk cache
      final batch = <String, Map>{};
      for (final card in cards) {
        batch[card.productId.toString()] = card.toJson();
      }
      await _cardsBox!.putAll(batch);
    } catch (e, stack) {
      talker.error('Failed to cache cards', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> getCachedCards() async {
    if (_cardsBox == null) return [];

    try {
      // Check memory cache first
      if (_memoryCards != null) {
        talker.debug('Using in-memory card cache');
        return _memoryCards!;
      }

      // Fall back to disk cache
      talker.debug('Using disk card cache');
      final cards = _cardsBox!.values
          .map((data) => models.Card.fromJson(Map<String, dynamic>.from(data)))
          .toList();

      // Update memory cache
      _memoryCards = cards;
      return cards;
    } catch (e, stack) {
      talker.error('Failed to get cached cards', e, stack);
      return [];
    }
  }

  Future<void> cacheSearchResults(
      String query, List<models.Card> results) async {
    if (_searchCacheBox == null) return;

    try {
      // Update memory cache
      _memorySearchCache[query] = results;

      // Update disk cache with timestamp for debugging
      final cacheData = [
        DateTime.now().toIso8601String(),
        ...results.map((card) => card.toJson())
      ];
      await _searchCacheBox!.put(query, cacheData);
    } catch (e, stack) {
      talker.error('Failed to cache search results', e, stack);
    }
  }

  Future<List<models.Card>?> getCachedSearchResults(String query) async {
    if (_searchCacheBox == null) return null;

    try {
      // Check memory cache first
      if (_memorySearchCache.containsKey(query)) {
        talker.debug('Using in-memory search cache for query: $query');
        return _memorySearchCache[query];
      }

      // Fall back to disk cache
      final cached = _searchCacheBox!.get(query);
      if (cached == null || cached.isEmpty) return null;

      // Rest of elements are card data (skip timestamp)
      final results = cached.skip(1).map((data) {
        final cardData = Map<String, dynamic>.from(data as Map);
        return models.Card.fromJson(cardData);
      }).toList();

      // Update memory cache
      _memorySearchCache[query] = results;
      return results;
    } catch (e, stack) {
      talker.error('Failed to get cached search results', e, stack);
      return null;
    }
  }

  Future<void> clearMemoryCache() async {
    // Only clear memory cache
    _memoryCards = null;
    _memorySearchCache.clear();
    _memoryFilterOptions.clear();
  }

  // Filter options caching
  Future<void> cacheFilterOptions(Map<String, dynamic> options) async {
    if (_filterOptionsBox == null) return;

    try {
      // Update memory cache
      _memoryFilterOptions.clear();
      _memoryFilterOptions.addAll(options);

      // Update disk cache with timestamp for debugging
      await _filterOptionsBox!.put('filter_options', {
        'timestamp': DateTime.now().toIso8601String(),
        'data': options,
      });
    } catch (e, stack) {
      talker.error('Failed to cache filter options', e, stack);
    }
  }

  Future<Map<String, dynamic>?> getCachedFilterOptions() async {
    if (_filterOptionsBox == null) return null;

    try {
      // Check memory cache first
      if (_memoryFilterOptions.isNotEmpty) {
        talker.debug('Using in-memory filter options cache');
        return Map<String, dynamic>.from(_memoryFilterOptions);
      }

      // Fall back to disk cache
      final cached = _filterOptionsBox!.get('filter_options');
      if (cached == null) return null;

      final options = Map<String, dynamic>.from(cached['data'] as Map);

      // Update memory cache
      _memoryFilterOptions.addAll(options);
      return options;
    } catch (e, stack) {
      talker.error('Failed to get cached filter options', e, stack);
      return null;
    }
  }
}
