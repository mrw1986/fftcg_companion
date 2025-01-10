// lib/features/prices/data/repositories/price_repository.dart
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_service.dart';
import 'package:fftcg_companion/features/models.dart';

part 'price_repository.g.dart';

@Riverpod(keepAlive: true)
class PriceRepository extends _$PriceRepository {
  late final Box<Price> _priceBox;
  late final Box<HistoricalPrice> _historicalBox;
  late final FirestoreService _firestoreService;

  @override
  FutureOr<void> build() async {
    _priceBox = Hive.box('prices');
    _historicalBox = Hive.box('historical_prices');
    _firestoreService = ref.watch(firestoreServiceProvider);
  }

  Future<Price?> getPrice(String cardId, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _priceBox.get(cardId);
      if (cached != null) return cached;
    }

    final price = await _firestoreService.getPrice(cardId);
    if (price != null) {
      await _priceBox.put(cardId, price);
    }

    return price;
  }

  Future<List<HistoricalPrice>> getCachedHistoricalPrices(String cardId) async {
    return _historicalBox.values
        .where((price) => price.productId.toString() == cardId)
        .toList();
  }
}
