// lib/core/storage/cache_persistence.dart

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_hive_adapter.dart';
// Import the Card model to access the mapper
import 'package:fftcg_companion/features/cards/domain/models/card.dart';

class CachePersistence {
  static const String _cardCacheBox = 'card_cache';
  static const String _queryCacheBox = 'query_cache';
  static const String _sortCacheBox = 'sort_cache';
  static const String _lastUpdateKey = 'last_update';

  static Future<void> initialize() async {
    try {
      // Register adapters first
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CardAdapter());
      }

      if (!Hive.isBoxOpen(_cardCacheBox)) {
        await Hive.openBox<Map>(_cardCacheBox);
      }
      if (!Hive.isBoxOpen(_queryCacheBox)) {
        await Hive.openBox<Map>(_queryCacheBox);
      }
      if (!Hive.isBoxOpen(_sortCacheBox)) {
        await Hive.openBox<Map>(_sortCacheBox);
      }

      talker.debug('Cache persistence initialized');
    } catch (e, stack) {
      talker.error('Failed to initialize cache persistence', e, stack);
      // Attempt recovery
      await _handleCorruptedBoxes();
    }
  }

  static Future<void> _handleCorruptedBoxes() async {
    try {
      await Future.wait([
        Hive.deleteBoxFromDisk(_cardCacheBox),
        Hive.deleteBoxFromDisk(_queryCacheBox),
        Hive.deleteBoxFromDisk(_sortCacheBox),
      ]);

      await initialize();
    } catch (e, stack) {
      talker.error('Failed to recover from corrupted cache', e, stack);
      // Let the app continue without cache
    }
  }

  static Future<void> cacheCards(List<Card> cards) async {
    final box = Hive.box<Map>(_cardCacheBox);
    // Use toMap
    final batch = cards.map((card) => card.toMap()).toList();

    await box.clear();
    for (var i = 0; i < batch.length; i += 100) {
      final end = (i + 100 < batch.length) ? i + 100 : batch.length;
      final chunk = batch.sublist(i, end);
      await box.putAll(
        Map.fromEntries(
          // Ensure json is treated as Map<String, dynamic>
          chunk.map((json) => MapEntry(
              json['productId'].toString(), Map<String, dynamic>.from(json))),
        ),
      );
    }

    await _updateLastModified();
    talker.debug('Cached ${cards.length} cards');
  }

  static Future<void> cacheQuery(
    String key,
    List<Card> cards,
  ) async {
    final box = Hive.box<Map>(_queryCacheBox);
    await box.put(key, {
      // Use toMap
      'cards': cards.map((card) => card.toMap()).toList(),
    });
    talker.debug('Cached query result for key: $key');
  }

  static Future<List<Card>?> getCachedQuery(String key) async {
    final box = Hive.box<Map>(_queryCacheBox);
    final cached = box.get(key);

    if (cached == null) return null;

    try {
      final cardsList = (cached['cards'] as List)
          .cast<Map<String, dynamic>>()
          // Use fromMap
          .map((json) => CardMapper.fromMap(json))
          .toList();

      talker.debug('Retrieved cached query for key: $key');
      return cardsList;
    } catch (e, stack) {
      talker.error('Error deserializing cached query', e, stack);
      await box.delete(key);
      return null;
    }
  }

  static Future<void> cacheSortedResults(
    String key,
    List<Card> cards,
  ) async {
    final box = Hive.box<Map>(_sortCacheBox);
    await box.put(key, {
      // Use toMap
      'cards': cards.map((card) => card.toMap()).toList(),
    });
    talker.debug('Cached sorted results for key: $key');
  }

  static Future<List<Card>?> getCachedSortedResults(String key) async {
    final box = Hive.box<Map>(_sortCacheBox);
    final cached = box.get(key);

    if (cached == null) return null;

    try {
      final cardsList = (cached['cards'] as List)
          .cast<Map<String, dynamic>>()
          // Use fromMap
          .map((json) => CardMapper.fromMap(json))
          .toList();

      talker.debug('Retrieved cached sorted results for key: $key');
      return cardsList;
    } catch (e, stack) {
      talker.error('Error deserializing cached sort results', e, stack);
      await box.delete(key);
      return null;
    }
  }

  static Future<DateTime?> getLastUpdateTime() async {
    final box = Hive.box<Map>(_cardCacheBox);
    final timestamp = box.get(_lastUpdateKey)?['timestamp'] as String?;
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static Future<void> _updateLastModified() async {
    final box = Hive.box<Map>(_cardCacheBox);
    await box.put(_lastUpdateKey, {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> clearCache() async {
    final boxes = [_cardCacheBox, _queryCacheBox, _sortCacheBox];

    for (final boxName in boxes) {
      final box = Hive.box<Map>(boxName);
      await box.clear();
      talker.debug('Cleared cache box: $boxName');
    }
  }

  static String generateQueryKey(Map<String, dynamic> params) {
    final normalized = Map<String, dynamic>.from(params)
      ..remove('timestamp')
      ..remove('validity');

    final jsonString = json.encode(normalized);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
