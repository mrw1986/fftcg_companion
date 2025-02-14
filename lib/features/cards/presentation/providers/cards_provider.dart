import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

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
