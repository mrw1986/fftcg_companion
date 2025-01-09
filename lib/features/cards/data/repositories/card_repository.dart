// lib/features/cards/data/repositories/card_repository.dart
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/services/firestore_service.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'card_repository.g.dart';

@Riverpod(keepAlive: true)
class CardRepository extends _$CardRepository {
  static const int prefetchLimit = 50;
  final _prefetchCache = <String, Card>{};
  bool _isPrefetching = false;
  Box<Card>? _cardBox;
  late final FirestoreService _firestoreService;

  @override
  FutureOr<void> build() async {
    _firestoreService = ref.watch(firestoreServiceProvider);
    await _initBox();
  }

  Future<void> _initBox() async {
    if (_cardBox != null) return;

    try {
      if (!Hive.isBoxOpen('cards')) {
        await Hive.deleteBoxFromDisk('cards');
        await Hive.openBox<Card>('cards');
      }
      _cardBox = Hive.box<Card>('cards');
    } catch (error, stack) {
      talker.error('Error initializing card box', error, stack);
      await Hive.deleteBoxFromDisk('cards');
      await Hive.openBox<Card>('cards');
      _cardBox = Hive.box<Card>('cards');
    }
  }

  Future<List<Card>> getCards({
    int limit = 50,
    String? startAfterId,
    bool forceRefresh = false,
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

  Future<List<Card>> prefetchNextBatch(String lastCardId) async {
    if (_isPrefetching) return [];

    try {
      _isPrefetching = true;
      final cards = await _firestoreService.getCards(
        limit: prefetchLimit,
        startAfterId: lastCardId,
      );

      for (final card in cards) {
        _prefetchCache[card.productId.toString()] = card;
      }

      return cards;
    } catch (error, stack) {
      talker.error('Error prefetching cards', error, stack);
      return [];
    } finally {
      _isPrefetching = false;
    }
  }

  Future<List<Card>> getCardsFromCache(List<String> ids) async {
    return ids
        .map((id) => _prefetchCache[id])
        .where((card) => card != null)
        .cast<Card>()
        .toList();
  }

  void clearPrefetchCache() {
    _prefetchCache.clear();
  }

  Future<Card?> getCard(String id, {bool forceRefresh = false}) async {
    await _initBox();

    talker.debug('Getting card with ID: $id, forceRefresh: $forceRefresh');

    if (!forceRefresh) {
      final cached = _cardBox?.get(id);
      if (cached != null) {
        talker.debug('Found cached card: ${cached.toJson()}');
        return cached;
      }
    }

    talker.debug('Fetching card from Firestore');
    final card = await _firestoreService.getCard(id);
    talker.debug('Firestore response: ${card?.toJson()}');

    if (card != null) {
      await _cardBox?.put(id, card);
      talker.debug('Card stored in Hive box');
    }

    return card;
  }

  Future<void> dispose() async {
    await _cardBox?.close();
    _cardBox = null;
    clearPrefetchCache();
  }

  Future<List<Card>> getFilteredCards(CardFilters filters) async {
    await _initBox();

    List<Card> cards = _cardBox?.values.toList() ?? [];

    return cards.where((card) {
      // Apply filters
      if (filters.elements.isNotEmpty &&
          !filters.elements.contains(card.extendedData['Element']?.value)) {
        return false;
      }

      if (filters.types.isNotEmpty &&
          !filters.types.contains(card.extendedData['Type']?.value)) {
        return false;
      }

      if (filters.sets.isNotEmpty &&
          !filters.sets.contains(card.extendedData['Set']?.value)) {
        return false;
      }

      if (filters.rarities.isNotEmpty &&
          !filters.rarities.contains(card.extendedData['Rarity']?.value)) {
        return false;
      }

      final cost = int.tryParse(card.extendedData['Cost']?.value ?? '') ?? 0;
      if (filters.minCost != null && cost < filters.minCost!) return false;
      if (filters.maxCost != null && cost > filters.maxCost!) return false;

      final power = int.tryParse(card.extendedData['Power']?.value ?? '') ?? 0;
      if (filters.minPower != null && power < filters.minPower!) return false;
      if (filters.maxPower != null && power > filters.maxPower!) return false;

      if (filters.searchText?.isNotEmpty ?? false) {
        final searchLower = filters.searchText!.toLowerCase();
        return card.name.toLowerCase().contains(searchLower) ||
            card.cleanName.toLowerCase().contains(searchLower) ||
            card.cardNumbers
                .any((number) => number.toLowerCase().contains(searchLower));
      }

      return true;
    }).toList();
  }
}
