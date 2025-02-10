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
    String? startAfterId,
    CardFilters? filters,
    bool forceRefresh = false,
  }) async {
    // Apply default sorting if no filters provided
    filters = filters ??
        const CardFilters(sortField: 'number', sortDescending: false);
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

          return filteredCards;
        }
      }

      // Fetch from Firestore
      final firestoreService = ref.read(firestoreServiceProvider);
      Query<Map<String, dynamic>> query = firestoreService.cardsCollection;

      // Apply non-card filter first
      if (!filters.showSealedProducts ||
          filters.sortField == 'number' ||
          filters.sortField == 'cost' ||
          filters.sortField == 'power') {
        query = query.where('isNonCard', isEqualTo: false);
      }

      // Due to Firestore limitations with array queries, we'll fetch all cards
      // and filter locally when array filters are present
      if (filters.elements.isNotEmpty || filters.sets.isNotEmpty) {
        final snapshot = await query.get();
        var cards =
            snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();
        return _applyLocalFilters(cards, filters);
      }

      // Apply non-array filters in Firestore
      if (filters.types.isNotEmpty) {
        query = query.where('cardType', whereIn: filters.types.toList());
      }
      if (filters.rarities.isNotEmpty) {
        query = query.where('rarity', whereIn: filters.rarities.toList());
      }

      final snapshot = await query.get();
      var cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Apply array filters locally since Firestore has limitations
      if (filters != null) {
        cards = _applyLocalFilters(cards, filters);
      }

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
      return getCards(filters: filters);
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  List<Card> _applyLocalFilters(List<Card> cards, CardFilters filters) {
    var filteredCards = cards.where((card) {
      if (!filters.showSealedProducts && card.isNonCard) return false;

      // Apply element filter
      if (filters.elements.isNotEmpty) {
        if (!card.elements.any((e) => filters.elements.contains(e))) {
          return false;
        }
      }

      // Apply type filter
      if (filters.types.isNotEmpty) {
        if (!filters.types.contains(card.cardType)) {
          return false;
        }
      }

      // Apply set filter
      if (filters.sets.isNotEmpty) {
        if (!card.set.any((s) => filters.sets.contains(s))) {
          return false;
        }
      }

      // Apply rarity filter
      if (filters.rarities.isNotEmpty) {
        if (!filters.rarities.contains(card.rarity)) {
          return false;
        }
      }

      // Apply cost filter
      if (filters.minCost != null &&
          (card.cost == null || card.cost! < filters.minCost!)) {
        return false;
      }
      if (filters.maxCost != null &&
          (card.cost == null || card.cost! > filters.maxCost!)) {
        return false;
      }

      // Apply power filter
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
}
