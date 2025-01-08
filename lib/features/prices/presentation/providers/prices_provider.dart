// lib/features/prices/presentation/providers/prices_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/features/repositories.dart';

part 'prices_provider.g.dart';

@riverpod
class PriceNotifier extends _$PriceNotifier {
  @override
  FutureOr<Price?> build(String cardId) {
    return ref.watch(priceRepositoryProvider.notifier).getPrice(cardId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(priceRepositoryProvider.notifier).getPrice(
              state.value?.productId.toString() ?? '',
              forceRefresh: true,
            ));
  }
}

@riverpod
Stream<List<HistoricalPrice>> historicalPrices(
  ref,
  String cardId,
) {
  return ref
      .watch(priceRepositoryProvider.notifier)
      .watchHistoricalPrices(cardId);
}
