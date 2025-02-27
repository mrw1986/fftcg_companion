// lib/features/cards/presentation/providers/set_card_count_provider.dart
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/repositories.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'set_card_count_provider.g.dart';

/// Global cache for set card counts to persist across app sessions
class SetCardCountsCache {
  static const String _boxName = 'set_card_counts';
  static Box<Map>? _box;

  /// Initialize the cache
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Map>(_boxName);
      talker.debug('Initialized set card counts cache');
    } catch (e, stack) {
      talker.error('Failed to initialize set card counts cache', e, stack);
    }
  }

  /// Store counts for a set
  static Future<void> storeSetCounts(
      String setId, Map<String, int> counts) async {
    try {
      await _box?.put(setId, counts);
    } catch (e) {
      talker.debug('Could not store set counts: $e');
    }
  }

  /// Get counts for a set
  static Map<String, int>? getSetCounts(String setId) {
    try {
      final data = _box?.get(setId);
      if (data != null) {
        return Map<String, int>.from(data);
      }
    } catch (e) {
      talker.debug('Could not get set counts: $e');
    }
    return null;
  }

  /// Clear the cache
  static Future<void> clear() async {
    try {
      await _box?.clear();
    } catch (e) {
      talker.debug('Could not clear set counts cache: $e');
    }
  }
}

/// Provider for getting filtered card counts for a specific set
@riverpod
class FilteredSetCardCount extends _$FilteredSetCardCount {
  @override
  Future<int> build(String setId, CardFilters filters) async {
    return ErrorBoundary.runAsync(
      () async {
        final cardRepository = ref.watch(cardRepositoryProvider.notifier);

        try {
          // Use the already loaded cards from the repository instead of making a new query
          final allCards = await ref.watch(cardRepositoryProvider.future);

          // Filter cards that belong to this set
          final setCards =
              allCards.where((card) => card.set.contains(setId)).toList();

          // Apply current filters to these cards
          final filteredCards =
              cardRepository.applyLocalFilters(setCards, filters);

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

/// Cached provider for filtered set card counts with persistent storage
@Riverpod(keepAlive: true)
class FilteredSetCardCountCache extends _$FilteredSetCardCountCache {
  // In-memory cache for the current session
  final _memoryCache = <String, Map<String, int>>{};

  // Flag to track if we've preloaded counts for all sets
  bool _hasPreloadedAllSets = false;

  @override
  Future<int> build(String setId) async {
    // Watch the current filters to update counts when filters change
    final filters = ref.watch(filterProvider);
    final cacheKey = _getCacheKey(filters);

    // Store previous state to avoid flickering when toggling sets
    final previousState = state;

    // Check if we're toggling a set filter
    final isTogglingSet = ref.read(filterProvider.notifier).isTogglingSet;

    // Check in-memory cache first (fastest)
    if (_memoryCache.containsKey(setId) &&
        _memoryCache[setId]!.containsKey(cacheKey)) {
      return _memoryCache[setId]![cacheKey]!;
    }

    // Check persistent cache next (still fast)
    final persistentCache = SetCardCountsCache.getSetCounts(setId);
    if (persistentCache != null && persistentCache.containsKey(cacheKey)) {
      // Update memory cache
      _memoryCache[setId] = {
        ..._memoryCache[setId] ?? {},
        cacheKey: persistentCache[cacheKey]!,
      };
      return persistentCache[cacheKey]!;
    }

    // If we're toggling a set and have a previous value, return it immediately
    // and update the cache asynchronously to avoid UI flickering
    if (isTogglingSet && previousState.hasValue) {
      // Start async update without waiting for it
      _updateCacheAsync(setId, filters, cacheKey);
      return previousState.value!;
    }

    // Get fresh count
    final count = await ref.watch(
      filteredSetCardCountProvider(setId, filters).future,
    );

    // Update both caches
    _memoryCache[setId] = {
      ..._memoryCache[setId] ?? {},
      cacheKey: count,
    };

    // Update persistent cache
    final existingCounts = SetCardCountsCache.getSetCounts(setId) ?? {};
    await SetCardCountsCache.storeSetCounts(setId, {
      ...existingCounts,
      cacheKey: count,
    });

    return count;
  }

  // Update cache asynchronously to avoid UI flickering
  Future<void> _updateCacheAsync(
      String setId, CardFilters filters, String cacheKey) async {
    try {
      final count = await ref.read(
        filteredSetCardCountProvider(setId, filters).future,
      );

      // Update memory cache
      _memoryCache[setId] = {
        ..._memoryCache[setId] ?? {},
        cacheKey: count,
      };

      // Update persistent cache
      final existingCounts = SetCardCountsCache.getSetCounts(setId) ?? {};
      await SetCardCountsCache.storeSetCounts(setId, {
        ...existingCounts,
        cacheKey: count,
      });

      // Only notify if the count has changed
      if (state.hasValue && state.value != count) {
        ref.invalidateSelf();
      }
    } catch (e, stack) {
      talker.error('Error updating cache asynchronously', e, stack);
    }
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
    _memoryCache.clear();
    ref.invalidateSelf();
  }

  /// Preload counts for all sets with the current filters
  /// This can be called during app initialization to warm up the cache
  Future<void> preloadAllSetCounts(
      List<String> allSetIds, CardFilters filters) async {
    if (_hasPreloadedAllSets) return;

    try {
      final cardRepository = ref.read(cardRepositoryProvider.notifier);
      final allCards = await ref.read(cardRepositoryProvider.future);
      final cacheKey = _getCacheKey(filters);

      // Process all sets in a single pass through the cards
      final Map<String, List<Card>> cardsBySet = {};

      // Group cards by set
      for (final card in allCards) {
        for (final setId in card.set) {
          if (!cardsBySet.containsKey(setId)) {
            cardsBySet[setId] = [];
          }
          cardsBySet[setId]!.add(card);
        }
      }

      // Calculate and cache counts for each set
      for (final setId in allSetIds) {
        final setCards = cardsBySet[setId] ?? [];
        final filteredCards =
            cardRepository.applyLocalFilters(setCards, filters);
        final count = filteredCards.length;

        // Update memory cache
        _memoryCache[setId] = {
          ..._memoryCache[setId] ?? {},
          cacheKey: count,
        };

        // Update persistent cache
        final existingCounts = SetCardCountsCache.getSetCounts(setId) ?? {};
        await SetCardCountsCache.storeSetCounts(setId, {
          ...existingCounts,
          cacheKey: count,
        });
      }

      _hasPreloadedAllSets = true;
      talker.debug('Preloaded counts for all sets');
    } catch (e, stack) {
      talker.error('Error preloading set counts', e, stack);
    }
  }
}

/// Provider to preload all set counts during app initialization
@riverpod
Future<void> preloadSetCounts(ref) async {
  try {
    // Initialize the persistent cache
    await SetCardCountsCache.initialize();

    // Get all set IDs from filter options
    final filterOptions = await ref.watch(filterOptionsNotifierProvider.future);
    final allSetIds = filterOptions.set.toList();

    // Preload counts for each set individually
    // This is a workaround since we can't directly access the notifier
    for (final setId in allSetIds) {
      // Force load each set to populate the cache
      await ref.read(filteredSetCardCountCacheProvider(setId).future);
    }

    talker.debug('Preloaded set counts for ${allSetIds.length} sets');
  } catch (e, stack) {
    talker.error('Error in preloadSetCounts', e, stack);
  }
}
