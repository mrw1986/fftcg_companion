import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'cards_provider.g.dart';

@riverpod
class SortingProgress extends _$SortingProgress {
  @override
  bool build() => false;

  void start() => state = true;
  void complete() => state = false;
}

@Riverpod(keepAlive: true)
class CardsNotifier extends _$CardsNotifier {
  static const int batchSize = 50;
  CardFilters? _currentFilters;
  final _loadedCards = <models.Card>[];
  bool _isLoadingMore = false;

  @override
  Future<List<models.Card>> build() async {
    // Wait for CardRepository to initialize
    await ref.read(cardRepositoryProvider.future);

    // Set default sort to Card Number (Ascending)
    _currentFilters = const CardFilters(
      sortField: 'number',
      sortDescending: false,
    );

    return _loadInitialBatch();
  }

  Future<List<models.Card>> _loadInitialBatch() async {
    try {
      final repository = ref.read(cardRepositoryProvider.notifier);
      var cards = await repository.getCards(
        limit: batchSize,
        filters: _currentFilters,
      );

      _loadedCards.clear();
      _loadedCards.addAll(cards);

      talker.debug('Loaded initial batch of ${cards.length} cards');
      return cards;
    } catch (error, stack) {
      talker.error('Error loading initial batch', error, stack);
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasValue) return;
    if (_loadedCards.isEmpty) return;

    try {
      _isLoadingMore = true;
      final repository = ref.read(cardRepositoryProvider.notifier);

      final lastCardId = _loadedCards.last.productId.toString();
      var newCards = await repository.getCards(
        limit: batchSize,
        startAfterId: lastCardId,
        filters: _currentFilters,
      );

      if (newCards.isNotEmpty) {
        _loadedCards.addAll(newCards);
        state = AsyncValue.data([..._loadedCards]);
      }
    } catch (error, stack) {
      talker.error('Error loading more cards', error, stack);
      state = AsyncValue.error(error, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> applyFilters(CardFilters filters) async {
    // Check if only reapplying the same sort
    final isSameSort = _currentFilters?.sortField == filters.sortField &&
        _currentFilters?.sortDescending == filters.sortDescending;
    final onlySortChanged = _currentFilters != null &&
        _currentFilters!.copyWith(
              sortField: filters.sortField,
              sortDescending: filters.sortDescending,
            ) ==
            filters;

    // If it's the exact same filters, do nothing
    if (_currentFilters == filters) return;

    // If only reapplying the same sort, don't reload
    if (isSameSort && onlySortChanged && state.hasValue) {
      _currentFilters = filters;
      return;
    }

    ref.read(sortingProgressProvider.notifier).start();
    state = const AsyncValue.loading();

    try {
      _currentFilters = filters;
      final repository = ref.read(cardRepositoryProvider.notifier);
      final filteredCards = await repository.getFilteredCards(filters);

      _loadedCards.clear();
      _loadedCards.addAll(filteredCards);

      state = AsyncValue.data(filteredCards);
      talker.debug(
          'Applied filters successfully. Found ${filteredCards.length} cards');
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      state = AsyncValue.error(e, stack);
    } finally {
      ref.read(sortingProgressProvider.notifier).complete();
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _loadedCards.clear();
    _isLoadingMore = false;

    // Reset to default sort (Card Number Ascending)
    _currentFilters = const CardFilters(
      sortField: 'number',
      sortDescending: false,
    );

    state = await AsyncValue.guard(_loadInitialBatch);
  }
}

final _searchCache = <String, List<models.Card>>{};
Timer? _searchDebounceTimer;
Object? _searchDebounceKey;

@riverpod
Future<List<models.Card>> cardSearch(ref, String query) async {
  if (query.isEmpty) return [];

  // Check cache first
  if (_searchCache.containsKey(query)) {
    return _searchCache[query]!;
  }

  // Create a unique key for this search request
  final searchKey = Object();
  ref.keepAlive();

  // Set this as the current search request
  _searchDebounceKey = searchKey;

  // Debounce the search
  _searchDebounceTimer?.cancel();
  await Future.delayed(const Duration(milliseconds: 300));

  // If this is no longer the current search request, cancel it
  if (searchKey != _searchDebounceKey) {
    return [];
  }

  try {
    final results =
        await ref.read(cardRepositoryProvider.notifier).searchCards(query);

    // If this is no longer the current search request, cancel it
    if (searchKey != _searchDebounceKey) {
      return [];
    }

    // Cache the results
    if (results.isNotEmpty) {
      _searchCache[query] = results;

      // Clear old cache entries if cache gets too large
      if (_searchCache.length > 50) {
        final oldestKeys =
            _searchCache.keys.take(_searchCache.length - 50).toList();
        for (final key in oldestKeys) {
          _searchCache.remove(key);
        }
      }
    }

    return results;
  } catch (error, stack) {
    talker.error('Error searching cards', error, stack);
    return [];
  }
}
