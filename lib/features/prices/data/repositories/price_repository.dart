import 'package:fftcg_companion/core/services/firestore_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/repositories.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'price_repository.g.dart';

@Riverpod(keepAlive: true)
class PriceRepository extends _$PriceRepository {
  late final Box<Price> _priceBox;
  late final FirestoreService _firestoreService;

  @override
  FutureOr<void> build() async {
    _priceBox = Hive.box('prices');
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

  Stream<List<HistoricalPrice>> watchHistoricalPrices(String cardId) {
    try {
      return _firestoreService.historicalPricesCollection
          .where('productId', isEqualTo: int.parse(cardId))
          .orderBy('date', descending: true)
          .limit(FirestoreService.maxQueryLimit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => HistoricalPrice.fromFirestore(doc.data()))
              .toList());
    } catch (e, stack) {
      talker.error(
          'Error watching historical prices for card: $cardId', e, stack);
      return Stream.value([]);
    }
  }
}
