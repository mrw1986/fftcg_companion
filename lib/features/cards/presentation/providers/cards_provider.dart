// lib/features/cards/presentation/providers/cards_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'cards_provider.g.dart';

@Riverpod(keepAlive: true)
class CardsNotifier extends _$CardsNotifier {
  static const int batchSize = 50;
  final _loadedCards = <models.Card>[];
  bool _isLoadingMore = false;

  @override
  Future<List<models.Card>> build() async {
    state = const AsyncValue.loading();
    return _loadInitialBatch();
  }

  Future<List<models.Card>> _loadInitialBatch() async {
    try {
      final repository = ref.read(cardRepositoryProvider.notifier);
      final cards = await repository.getCards(limit: batchSize);
      _loadedCards.clear();
      _loadedCards.addAll(cards);

      talker.debug('Loaded initial batch of ${cards.length} cards');

      if (cards.isNotEmpty) {
        talker.debug('Starting prefetch for next batch');
        _prefetchNextBatch(cards.last.productId.toString());
      }

      return cards;
    } catch (error, stack) {
      talker.error('Error loading initial batch', error, stack);
      rethrow;
    }
  }

  Future<void> _prefetchNextBatch(String lastCardId) async {
    try {
      final repository = ref.read(cardRepositoryProvider.notifier);
      await repository.prefetchNextBatch(lastCardId);
    } catch (error, stack) {
      talker.error('Error prefetching next batch', error, stack);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !state.hasValue) return;
    if (_loadedCards.isEmpty) return;

    try {
      _isLoadingMore = true;
      final repository = ref.read(cardRepositoryProvider.notifier);

      // Try to get cards from cache first
      final lastCardId = _loadedCards.last.productId.toString();
      final nextBatchIds = List.generate(
        batchSize,
        (i) => (int.parse(lastCardId) + i + 1).toString(),
      );

      var newCards = await repository.getCardsFromCache(nextBatchIds);

      // If cache miss, fetch from Firestore
      if (newCards.isEmpty) {
        newCards = await repository.getCards(
          limit: batchSize,
          startAfterId: lastCardId,
        );
      }

      if (newCards.isNotEmpty) {
        _loadedCards.addAll(newCards);
        state = AsyncValue.data([..._loadedCards]);

        // Prefetch next batch
        _prefetchNextBatch(newCards.last.productId.toString());
      }
    } catch (error, stack) {
      talker.error('Error loading more cards', error, stack);
      state = AsyncValue.error(error, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _loadedCards.clear();
    ref.read(cardRepositoryProvider.notifier).clearPrefetchCache();
    state = await AsyncValue.guard(_loadInitialBatch);
  }

  Future<void> applyFilters(CardFilters filters) async {
    state = const AsyncValue.loading();
    _loadedCards.clear();
    ref.read(cardRepositoryProvider.notifier).clearPrefetchCache();

    try {
      final repository = ref.read(cardRepositoryProvider.notifier);
      final filteredCards = await repository.getFilteredCards(filters);
      _loadedCards.addAll(filteredCards);
      state = AsyncValue.data(filteredCards);
    } catch (error, stack) {
      talker.error('Error applying filters', error, stack);
      state = AsyncValue.error(error, stack);
    }
  }

  Future<void> sort(String sortField) async {
    state = const AsyncValue.loading();
    _loadedCards.clear();
    ref.read(cardRepositoryProvider.notifier).clearPrefetchCache();

    try {
      final repository = ref.read(cardRepositoryProvider.notifier);
      final sortedCards = await repository.getSortedCards(sortField: sortField);
      _loadedCards.addAll(sortedCards);
      state = AsyncValue.data(sortedCards);
    } catch (error, stack) {
      talker.error('Error sorting cards', error, stack);
      state = AsyncValue.error(error, stack);
    }
  }
}

@riverpod
Future<List<models.Card>> cardSearch(ref, String query) async {
  if (query.isEmpty) return [];

  try {
    return await ref.read(cardRepositoryProvider.notifier).searchCards(query);
  } catch (error, stack) {
    talker.error('Error searching cards', error, stack);
    return [];
  }
}
