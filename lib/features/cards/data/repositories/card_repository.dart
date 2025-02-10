import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/utils/soundex.dart';

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

  Future<List<Card>> searchCards(String searchTerm) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final normalizedQuery = searchTerm.toLowerCase().trim();

      if (normalizedQuery.isEmpty) {
        return [];
      }

      // Generate search terms
      final searchTerms = <String>{normalizedQuery};

      // Only add progressive substrings and soundex for longer queries
      if (normalizedQuery.length > 3) {
        // Add progressive substrings for prefix search
        for (int i = 3; i < normalizedQuery.length; i++) {
          searchTerms.add(normalizedQuery.substring(0, i));
        }
        // Add soundex term for longer queries
        searchTerms.add(SoundexUtil.generate(normalizedQuery));
      }

      // Search using arrayContainsAny
      final snapshot = await firestoreService.cardsCollection
          .where('searchTerms', arrayContainsAny: searchTerms.toList())
          .limit(50)
          .get();

      final cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Enhanced relevance sorting
      cards.sort((a, b) {
        int getRelevance(Card card) {
          final name = card.name.toLowerCase();
          // Exact match gets highest priority
          if (name == normalizedQuery) return 5;
          // Starts with query term gets high priority
          if (name.startsWith(normalizedQuery)) return 4;
          // Contains full query term gets medium priority
          if (name.contains(normalizedQuery)) return 3;
          // For longer queries (>3 chars), give some priority to partial matches
          if (normalizedQuery.length > 3) {
            // Partial match at word boundary gets low priority
            if (name
                .split(' ')
                .any((word) => word.startsWith(normalizedQuery))) {
              return 2;
            }
            // Soundex match gets lowest priority
            if (SoundexUtil.generate(name) ==
                SoundexUtil.generate(normalizedQuery)) {
              return 1;
            }
          }
          // No relevant match
          return 0;
        }

        final relevanceA = getRelevance(a);
        final relevanceB = getRelevance(b);

        // Filter out completely irrelevant matches
        if (normalizedQuery.length <= 3) {
          // For short queries, only keep exact matches or starts-with matches
          if (relevanceA < 4 && relevanceB < 4) return 0;
        } else {
          // For longer queries, filter out anything below partial word boundary matches
          if (relevanceA < 2 && relevanceB < 2) return 0;
        }

        return relevanceB.compareTo(relevanceA);
      });

      // Remove cards with 0 relevance
      cards.removeWhere((card) {
        final name = card.name.toLowerCase();
        if (normalizedQuery.length <= 3) {
          // For short queries, must exactly match or start with query
          return !name.startsWith(normalizedQuery);
        }
        // For longer queries, must at least partially match at word boundaries
        return !name.contains(normalizedQuery) &&
            !name.split(' ').any((word) => word.startsWith(normalizedQuery));
      });

      return cards;
    } catch (e, stack) {
      talker.error('Error searching cards', e, stack);
      rethrow;
    }
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

  String _generateCacheKey({
    required int limit,
    String? startAfterId,
    CardFilters? filters,
  }) {
    if (filters == null) {
      return 'l$limit${startAfterId != null ? '-s$startAfterId' : ''}';
    }

    final parts = <String>[];

    if (filters.elements.isNotEmpty) parts.add('e${filters.elements.length}');
    if (filters.types.isNotEmpty) parts.add('t${filters.types.length}');
    if (filters.sets.isNotEmpty) parts.add('s${filters.sets.length}');
    if (filters.rarities.isNotEmpty) parts.add('r${filters.rarities.length}');

    if (filters.minCost != null) parts.add('c>${filters.minCost}');
    if (filters.maxCost != null) parts.add('c<${filters.maxCost}');
    if (filters.minPower != null) parts.add('p>${filters.minPower}');
    if (filters.maxPower != null) parts.add('p<${filters.maxPower}');

    if (filters.isNormalOnly == true) parts.add('n');
    if (filters.isFoilOnly == true) parts.add('f');
    if (!filters.showSealedProducts) parts.add('ns');

    if (filters.sortField?.isNotEmpty == true) {
      parts.add(
          'o${filters.sortField![0]}${filters.sortDescending ? 'd' : 'a'}');
    }

    final filterStr = parts.isEmpty ? '' : '-${parts.join('')}';
    return 'l$limit${startAfterId != null ? '-s$startAfterId' : ''}$filterStr';
  }

  Future<List<Card>> getFilteredCards(CardFilters filters) async {
    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      Query<Map<String, dynamic>> query = firestoreService.cardsCollection;
      query = _applyFilters(query, filters);

      final snapshot = await query.get();
      var cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      if (filters.sortField != null) {
        cards.sort((a, b) {
          if (filters.sortField == 'number') {
            final comparison = a.compareByNumber(b);
            return filters.sortDescending ? -comparison : comparison;
          }

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
        // Convert the raw map to ensure proper types for nested maps
        final Map<String, dynamic> jsonMap = {};
        (item as Map).forEach((key, value) {
          if (key == 'searchName' || key == 'searchNumber') {
            // Convert nested maps to proper Map<String, num>
            final Map<String, num> convertedMap = {};
            (value as Map).forEach((k, v) {
              convertedMap[k.toString()] =
                  (v is num) ? v : num.parse(v.toString());
            });
            jsonMap[key.toString()] = convertedMap;
          } else {
            jsonMap[key.toString()] = value;
          }
        });
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
