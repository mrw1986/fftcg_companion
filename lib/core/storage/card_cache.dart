import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/core/utils/logger.dart';

class CardCache {
  static const String _cardsBoxName = 'cards';
  static const String _searchCacheBoxName = 'search_cache';
  Box<Map>? _cardsBox;
  Box<List>? _searchCacheBox;

  Future<void> initialize() async {
    try {
      // Close any existing boxes
      await Hive.close();

      // Delete existing boxes to change their type
      await Hive.deleteBoxFromDisk(_cardsBoxName);
      await Hive.deleteBoxFromDisk(_searchCacheBoxName);

      // Open boxes with new types
      _cardsBox = await Hive.openBox<Map>(_cardsBoxName);
      _searchCacheBox = await Hive.openBox<List>(_searchCacheBoxName);
      talker.debug('Initialized card cache boxes');
    } catch (e, stack) {
      talker.error('Failed to initialize card cache boxes', e, stack);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _cardsBox?.close();
    await _searchCacheBox?.close();
  }

  Future<void> cacheCards(List<models.Card> cards) async {
    if (_cardsBox == null) return;

    try {
      final batch = <String, Map>{};
      for (final card in cards) {
        batch[card.productId.toString()] = card.toJson();
      }
      await _cardsBox!.putAll(batch);
      talker.debug('Cached ${cards.length} cards');
    } catch (e, stack) {
      talker.error('Failed to cache cards', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> getCachedCards() async {
    if (_cardsBox == null) return [];

    try {
      return _cardsBox!.values
          .map((data) => models.Card.fromJson(Map<String, dynamic>.from(data)))
          .toList();
    } catch (e, stack) {
      talker.error('Failed to get cached cards', e, stack);
      return [];
    }
  }

  Future<void> cacheSearchResults(
      String query, List<models.Card> results) async {
    if (_searchCacheBox == null) return;

    try {
      // Store results as a list with timestamp as first element
      final cacheData = [
        DateTime.now().toIso8601String(),
        ...results.map((card) => card.toJson())
      ];
      await _searchCacheBox!.put(query, cacheData);

      // Clear old cache entries if cache gets too large
      if (_searchCacheBox!.length > 50) {
        final oldestKeys = _searchCacheBox!.keys
            .take(_searchCacheBox!.length - 50)
            .toList()
            .cast<String>();
        await _searchCacheBox!.deleteAll(oldestKeys);
      }
    } catch (e, stack) {
      talker.error('Failed to cache search results', e, stack);
    }
  }

  Future<List<models.Card>?> getCachedSearchResults(String query) async {
    if (_searchCacheBox == null) return null;

    try {
      final cached = _searchCacheBox!.get(query);
      if (cached == null || cached.isEmpty) return null;

      // First element is timestamp
      final timestamp = DateTime.parse(cached[0] as String);
      if (DateTime.now().difference(timestamp) > const Duration(minutes: 30)) {
        await _searchCacheBox!.delete(query);
        return null;
      }

      // Rest of elements are card data
      return cached.skip(1).map((data) {
        final cardData = Map<String, dynamic>.from(data as Map);
        return models.Card.fromJson(cardData);
      }).toList();
    } catch (e, stack) {
      talker.error('Failed to get cached search results', e, stack);
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _cardsBox?.clear();
      await _searchCacheBox?.clear();
      talker.debug('Cleared card cache');
    } catch (e, stack) {
      talker.error('Failed to clear card cache', e, stack);
    }
  }
}
