import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/set_card_count_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';

part 'initialization_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> initialization(ref) async {
  talker.debug('Starting app initialization...');

  ref.onDispose(() {
    talker.debug('Initialization provider disposed');
  });

  ref.onCancel(() {
    talker.debug('Initialization provider cancelled');
  });

  ref.onResume(() {
    talker.debug('Initialization provider resumed');
  });

  // Initialize cache first
  talker.debug('Initializing card cache...');
  final cardCache = await ref.read(cardCacheNotifierProvider.future);
  talker.debug('Card cache initialized');

  // Clear filter options cache to ensure we get fresh categorization with updated set categories
  talker.debug('Clearing caches...');
  await cardCache.clearFilterOptionsCache();
  await SetCardCountsCache.clear();
  talker.debug('Filter options and set count caches cleared');

  // Then initialize repository
  talker.debug('Initializing card repository...');
  final repository = ref.read(cardRepositoryProvider.notifier);
  await repository.initialize();
  talker.debug('Card repository initialized');

  // Preload set card counts in the background by loading a few sets
  // This will speed up the initial filter dialog opening
  try {
    talker.debug('Starting set card count preload...');
    // Get all set IDs from filter options
    final filterOptions = await ref.read(filterOptionsNotifierProvider.future);
    final allSetIds = filterOptions.set.toList();

    // Initialize the persistent cache
    talker.debug('Initializing set card counts cache...');
    await SetCardCountsCache.initialize();
    talker.debug('Set card counts cache initialized');

    // Preload a few sets to warm up the cache
    talker.debug('Preloading first 5 sets: ${allSetIds.take(5).join(", ")}');
    for (final setId in allSetIds.take(5)) {
      // Force load each set to populate the cache
      ref.read(filteredSetCardCountCacheProvider(setId).future).ignore();
    }

    talker.debug('Set card count preload started');
  } catch (e, stack) {
    talker.error('Error preloading set counts', e, stack);
  }

  talker.debug('App initialization completed successfully');
  talker.debug('All initialization steps completed:');
  talker.debug('- Card cache initialized');
  talker.debug('- Filter options and set count caches cleared');
  talker.debug('- Card repository initialized');
  talker.debug('- Set card counts cache initialized');
  talker.debug('- Set card count preload started');
}
