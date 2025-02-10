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

      // Handle number formats
      if (normalizedQuery.contains('-') ||
          RegExp(r'[0-9]').hasMatch(normalizedQuery)) {
        // Add original number format
        searchTerms.add(normalizedQuery);

        // If query contains hyphen (e.g., "1-001H" or "20-040L")
        if (normalizedQuery.contains('-')) {
          final parts = normalizedQuery.split('-');
          if (parts.length == 2) {
            final prefix = parts[0];
            final suffix = parts[1];

            // Add set number variations (e.g., "1", "20")
            if (prefix.isNotEmpty) {
              searchTerms.add(prefix);
              searchTerms.add('$prefix-');
            }

            // Add progressive card number variations
            if (prefix.isNotEmpty && suffix.isNotEmpty) {
              for (int i = 1; i <= suffix.length; i++) {
                searchTerms.add('$prefix-${suffix.substring(0, i)}');
              }
            }
          }
        }
        // If it's just a number (potential set number), add variations
        else if (RegExp(r'^\d+$').hasMatch(normalizedQuery)) {
          searchTerms.add('$normalizedQuery-');
        }

        // We no longer need progressive substrings of the cleaned number
        // as we already have proper variations with hyphens
      }

      // Only add progressive substrings and soundex for longer name-based queries
      if (normalizedQuery.length > 3 &&
          !normalizedQuery.contains('-') &&
          !RegExp(r'[0-9]').hasMatch(normalizedQuery)) {
        // Add progressive substrings for prefix search
        for (int i = 3; i < normalizedQuery.length; i++) {
          searchTerms.add(normalizedQuery.substring(0, i));
        }
        // We no longer use soundex codes
      }

      // Search using arrayContainsAny
      final snapshot = await firestoreService.cardsCollection
          .where('searchTerms', arrayContainsAny: searchTerms.toList())
          .limit(50)
          .get();

      final cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Helper function to calculate relevance score
      int getRelevance(Card card) {
        final name = card.name.toLowerCase();
        final number = card.number?.toLowerCase() ?? '';
        final cardNumbers =
            card.cardNumbers.map((n) => n.toLowerCase()).toList();

        // Exact matches get highest priority
        if (name == normalizedQuery ||
            number == normalizedQuery ||
            cardNumbers.contains(normalizedQuery)) return 6;

        // Starts with query term gets high priority
        if (name.startsWith(normalizedQuery) ||
            number.startsWith(normalizedQuery) ||
            cardNumbers.any((n) => n.startsWith(normalizedQuery))) return 5;

        // Contains full query term gets medium-high priority
        if (name.contains(normalizedQuery) ||
            number.contains(normalizedQuery) ||
            cardNumbers.any((n) => n.contains(normalizedQuery))) return 4;

        // For longer queries (>3 chars), give some priority to partial matches
        if (normalizedQuery.length > 3) {
          // Partial match at word boundary gets medium priority
          if (name.split(' ').any((word) => word.startsWith(normalizedQuery)))
            return 3;

          // Number partial match gets low-medium priority
          if (number.contains(normalizedQuery) ||
              cardNumbers.any((n) => n.contains(normalizedQuery))) return 2;

          // We no longer use soundex matching
          return 0;
        }

        // No relevant match
        return 0;
      }

      // Enhanced relevance sorting
      cards.sort((a, b) {
        final relevanceA = getRelevance(a);
        final relevanceB = getRelevance(b);

        // If both have same relevance, sort based on query type
        if (relevanceA == relevanceB) {
          // If query looks like a card number, sort by number
          if (normalizedQuery.contains('-') ||
              RegExp(r'[0-9]').hasMatch(normalizedQuery)) {
            return a.compareByNumber(b);
          }
          // Otherwise sort alphabetically by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        // Otherwise sort by relevance
        return relevanceB.compareTo(relevanceA);
      });

      // Remove cards with 0 relevance
      cards.removeWhere((card) {
        final name = card.name.toLowerCase();
        final number = card.number?.toLowerCase() ?? '';
        final cardNumbers =
            card.cardNumbers.map((n) => n.toLowerCase()).toList();

        if (normalizedQuery.length <= 3) {
          // For short queries, must exactly match or start with query
          return !name.startsWith(normalizedQuery) &&
              !number.startsWith(normalizedQuery) &&
              !cardNumbers.any((n) => n.startsWith(normalizedQuery));
        }

        // For longer queries, must at least partially match
        return !name.contains(normalizedQuery) &&
            !name.split(' ').any((word) => word.startsWith(normalizedQuery)) &&
            !number.contains(normalizedQuery) &&
            !cardNumbers.any((n) => n.contains(normalizedQuery));
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
