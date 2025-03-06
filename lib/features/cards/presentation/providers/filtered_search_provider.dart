import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Provider that combines search and filter functionality
class FilteredSearchNotifier extends AsyncNotifier<List<models.Card>> {
  @override
  Future<List<models.Card>> build() async {
    // Watch for changes to the search query
    final searchQuery = ref.watch(searchQueryProvider);

    // Watch for changes to the filtered cards
    final filteredCards = await ref.watch(cardsNotifierProvider.future);

    // Watch for changes to the filter provider to get current sort settings
    final currentFilters = ref.watch(filterProvider);

    // If search query is empty, return the filtered cards
    if (searchQuery.isEmpty) {
      return filteredCards;
    }

    // Perform search on the filtered cards using the current filters
    final searchResults = await _searchWithinFilteredCards(
      searchQuery,
      filteredCards,
      currentFilters,
    );

    return searchResults;
  }

  /// Search within the already filtered cards
  Future<List<models.Card>> _searchWithinFilteredCards(
    String query,
    List<models.Card> filteredCards,
    CardFilters? filters,
  ) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();

      if (normalizedQuery.isEmpty) {
        return filteredCards;
      }

      // Determine if this is a card number search
      final isCardNumberSearch = normalizedQuery.contains('-') ||
          RegExp(r'^\d+$').hasMatch(normalizedQuery);

      // Generate search terms - always include the full query
      final searchTerms = <String>{normalizedQuery};

      // Add progressive substrings for any query
      for (int i = 1; i <= normalizedQuery.length; i++) {
        searchTerms.add(normalizedQuery.substring(0, i));
      }

      // Search locally with more strict matching to ensure results actually match the query
      final results = filteredCards.where((card) {
        final name = card.name.toLowerCase();
        final number = card.number?.toLowerCase() ?? '';
        final cardNumbers =
            card.cardNumbers.map((n) => n.toLowerCase()).toList();

        // For name searches, check if the name contains the query
        if (!isCardNumberSearch) {
          return name.contains(normalizedQuery) ||
              name.split(' ').any((word) => word.startsWith(normalizedQuery));
        }

        // For card number searches, check if the number contains the query
        return number.contains(normalizedQuery) ||
            cardNumbers.any((n) => n.contains(normalizedQuery));
      }).toList();

      talker.debug(
          'Found ${results.length} cards locally for query "$normalizedQuery" within ${filteredCards.length} filtered cards');

      // Helper function to calculate relevance score
      int getRelevance(models.Card card) {
        final name = card.name.toLowerCase();
        final number = card.number?.toLowerCase() ?? '';
        final cardNumbers =
            card.cardNumbers.map((n) => n.toLowerCase()).toList();

        // Exact matches get highest priority
        if (name == normalizedQuery ||
            number == normalizedQuery ||
            cardNumbers.contains(normalizedQuery)) {
          return 10;
        }

        // For card number searches, prioritize card number matches
        if (isCardNumberSearch) {
          // Card number exact match
          if (number == normalizedQuery ||
              cardNumbers.contains(normalizedQuery)) {
            return 9;
          }

          // Card number starts with query
          if (number.startsWith(normalizedQuery) ||
              cardNumbers.any((n) => n.startsWith(normalizedQuery))) {
            return 8;
          }
        }
        // For name searches, prioritize name matches
        else {
          // Name starts with query - highest priority for name searches
          if (name.startsWith(normalizedQuery)) {
            return 9;
          }

          // Word in name starts with query
          if (name.split(' ').any((word) => word.startsWith(normalizedQuery))) {
            return 8;
          }

          // Name contains query
          if (name.contains(normalizedQuery)) {
            return 7;
          }
        }

        // Lower priority matches
        if (card.searchTerms.any((term) =>
            term.startsWith(normalizedQuery) ||
            searchTerms.any((searchTerm) => term.startsWith(searchTerm)))) {
          return 3;
        }

        // No relevant match
        return 0;
      }

      // Separate non-cards from regular cards for better sorting control
      final regularCards = results.where((card) => !card.isNonCard).toList();
      final nonCards = results.where((card) => card.isNonCard).toList();

      talker.debug(
          'Search results: ${regularCards.length} regular cards, ${nonCards.length} non-cards');

      // Sort regular cards by relevance first, then by the current sort criteria
      regularCards.sort((a, b) {
        final relevanceA = getRelevance(a);
        final relevanceB = getRelevance(b);

        // If both have same relevance, sort based on current filters
        if (relevanceA == relevanceB) {
          if (filters != null && filters.sortField != null) {
            final comparison = switch (filters.sortField) {
              'number' => a.compareByNumber(b),
              'name' => a.compareByName(b),
              'cost' => a.compareByCost(b) != 0
                  ? a.compareByCost(b)
                  : a.compareByNumber(b),
              'power' => a.compareByPower(b) != 0
                  ? a.compareByPower(b)
                  : a.compareByNumber(b),
              _ => a.compareByNumber(b), // Default to number sort
            };
            return filters.sortDescending ? -comparison : comparison;
          } else {
            // Default to name sort if no filters
            return a.compareByName(b);
          }
        }
        // Otherwise sort by relevance
        return relevanceB.compareTo(relevanceA);
      });

      // Sort non-cards by name
      nonCards.sort((a, b) {
        if (filters != null && filters.sortField == 'name') {
          final nameA = a.cleanName.toLowerCase();
          final nameB = b.cleanName.toLowerCase();
          return filters.sortDescending
              ? nameB.compareTo(nameA)
              : nameA.compareTo(nameB);
        }
        return a.cleanName.toLowerCase().compareTo(b.cleanName.toLowerCase());
      });

      // Combine the lists with regular cards first, non-cards at the bottom
      final sortedResults = [...regularCards, ...nonCards];

      // Verify non-cards are at the bottom
      if (nonCards.isNotEmpty && regularCards.isNotEmpty) {
        final firstNonCardIndex =
            sortedResults.indexWhere((card) => card.isNonCard);
        final lastRegularCardIndex =
            sortedResults.lastIndexWhere((card) => !card.isNonCard);

        if (firstNonCardIndex < lastRegularCardIndex) {
          talker.error(
              'Sorting error in search results: Non-card found before regular card!');
          // Force correct order by re-sorting
          sortedResults.sort((a, b) =>
              a.isNonCard == b.isNonCard ? 0 : (a.isNonCard ? 1 : -1));
        } else {
          talker.debug(
              'Search results sorting verified: All non-cards are at the bottom');
        }
      }

      return sortedResults;
    } catch (e, stack) {
      talker.error('Error searching within filtered cards', e, stack);
      return [];
    }
  }

  /// Apply new filters and update the search results
  Future<void> applyFilters(CardFilters filters) async {
    // Let the cards notifier handle the filtering
    await ref.read(cardsNotifierProvider.notifier).applyFilters(filters);

    // Invalidate this provider to trigger a rebuild with the new filtered cards
    ref.invalidateSelf();
  }
}

/// Provider that exposes the filtered search notifier
final filteredSearchNotifierProvider =
    AsyncNotifierProvider<FilteredSearchNotifier, List<models.Card>>(
  () => FilteredSearchNotifier(),
);

/// Provider that exposes the filtered search results
final filteredSearchProvider = Provider<AsyncValue<List<models.Card>>>((ref) {
  return ref.watch(filteredSearchNotifierProvider);
});
