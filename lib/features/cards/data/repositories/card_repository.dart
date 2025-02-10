import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';

part 'card_repository.g.dart';

@Riverpod(keepAlive: true)
class CardRepository extends _$CardRepository {
  @override
  FutureOr<void> build() async {
    // Initialize card cache
    await ref.read(cardCacheNotifierProvider.future);
    return;
  }

  Future<List<Card>> searchCards(String searchTerm) async {
    try {
      final cache = await ref.read(cardCacheNotifierProvider.future);
      final normalizedQuery = searchTerm.toLowerCase().trim();

      if (normalizedQuery.isEmpty) {
        return [];
      }

      // Check cache first
      final cachedResults = await cache.getCachedSearchResults(normalizedQuery);
      if (cachedResults != null) {
        return cachedResults;
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
      }

      // Only add progressive substrings for longer name-based queries
      if (normalizedQuery.length > 3 &&
          !normalizedQuery.contains('-') &&
          !RegExp(r'[0-9]').hasMatch(normalizedQuery)) {
        // Add progressive substrings for prefix search
        for (int i = 3; i < normalizedQuery.length; i++) {
          searchTerms.add(normalizedQuery.substring(0, i));
        }
      }

      // Search using arrayContainsAny
      final firestoreService = ref.read(firestoreServiceProvider);
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
            cardNumbers.contains(normalizedQuery)) {
          return 6;
        }

        // Starts with query term gets high priority
        if (name.startsWith(normalizedQuery) ||
            number.startsWith(normalizedQuery) ||
            cardNumbers.any((n) => n.startsWith(normalizedQuery))) {
          return 5;
        }

        // Contains full query term gets medium-high priority
        if (name.contains(normalizedQuery) ||
            number.contains(normalizedQuery) ||
            cardNumbers.any((n) => n.contains(normalizedQuery))) {
          return 4;
        }

        // For longer queries (>3 chars), give some priority to partial matches
        if (normalizedQuery.length > 3) {
          // Partial match at word boundary gets medium priority
          if (name.split(' ').any((word) => word.startsWith(normalizedQuery))) {
            return 3;
          }

          // Number partial match gets low-medium priority
          if (number.contains(normalizedQuery) ||
              cardNumbers.any((n) => n.contains(normalizedQuery))) {
            return 2;
          }
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
          return a.compareByName(b);
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

      // Cache the results
      await cache.cacheSearchResults(normalizedQuery, cards);

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
    try {
      final cache = await ref.read(cardCacheNotifierProvider.future);

      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedCards = await cache.getCachedCards();
        if (cachedCards.isNotEmpty) {
          var filteredCards = cachedCards;

          // Apply filters if needed
          if (filters != null) {
            filteredCards = _applyLocalFilters(filteredCards, filters);
          }

          // Apply pagination
          if (startAfterId != null) {
            final startIndex = filteredCards.indexWhere(
                (card) => card.productId.toString() == startAfterId);
            if (startIndex != -1 && startIndex + 1 < filteredCards.length) {
              filteredCards = filteredCards.sublist(startIndex + 1);
            }
          }

          // Apply limit
          if (filteredCards.length > limit) {
            filteredCards = filteredCards.sublist(0, limit);
          }

          return filteredCards;
        }
      }

      // Fetch from Firestore
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

      // Cache the results
      if (cards.isNotEmpty) {
        await cache.cacheCards(cards);
      }

      return cards;
    } catch (e, stack) {
      talker.error('Error fetching cards from Firestore', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getFilteredCards(CardFilters filters) async {
    try {
      final cache = await ref.read(cardCacheNotifierProvider.future);
      final cachedCards = await cache.getCachedCards();

      // If we have cached cards, apply filters locally
      if (cachedCards.isNotEmpty) {
        return _applyLocalFilters(cachedCards, filters);
      }

      // Otherwise fetch from Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      Query<Map<String, dynamic>> query = firestoreService.cardsCollection;
      query = _applyFilters(query, filters);

      final snapshot = await query.get();
      final cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Cache the results
      if (cards.isNotEmpty) {
        await cache.cacheCards(cards);
      }

      return cards;
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  List<Card> _applyLocalFilters(List<Card> cards, CardFilters filters) {
    var filteredCards = cards.where((card) {
      if (!filters.showSealedProducts && card.isNonCard) return false;

      if (filters.elements.isNotEmpty &&
          !filters.elements.any((e) => card.elements.contains(e))) {
        return false;
      }

      if (filters.types.isNotEmpty && !filters.types.contains(card.cardType)) {
        return false;
      }

      if (filters.sets.isNotEmpty &&
          !filters.sets.contains(card.groupId.toString())) {
        return false;
      }

      if (filters.rarities.isNotEmpty &&
          !filters.rarities.contains(card.rarity)) {
        return false;
      }

      if (filters.minCost != null &&
          (card.cost == null || card.cost! < filters.minCost!)) {
        return false;
      }

      if (filters.maxCost != null &&
          (card.cost == null || card.cost! > filters.maxCost!)) {
        return false;
      }

      if (filters.minPower != null &&
          (card.power == null || card.power! < filters.minPower!)) {
        return false;
      }

      if (filters.maxPower != null &&
          (card.power == null || card.power! > filters.maxPower!)) {
        return false;
      }

      return true;
    }).toList();

    // Apply sorting
    if (filters.sortField != null) {
      filteredCards.sort((a, b) {
        final comparison = switch (filters.sortField) {
          'number' => a.compareByNumber(b),
          'name' => a.compareByName(b),
          'cost' => a.compareByCost(b),
          'power' => a.compareByPower(b),
          _ => 0,
        };
        return filters.sortDescending ? -comparison : comparison;
      });
    }

    return filteredCards;
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
