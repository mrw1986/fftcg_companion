// lib/features/cards/presentation/providers/cards_provider.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
// Import favorite/wishlist providers
import 'package:fftcg_companion/features/cards/presentation/providers/favorites_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/wishlist_provider.dart';
// Import card filter provider to read current filters
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';

part 'cards_provider.g.dart';

/// Manages the card list state and filtering operations
@Riverpod(keepAlive: true)
class CardsNotifier extends _$CardsNotifier {
  CardFilters? _currentFilters;

  @override
  FutureOr<List<models.Card>> build() async {
    _currentFilters = const CardFilters(
      sortField: 'number',
      sortDescending: false,
    );

    final repository = ref.read(cardRepositoryProvider.notifier);
    final cards = await repository.getCards(filters: _currentFilters);
    // Apply initial status filters if any were loaded from persistence
    final initialFilters = ref.read(cardFilterProvider);
    return _applyStatusFilters(cards, initialFilters);
  }

  /// Apply new filters to the card list
  Future<void> applyFilters(CardFilters filters) async {
    // Optimization: Don't refetch if only favorite/wishlist status changed
    // We can filter the current state locally for these flags.
    final bool onlyStatusChanged = _currentFilters != null &&
        _currentFilters!.copyWith(
              showFavoritesOnly: filters.showFavoritesOnly,
              showWishlistOnly: filters.showWishlistOnly,
            ) ==
            filters.copyWith(
              showFavoritesOnly: _currentFilters!.showFavoritesOnly,
              showWishlistOnly: _currentFilters!.showWishlistOnly,
            );

    if (_currentFilters == filters) return; // No change at all

    // If only status changed and we have existing data, filter locally
    if (onlyStatusChanged && state.hasValue) {
      talker.debug('Applying favorite/wishlist filters locally.');
      _currentFilters = filters; // Update current filters
      final currentCards = state.value!;
      final filteredCards = _applyStatusFilters(currentCards, filters);
      state = AsyncData(filteredCards);
      return;
    }

    // Otherwise, perform a full refetch/filter
    talker.debug('Applying full filters from repository.');
    state = const AsyncLoading();

    try {
      _currentFilters = filters;
      final repository = ref.read(cardRepositoryProvider.notifier);
      // Get cards based on non-status filters first
      final baseFilteredCards = await repository.getFilteredCards(
          filters.copyWith(showFavoritesOnly: false, showWishlistOnly: false));
      // Apply status filters locally
      final finalFilteredCards =
          _applyStatusFilters(baseFilteredCards, filters);
      state = AsyncData(finalFilteredCards);
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      state = AsyncError(e, stack);
    }
  }

  // Helper function to apply favorite/wishlist filters locally
  List<models.Card> _applyStatusFilters(
      List<models.Card> cards, CardFilters filters) {
    List<models.Card> result = cards;
    if (filters.showFavoritesOnly) {
      final favorites = ref.read(favoritesProvider);
      result = result
          .where((card) => favorites.contains(card.productId.toString()))
          .toList();
      talker.debug('Filtered by favorites: ${result.length} cards remaining.');
    }
    if (filters.showWishlistOnly) {
      final wishlist = ref.read(wishlistProvider);
      result = result
          .where((card) => wishlist.contains(card.productId.toString()))
          .toList();
      talker.debug('Filtered by wishlist: ${result.length} cards remaining.');
    }
    return result;
  }

  /// Refresh the card list from the repository
  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      // Reset to default sort, but keep status filters if they were active
      final previousFilters = _currentFilters ?? ref.read(cardFilterProvider);
      _currentFilters = CardFilters(
        sortField: 'number',
        sortDescending: false,
        showFavoritesOnly: previousFilters?.showFavoritesOnly ??
            false, // Keep status w/ null check
        showWishlistOnly: previousFilters?.showWishlistOnly ??
            false, // Keep status w/ null check
        // Keep other filters as default or consider persisting them too?
        // For now, only keeping status filters on refresh.
      );

      final repository = ref.read(cardRepositoryProvider.notifier);
      // Fetch all cards (or based on minimal default filters if needed)
      final cards = await repository.getCards(
          filters:
              const CardFilters(sortField: 'number', sortDescending: false));
      // Apply the potentially active status filters
      final finalCards = _applyStatusFilters(cards, _currentFilters!);
      state = AsyncData(finalCards);
    } catch (error, stack) {
      talker.error('Error refreshing cards', error, stack);
      state = AsyncError(error, stack);
    }
  }
}

/// Completely rewritten search implementation to fix progressive search issues
@riverpod
class CardSearchNotifier extends _$CardSearchNotifier {
  Timer? _debounceTimer;
  String? _lastQuery;

  @override
  FutureOr<List<models.Card>> build(String query) async {
    // For empty queries, return empty results immediately
    if (query.isEmpty) return [];

    // Always set loading state when the query changes
    if (_lastQuery != query) {
      _lastQuery = query;
      state = const AsyncLoading();

      // Clear any existing search cache for this query to ensure fresh results
      final cardCache = await ref.read(cardCacheNotifierProvider.future);
      await cardCache.clearSearchCache();
    }

    try {
      // Cancel any pending debounce timer
      _debounceTimer?.cancel();

      // Create a completer to handle the async result
      final completer = Completer<List<models.Card>>();

      // Use a shorter debounce time (100ms) to be more responsive during typing
      _debounceTimer = Timer(const Duration(milliseconds: 100), () async {
        try {
          // Always perform a fresh search for each query
          final results = await ref
              .read(cardRepositoryProvider.notifier)
              .searchCards(query);

          // Apply status filters to search results
          final currentFilters =
              ref.read(cardFilterProvider); // Read current filters
          final finalResults =
              _applyStatusFiltersToSearch(results, currentFilters);

          // Update state with the search results
          state = AsyncData(finalResults);
          completer.complete(finalResults);
        } catch (e, stack) {
          talker.error('Error performing search', e, stack);
          state = AsyncError(e, stack);
          completer.completeError(e, stack);
        }
      });

      return completer.future;
    } catch (error, stack) {
      talker.error('Error searching cards', error, stack);
      return [];
    }
  }

  // Helper function to apply favorite/wishlist filters locally to search results
  List<models.Card> _applyStatusFiltersToSearch(
      List<models.Card> cards, CardFilters filters) {
    List<models.Card> result = cards;
    if (filters.showFavoritesOnly) {
      final favorites = ref.read(favoritesProvider);
      result = result
          .where((card) => favorites.contains(card.productId.toString()))
          .toList();
    }
    if (filters.showWishlistOnly) {
      final wishlist = ref.read(wishlistProvider);
      result = result
          .where((card) => wishlist.contains(card.productId.toString()))
          .toList();
    }
    return result;
  }
}

// Convenience provider that uses the notifier
@riverpod
Future<List<models.Card>> cardSearch(ref, String query) async {
  return ref.watch(cardSearchNotifierProvider(query).future);
}
