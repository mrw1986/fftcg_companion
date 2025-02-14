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

Timer? _searchDebounceTimer;
Object? _searchDebounceKey;

@riverpod
Future<List<models.Card>> cardSearch(ref, String query) async {
  if (query.isEmpty) return [];

  try {
    // Check cache first before any debouncing
    final cardCache = await ref.read(cardCacheNotifierProvider.future);
    final cachedResults = await cardCache.getCachedSearchResults(query);
    if (cachedResults != null) {
      talker.debug('Using cached search results for query: $query');
      return cachedResults;
    }

    // Only debounce network requests
    final searchKey = Object();
    ref.keepAlive();
    _searchDebounceKey = searchKey;

    _searchDebounceTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 300));

    // If this is no longer the current search request, cancel it
    if (searchKey != _searchDebounceKey) {
      return [];
    }

    final results =
        await ref.read(cardRepositoryProvider.notifier).searchCards(query);

    // If this is no longer the current search request, cancel it
    if (searchKey != _searchDebounceKey) {
      return [];
    }

    // Cache the results and all progressive substrings
    if (results.isNotEmpty) {
      await cardCache.cacheSearchResults(query, results);

      // Cache progressive substrings for better partial matching
      if (query.length > 1) {
        for (int i = 1; i < query.length; i++) {
          final substring = query.substring(0, i);
          final substringResults = results.where((card) {
            final name = card.name.toLowerCase();
            final number = card.number?.toLowerCase() ?? '';
            return name.startsWith(substring) ||
                number.startsWith(substring) ||
                card.cardNumbers
                    .any((n) => n.toLowerCase().startsWith(substring));
          }).toList();
          if (substringResults.isNotEmpty) {
            await cardCache.cacheSearchResults(substring, substringResults);
          }
        }
      }
    }

    return results;
  } catch (error, stack) {
    talker.error('Error searching cards', error, stack);
    return [];
  }
}
