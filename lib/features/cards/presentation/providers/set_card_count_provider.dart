// lib/features/cards/presentation/providers/set_card_count_provider.dart
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/repositories.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart';

part 'set_card_count_provider.g.dart';

/// Provider for getting filtered card counts for a specific set
@riverpod
class FilteredSetCardCount extends _$FilteredSetCardCount {
  @override
  Future<int> build(String setId, CardFilters filters) async {
    return ErrorBoundary.runAsync(
      () async {
        final firestoreService = ref.watch(firestoreServiceProvider);
        final cardRepository = ref.watch(cardRepositoryProvider.notifier);

        try {
          // Get all cards for this set
          final query = firestoreService.cardsCollection
              .where('set', arrayContains: setId);
          final snapshot = await query.get();
          final cards = snapshot.docs
              .map((doc) => Card.fromFirestore(doc.data()))
              .toList();

          // Apply current filters to these cards
          final filteredCards =
              cardRepository.applyLocalFilters(cards, filters);

          return filteredCards.length;
        } catch (e, stack) {
          talker.error(
              'Error getting filtered card count for set $setId', e, stack);
          return 0;
        }
      },
      context: 'filteredSetCardCount($setId)',
      fallback: 0,
    );
  }
}

/// Cached provider for filtered set card counts
@Riverpod(keepAlive: true)
class FilteredSetCardCountCache extends _$FilteredSetCardCountCache {
  final _cache = <String, Map<String, int>>{};

  @override
  Future<int> build(String setId) async {
    // Watch the current filters to update counts when filters change
    final filters = ref.watch(filterProvider);
    final cacheKey = _getCacheKey(filters);

    // Check cache first
    if (_cache.containsKey(setId) && _cache[setId]!.containsKey(cacheKey)) {
      return _cache[setId]![cacheKey]!;
    }

    // Get fresh count
    final count = await ref.watch(
      filteredSetCardCountProvider(setId, filters).future,
    );

    // Update cache
    _cache[setId] = {
      ..._cache[setId] ?? {},
      cacheKey: count,
    };

    return count;
  }

  String _getCacheKey(CardFilters filters) {
    // Create a unique key based on filter values
    return [
      ...filters.elements,
      ...filters.types,
      ...filters.rarities,
      filters.minCost?.toString() ?? '',
      filters.maxCost?.toString() ?? '',
      filters.minPower?.toString() ?? '',
      filters.maxPower?.toString() ?? '',
      filters.showSealedProducts.toString(),
    ].join('|');
  }

  void invalidateCache() {
    _cache.clear();
    ref.invalidateSelf();
  }
}
