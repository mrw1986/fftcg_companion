import 'dart:convert'; // Import added for jsonEncode
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/storage/cached_card_adapter.dart';

class FFTCGCacheManager {
  static const String cardBoxName = 'cached_cards';
  static const String queryBoxName = 'cached_queries';
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheEntries = 1000;

  late Box<CachedCard> _cardBox;
  late Box<List<dynamic>> _queryBox;

  static final FFTCGCacheManager _instance = FFTCGCacheManager._internal();

  factory FFTCGCacheManager() => _instance;

  FFTCGCacheManager._internal();

  Future<void> init() async {
    try {
      talker.debug('Initializing FFTCGCacheManager');

      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(CachedCardAdapter());
      }

      _cardBox = await Hive.openBox<CachedCard>(cardBoxName);
      _queryBox = await Hive.openBox<List<dynamic>>(queryBoxName);

      await _cleanOldCache();

      talker.info('✅ FFTCGCacheManager initialized successfully');
    } catch (e, stack) {
      talker.error('Error initializing FFTCGCacheManager', e, stack);
      rethrow;
    }
  }

  Future<void> _cleanOldCache() async {
    try {
      final now = DateTime.now();

      final oldCardKeys = _cardBox.values
          .where((card) => now.difference(card.cacheTime) > cacheDuration)
          .map((card) => card.id)
          .toList();
      if (oldCardKeys.isNotEmpty) {
        await _cardBox.deleteAll(oldCardKeys);
      }

      final oldQueryKeys = _queryBox.keys.where((key) {
        final cacheTime = DateTime.tryParse(_queryBox.get(key)?[0] ?? '');
        return cacheTime == null || now.difference(cacheTime) > cacheDuration;
      }).toList();
      if (oldQueryKeys.isNotEmpty) {
        await _queryBox.deleteAll(oldQueryKeys);
      }

      if (_cardBox.length > maxCacheEntries) {
        final sortedCards = _cardBox.values.toList()
          ..sort((a, b) => a.cacheTime.compareTo(b.cacheTime));

        final keysToDelete = sortedCards
            .take(_cardBox.length - maxCacheEntries)
            .map((card) => card.id)
            .toList();

        await _cardBox.deleteAll(keysToDelete);
      }

      talker.debug('Cache cleanup completed');
    } catch (e, stack) {
      talker.error('Error cleaning cache', e, stack);
    }
  }

  Future<void> cacheCard(DocumentSnapshot cardSnapshot) async {
    try {
      final cachedCard = CachedCard.fromSnapshot(cardSnapshot);
      await _cardBox.put(cardSnapshot.id, cachedCard);
    } catch (e, stack) {
      talker.error('Error caching card', e, stack);
    }
  }

  Future<void> cacheCards(List<DocumentSnapshot> snapshots) async {
    try {
      final Map<String, CachedCard> cards = {
        for (var snap in snapshots) snap.id: CachedCard.fromSnapshot(snap)
      };
      await _cardBox.putAll(cards);
    } catch (e, stack) {
      talker.error('Error caching multiple cards', e, stack);
    }
  }

  Future<void> cacheQueryResult(
    String queryKey,
    List<DocumentSnapshot> snapshots,
  ) async {
    try {
      await cacheCards(snapshots);

      final queryData = [
        DateTime.now().toIso8601String(),
        snapshots.map((s) => s.id).toList(),
      ];

      await _queryBox.put(queryKey, queryData);
    } catch (e, stack) {
      talker.error('Error caching query result', e, stack);
    }
  }

  CachedCard? getCard(String cardId) {
    try {
      final cached = _cardBox.get(cardId);
      if (cached != null &&
          DateTime.now().difference(cached.cacheTime) <= cacheDuration) {
        return cached;
      }
    } catch (e, stack) {
      talker.error('Error retrieving cached card', e, stack);
    }
    return null;
  }

  List<CachedCard>? getCachedQueryResult(String queryKey) {
    try {
      final cached = _queryBox.get(queryKey);
      if (cached != null) {
        final cacheTime = DateTime.parse(cached[0]);
        if (DateTime.now().difference(cacheTime) <= cacheDuration) {
          final cardIds = List<String>.from(cached[1]);
          return cardIds
              .map((id) => getCard(id))
              .whereType<CachedCard>()
              .toList();
        }
      }
    } catch (e, stack) {
      talker.error('Error retrieving cached query result', e, stack);
    }
    return null;
  }

  String generateQueryKey(Map<String, dynamic> queryParams) {
    return jsonEncode(queryParams);
  }

  Future<void> clearCache() async {
    try {
      await _cardBox.clear();
      await _queryBox.clear();
      talker.info('Cache cleared successfully');
    } catch (e, stack) {
      talker.error('Error clearing cache', e, stack);
    }
  }
}

extension CachedCardExtension on CachedCard {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
    };
  }
}
