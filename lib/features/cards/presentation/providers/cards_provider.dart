import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';

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
    return cards;
  }

  /// Apply new filters to the card list
  Future<void> applyFilters(CardFilters filters) async {
    if (_currentFilters == filters) return;

    state = const AsyncLoading();

    try {
      _currentFilters = filters;
      final repository = ref.read(cardRepositoryProvider.notifier);
      final cards = await repository.getFilteredCards(filters);
      state = AsyncData(cards);
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      state = AsyncError(e, stack);
    }
  }

  /// Refresh the card list from the repository
  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      // Reset to default sort
      _currentFilters = const CardFilters(
        sortField: 'number',
        sortDescending: false,
      );

      final repository = ref.read(cardRepositoryProvider.notifier);
      final cards = await repository.getCards(filters: _currentFilters);
      state = AsyncData(cards);
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

          // Update state with the search results
          state = AsyncData(results);
          completer.complete(results);
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
}

// Convenience provider that uses the notifier
@riverpod
Future<List<models.Card>> cardSearch(ref, String query) async {
  return ref.watch(cardSearchNotifierProvider(query).future);
}
