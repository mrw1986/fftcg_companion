// lib/features/cards/data/repositories/card_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_service.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart'
    as models;
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';

part 'card_repository.g.dart';

@Riverpod(keepAlive: true)
class CardRepository extends _$CardRepository {
  Box<models.Card>? _cardBox;
  late final FirestoreService _firestoreService;

  @override
  FutureOr<void> build() async {
    _firestoreService = ref.watch(firestoreServiceProvider);
    await _initBox();
  }

  Future<void> _initBox() async {
    if (_cardBox != null) return;

    if (!Hive.isBoxOpen('cards')) {
      await Hive.openBox<models.Card>('cards');
    }
    _cardBox = Hive.box<models.Card>('cards');
  }

  Future<List<models.Card>> getCards({
    int limit = 20,
    String? startAfterId,
    bool forceRefresh = false,
    Query<Object?>? Function(Query<Object?> query)? queryBuilder,
  }) async {
    await _initBox();

    if (startAfterId == null && !forceRefresh) {
      final box = _cardBox;
      if (box != null && box.values.isNotEmpty) {
        return box.values.take(limit).toList();
      }
    }

    final cards = await _firestoreService.getCards(
      limit: limit,
      startAfterId: startAfterId,
      queryBuilder: queryBuilder,
    );

    if (startAfterId == null) {
      final box = _cardBox;
      if (box != null) {
        await box.clear();
        await box
            .putAll({for (var card in cards) card.productId.toString(): card});
      }
    }

    return cards;
  }

  Future<models.Card?> getCard(String id, {bool forceRefresh = false}) async {
    await _initBox();

    if (!forceRefresh) {
      final box = _cardBox;
      if (box != null) {
        final cached = box.get(id);
        if (cached != null) return cached;
      }
    }

    final card = await _firestoreService.getCard(id);
    if (card != null) {
      await _cardBox?.put(id, card);
    }

    return card;
  }

  Future<List<models.Card>> searchCards(String query) async {
    await _initBox();

    final box = _cardBox;
    if (box != null) {
      final cachedResults = box.values
          .where((card) => card.cleanName.contains(query.toLowerCase()))
          .toList();

      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }
    }

    return _firestoreService.searchCards(query);
  }

  Future<List<models.Card>> getFilteredCards(CardFilters filters) async {
    return _firestoreService.getCards(
      queryBuilder: (query) {
        if (filters.elements.isNotEmpty) {
          query = query.where('extendedData.Element.value',
              whereIn: filters.elements.toList());
        }
        if (filters.types.isNotEmpty) {
          query = query.where('extendedData.Type.value',
              whereIn: filters.types.toList());
        }
        // ... rest of the filter logic
        return query;
      },
    );
  }

  Future<void> clearCache() async {
    await _cardBox?.clear();
  }

  Future<void> dispose() async {
    await _cardBox?.close();
    _cardBox = null;
  }
}
