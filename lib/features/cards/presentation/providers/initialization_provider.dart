import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/set_card_count_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';

part 'initialization_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> initialization(ref) async {
  // Initialize cache first
  final cardCache = await ref.read(cardCacheNotifierProvider.future);

  // Clear filter options cache to ensure we get fresh categorization with updated set categories
  await cardCache.clearFilterOptionsCache();
  await SetCardCountsCache.clear();
  talker.debug(
      'Cleared filter options and set count caches during initialization');

  // Then initialize repository
  final repository = ref.read(cardRepositoryProvider.notifier);
  await repository.initialize();

  // Preload set card counts in the background by loading a few sets
  // This will speed up the initial filter dialog opening
  try {
    // Get all set IDs from filter options
    final filterOptions = await ref.read(filterOptionsNotifierProvider.future);
    final allSetIds = filterOptions.set.toList();

    // Initialize the persistent cache
    await SetCardCountsCache.initialize();

    // Preload a few sets to warm up the cache
    for (final setId in allSetIds.take(5)) {
      // Force load each set to populate the cache
      ref.read(filteredSetCardCountCacheProvider(setId).future).ignore();
    }

    talker.debug('Started preloading set card counts');
  } catch (e) {
    talker.debug('Error preloading set counts: $e');
  }
}
