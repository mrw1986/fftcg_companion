// lib/features/cards/presentation/providers/cards_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart'
    as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';

part 'cards_provider.g.dart';

@Riverpod(keepAlive: true)
class CardsNotifier extends _$CardsNotifier {
  @override
  Future<List<models.Card>> build() async {
    final repository = ref.watch(cardRepositoryProvider.notifier);
    return repository.getCards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(cardRepositoryProvider.notifier).getCards(forceRefresh: true));
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasValue) return;

    final currentCards = state.value!;
    if (currentCards.isEmpty) return;

    final lastCardId = currentCards.last.productId.toString();

    try {
      state = AsyncValue.data([
        ...currentCards,
        ...await ref.read(cardRepositoryProvider.notifier).getCards(
              limit: 20,
              startAfterId: lastCardId,
            ),
      ]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> applyFilters(CardFilters filters) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(cardRepositoryProvider.notifier).getFilteredCards(filters));
  }
}

@riverpod
Future<List<models.Card>> cardSearch(ref, String query) async {
  if (query.isEmpty) return [];
  return AsyncValue.guard(
          () => ref.read(cardRepositoryProvider.notifier).searchCards(query))
      .then((value) => value.value ?? []);
}
