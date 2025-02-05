import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'card_repository.g.dart';

@Riverpod(keepAlive: true)
class CardRepository extends _$CardRepository {
  Box<Map>? _cardBox;
  Box<Map>? _queryCache;
  static const _queryCacheDuration = Duration(minutes: 30);
  Timer? _cleanupTimer;

  @override
  FutureOr<void> build() async {
    await _initializeBoxes();
    _setupCleanupTimer();

    // Add a ref listener to handle disposal
    ref.onDispose(() {
      _cleanupTimer?.cancel();
      _cardBox?.close();
      _queryCache?.close();
      talker.debug('Disposed CardRepository resources');
    });

    return;
  }

  Future<void> _initializeBoxes() async {
    try {
      _cardBox = await Hive.openBox<Map>('cards');
      _queryCache = await Hive.openBox<Map>('query_cache');
      talker.debug('Initialized Hive boxes for CardRepository');
    } catch (e, stack) {
      talker.error('Failed to initialize Hive boxes', e, stack);
      rethrow;
    }
  }

  void _setupCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _cleanupCache(),
    );
  }

  String _generateCacheKey({
    required int limit,
    String? startAfterId,
    CardFilters? filters,
  }) {
    if (filters == null) {
      return 'l$limit${startAfterId != null ? '-s$startAfterId' : ''}';
    }

    // Create compact filter string
    final parts = <String>[];

    // Add basic filters with short prefixes
    if (filters.elements.isNotEmpty) parts.add('e${filters.elements.length}');
    if (filters.types.isNotEmpty) parts.add('t${filters.types.length}');
    if (filters.sets.isNotEmpty) parts.add('s${filters.sets.length}');
    if (filters.rarities.isNotEmpty) parts.add('r${filters.rarities.length}');

    // Add range filters if present
    if (filters.minCost != null) parts.add('c>${filters.minCost}');
    if (filters.maxCost != null) parts.add('c<${filters.maxCost}');
    if (filters.minPower != null) parts.add('p>${filters.minPower}');
    if (filters.maxPower != null) parts.add('p<${filters.maxPower}');

    // Add boolean flags
    if (filters.isNormalOnly == true) parts.add('n');
    if (filters.isFoilOnly == true) parts.add('f');
    if (!filters.showSealedProducts) parts.add('ns');

    // Add sort info if present
    if (filters.sortField?.isNotEmpty == true) {
      parts.add(
          'o${filters.sortField![0]}${filters.sortDescending ? 'd' : 'a'}');
    }

    // Combine everything into a compact key
    final filterStr = parts.isEmpty ? '' : '-${parts.join('')}';
    return 'l$limit${startAfterId != null ? '-s$startAfterId' : ''}$filterStr';
  }

  Future<List<Card>> getCards({
    int limit = 50,
    String? startAfterId,
    CardFilters? filters,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cacheKey = _generateCacheKey(
        limit: limit,
        startAfterId: startAfterId,
        filters: filters,
      );

      final cached = await _getFromCache(cacheKey);
      if (cached != null) {
        talker.debug('Returning cached cards for key: $cacheKey');
        return cached;
      }
    }

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      Query<Map<String, dynamic>> query = firestoreService.cardsCollection;

      if (filters != null) {
        query = _applyFilters(query, filters);
      }

      if (startAfterId != null) {
        final lastDoc =
            await firestoreService.cardsCollection.doc(startAfterId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final snapshot = await query.limit(limit).get();
      final cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      if (cards.isNotEmpty) {
        await _cacheResults(
          _generateCacheKey(
            limit: limit,
            startAfterId: startAfterId,
            filters: filters,
          ),
          cards,
        );
      }

      return cards;
    } catch (e, stack) {
      talker.error('Error fetching cards from Firestore', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getFilteredCards(CardFilters filters) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      Query<Map<String, dynamic>> query = firestoreService.cardsCollection;
      query = _applyFilters(query, filters);

      final snapshot = await query.get();
      var cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Apply sorting after fetching
      if (filters.sortField != null) {
        cards.sort((a, b) {
          // Handle number sorting specially
          if (filters.sortField == 'number') {
            final comparison = a.compareByNumber(b);
            return filters.sortDescending ? -comparison : comparison;
          }

          // Handle other sort fields
          switch (filters.sortField) {
            case 'name':
              final comparison = a.compareByName(b);
              return filters.sortDescending ? -comparison : comparison;
            case 'cost':
              final comparison = a.compareByCost(b);
              return filters.sortDescending ? -comparison : comparison;
            case 'power':
              final comparison = a.compareByPower(b);
              return filters.sortDescending ? -comparison : comparison;
            default:
              return 0;
          }
        });
      }

      return cards;
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> searchCards(String searchTerm) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final normalizedQuery = searchTerm.toLowerCase().trim();

      final snapshot = await firestoreService.cardsCollection
          .where('cleanName', isGreaterThanOrEqualTo: normalizedQuery)
          .where('cleanName', isLessThan: '${normalizedQuery}z')
          .get();

      return snapshot.docs
          .map((doc) => Card.fromFirestore(doc.data()))
          .toList();
    } catch (e, stack) {
      talker.error('Error searching cards', e, stack);
      rethrow;
    }
  }

  Future<List<Card>?> _getFromCache(String key) async {
    if (_queryCache == null) return null;

    final cached = _queryCache!.get(key);
    if (cached == null) return null;

    final timestamp = cached['timestamp'] as DateTime?;
    if (timestamp == null ||
        DateTime.now().difference(timestamp) > _queryCacheDuration) {
      await _queryCache!.delete(key);
      return null;
    }

    try {
      final cardsList = (cached['cards'] as List).map((item) {
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final jsonMap = Map<String, dynamic>.from(item as Map);
        return Card.fromJson(jsonMap);
      }).toList();
      return cardsList;
    } catch (e, stack) {
      talker.error('Error deserializing cached cards', e, stack);
      await _queryCache!.delete(key);
      return null;
    }
  }

  Future<void> _cleanupCache() async {
    if (_queryCache == null) return;

    final now = DateTime.now();
    final keysToDelete = _queryCache!.keys.where((key) {
      final cached = _queryCache!.get(key);
      if (cached == null) return true;

      final timestamp = cached['timestamp'] as DateTime?;
      return timestamp == null ||
          now.difference(timestamp) > _queryCacheDuration;
    }).toList();

    if (keysToDelete.isNotEmpty) {
      await _queryCache!.deleteAll(keysToDelete);
      talker.debug('Cleaned up ${keysToDelete.length} cached queries');
    }
  }

  Future<void> _cacheResults(String key, List<Card> cards) async {
    if (_queryCache == null) return;

    await _queryCache!.put(key, {
      'timestamp': DateTime.now(),
      'cards': cards.map((card) => card.toJson()).toList(),
    });
  }

  Query<Map<String, dynamic>> _applyFilters(
    Query<Map<String, dynamic>> query,
    CardFilters filters,
  ) {
    // Always filter out non-cards when:
    // 1. showSealedProducts is false, or
    // 2. Sorting by number, cost, or power (these don't apply to sealed products)
    if (!filters.showSealedProducts ||
        filters.sortField == 'number' ||
        filters.sortField == 'cost' ||
        filters.sortField == 'power') {
      query = query.where('isNonCard', isEqualTo: false);
    }

    if (filters.elements.isNotEmpty) {
      query =
          query.where('elements', arrayContainsAny: filters.elements.toList());
    }
    if (filters.types.isNotEmpty) {
      query = query.where('cardType', whereIn: filters.types.toList());
    }
    if (filters.sets.isNotEmpty) {
      query = query.where('groupId', whereIn: filters.sets.toList());
    }
    if (filters.rarities.isNotEmpty) {
      query = query.where('rarity', whereIn: filters.rarities.toList());
    }
    if (filters.minCost != null) {
      query = query.where('cost', isGreaterThanOrEqualTo: filters.minCost);
    }
    if (filters.maxCost != null) {
      query = query.where('cost', isLessThanOrEqualTo: filters.maxCost);
    }
    if (filters.minPower != null) {
      query = query.where('power', isGreaterThanOrEqualTo: filters.minPower);
    }
    if (filters.maxPower != null) {
      query = query.where('power', isLessThanOrEqualTo: filters.maxPower);
    }
    return query;
  }
}
