import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';

part 'card_repository.g.dart';

/// Provides access to card data with caching support
@Riverpod(keepAlive: true)
class CardRepository extends _$CardRepository {
  @override
  FutureOr<List<Card>> build() async {
    try {
      final cache = await ref.read(cardCacheNotifierProvider.future);
      final cachedCards = await cache.getCachedCards();

      if (cachedCards.isNotEmpty) {
        return cachedCards;
      }

      final firestoreService = ref.read(firestoreServiceProvider);
      final snapshot = await firestoreService.cardsCollection.get();
      final cards =
          snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

      // Only clear memory cache if card count has changed
      final cachedCardCount = (await cache.getCachedCards()).length;
      if (cachedCardCount != cards.length) {
        talker.debug('Card count changed, clearing memory cache');
        await cache.clearMemoryCache();
      }

      await cache.cacheCards(cards);
      return cards;
    } catch (e, stack) {
      talker.error('Error loading cards', e, stack);
      rethrow;
    }
  }

  /// Prefetch images for visible cards to improve performance
  Future<void> prefetchVisibleCardImages(List<Card> visibleCards) async {
    try {
      for (final card in visibleCards.take(20)) {
        final imageUrl = card.getBestImageUrl();
        if (imageUrl != null) {
          CardImageUtils.prefetchImage(imageUrl);
        }
      }
    } catch (e, stack) {
      talker.error('Error loading cards', e, stack);
      rethrow;
    }
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
        talker.debug('Using cached search results for query: $normalizedQuery');
        return cachedResults;
      }

      talker.debug('Search query: "$normalizedQuery"');

      // Generate search terms - always include the full query
      final searchTerms = <String>{normalizedQuery};

      // IMPORTANT: Always add progressive substrings for any query
      // This ensures queries like "Clou" will match "Cloud"
      for (int i = 1; i <= normalizedQuery.length; i++) {
        searchTerms.add(normalizedQuery.substring(0, i));
      }

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
          // Also add variations for partial number matches
          for (int i = 1; i <= normalizedQuery.length; i++) {
            searchTerms.add(normalizedQuery.substring(0, i));
          }
        }
      }

      talker.debug('Generated search terms: ${searchTerms.join(', ')}');

      // IMPORTANT: Firestore's arrayContainsAny is limited to 10 terms
      // If we have more than 10 terms, we need to split into multiple queries
      final firestoreService = ref.read(firestoreServiceProvider);
      List<Card> cards = [];

      // Split search terms into chunks of 10 (Firestore's limit)
      final searchTermChunks = <List<String>>[];
      final termsList = searchTerms.toList();

      for (int i = 0; i < termsList.length; i += 10) {
        final end = (i + 10 < termsList.length) ? i + 10 : termsList.length;
        searchTermChunks.add(termsList.sublist(i, end));
      }

      // Execute each chunk as a separate query and combine results
      for (final chunk in searchTermChunks) {
        final snapshot = await firestoreService.cardsCollection
            .where('searchTerms', arrayContainsAny: chunk)
            .get();

        final chunkCards =
            snapshot.docs.map((doc) => Card.fromFirestore(doc.data())).toList();

        cards.addAll(chunkCards);
      }

      // Remove duplicates (since cards might match multiple terms)
      final uniqueCards = <int, Card>{};
      for (final card in cards) {
        uniqueCards[card.productId] = card;
      }
      cards = uniqueCards.values.toList();

      talker.debug('Found ${cards.length} cards for query "$normalizedQuery"');

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
          return 7;
        }

        // Card number starts with query gets very high priority
        if (cardNumbers.any((n) => n.startsWith(normalizedQuery))) {
          return 6;
        }

        // Name or primary number starts with query gets high priority
        if (name.startsWith(normalizedQuery) ||
            number.startsWith(normalizedQuery)) {
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

      // Also cache progressive substrings for better partial matching
      if (cards.isNotEmpty && normalizedQuery.length > 1) {
        for (int i = 1; i < normalizedQuery.length; i++) {
          final substring = normalizedQuery.substring(0, i);
          final substringResults = cards.where((card) {
            final name = card.name.toLowerCase();
            final number = card.number?.toLowerCase() ?? '';
            return name.startsWith(substring) ||
                number.startsWith(substring) ||
                card.cardNumbers
                    .any((n) => n.toLowerCase().startsWith(substring));
          }).toList();
          if (substringResults.isNotEmpty) {
            await cache.cacheSearchResults(substring, substringResults);
          }
        }
      }

      return cards;
    } catch (e, stack) {
      talker.error('Error searching cards', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getFilteredCards(CardFilters filters) async {
    try {
      // Ensure cards are loaded
      if (state.value?.isEmpty ?? true) {
        ref.invalidateSelf();
      }

      final cards = await future;
      return applyLocalFilters(cards, filters);
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  Future<List<Card>> getCards({
    CardFilters? filters,
    bool forceRefresh = false,
  }) async {
    try {
      // Force refresh if requested
      if (forceRefresh) {
        ref.invalidateSelf();
        // Only clear memory cache on force refresh
        final cache = await ref.read(cardCacheNotifierProvider.future);
        await cache.clearMemoryCache();
      }

      final cards = await future;

      // Apply default sorting if no filters provided
      filters = filters ??
          const CardFilters(sortField: 'number', sortDescending: false);

      return applyLocalFilters(cards, filters);
    } catch (e, stack) {
      talker.error('Error fetching cards', e, stack);
      rethrow;
    }
  }

  /// Apply filters to a list of cards locally
  List<Card> applyLocalFilters(List<Card> cards, CardFilters filters) {
    // Create a list of indices that match the filters
    final indices = <int>[];
    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];

      // For number, cost, and power sorts, always hide non-cards
      if (filters.sortField == 'number' ||
          filters.sortField == 'cost' ||
          filters.sortField == 'power') {
        if (card.isNonCard) continue;
      } else if (!filters.showSealedProducts && card.isNonCard) {
        // For other sorts, respect showSealedProducts flag
        continue;
      }

      // Apply element filter
      if (filters.elements.isNotEmpty) {
        if (!card.elements.any((e) => filters.elements.contains(e))) {
          continue;
        }
      }

      // Apply type filter
      if (filters.types.isNotEmpty) {
        if (!filters.types.contains(card.cardType)) {
          continue;
        }
      }

      // Apply set filter
      if (filters.set.isNotEmpty) {
        if (!card.set.any((s) => filters.set.contains(s))) {
          continue;
        }
      }

      // Apply rarity filter
      if (filters.rarities.isNotEmpty) {
        if (card.rarity == null || !filters.rarities.contains(card.rarity)) {
          continue;
        }
      }

      // Apply cost filter
      if (filters.minCost != null &&
          (card.cost == null || card.cost! < filters.minCost!)) {
        continue;
      }
      if (filters.maxCost != null &&
          (card.cost == null || card.cost! > filters.maxCost!)) {
        continue;
      }

      // Apply power filter
      if (filters.minPower != null &&
          (card.power == null || card.power! < filters.minPower!)) {
        continue;
      }
      if (filters.maxPower != null &&
          (card.power == null || card.power! > filters.maxPower!)) {
        continue;
      }

      // Apply category filter
      if (filters.categories.isNotEmpty) {
        if (!card.categories.any((c) => filters.categories.contains(c))) {
          continue;
        }
      }

      indices.add(i);
    }

    // Sort indices if needed
    if (filters.sortField != null) {
      indices.sort((a, b) {
        final cardA = cards[a];
        final cardB = cards[b];

        // Check if either card is a crystal card
        final aIsCrystal = cardA.number?.startsWith('C-') ?? false;
        final bIsCrystal = cardB.number?.startsWith('C-') ?? false;

        // If one is crystal and other isn't, crystal comes after
        if (aIsCrystal != bIsCrystal) {
          return aIsCrystal ? 1 : -1;
        }

        // If both are crystal or both are not, use normal sorting
        final comparison = switch (filters.sortField) {
          'number' => cardA.compareByNumber(cardB),
          'name' => cardA.compareByName(cardB),
          'cost' => cardA.compareByCost(cardB) != 0
              ? cardA.compareByCost(cardB)
              : cardA.compareByNumber(cardB),
          'power' => cardA.compareByPower(cardB) != 0
              ? cardA.compareByPower(cardB)
              : cardA.compareByNumber(cardB),
          _ => 0,
        };
        return filters.sortDescending ? -comparison : comparison;
      });
    }

    // Create and return filtered list using sorted indices
    return indices.map((i) => cards[i]).toList();
  }
}
