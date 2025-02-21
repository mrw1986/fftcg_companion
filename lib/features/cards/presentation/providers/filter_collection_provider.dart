import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/services/firestore_provider.dart';
import 'package:fftcg_companion/core/services/firestore_service.dart';
import 'package:fftcg_companion/core/storage/hive_provider.dart';
import 'package:fftcg_companion/core/storage/hive_storage.dart';
import 'package:fftcg_companion/features/cards/domain/models/filter_collection.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

const _filterCollectionCacheKey = 'filter_collection_cache';

class FilterCollectionNotifier extends AsyncNotifier<FilterCollection> {
  late final FirestoreService _firestoreService;
  late final HiveStorage _hiveStorage;
  FilterCollection? _memoryCache;

  @override
  Future<FilterCollection> build() async {
    _firestoreService = ref.read(firestoreServiceProvider);
    _hiveStorage = ref.read(hiveStorageProvider);

    return _getFilterCollection();
  }

  Future<FilterCollection> _getFilterCollection() async {
    try {
      // Check memory cache first
      if (_memoryCache != null) {
        return _memoryCache!;
      }

      // Check local storage cache
      final cachedData = await _hiveStorage
          .get<Map<String, dynamic>>(_filterCollectionCacheKey);
      if (cachedData != null) {
        final cache = FilterCollectionCache.fromJson(cachedData);
        _memoryCache = cache.filters;
        return cache.filters;
      }

      // Fetch from Firestore
      final filters = await _fetchFromFirestore();
      await _updateCache(filters);
      return filters;
    } catch (e, st) {
      talker.error(
          '[FilterCollectionNotifier] Error getting filter collection', e, st);

      // Return empty collection on error
      return FilterCollection.empty();
    }
  }

  Future<FilterCollection> _fetchFromFirestore() async {
    final snapshot = await _firestoreService.collection('filters').get();
    final data = snapshot.docs.fold<Map<String, List<String>>>(
      {},
      (map, doc) {
        final values = List<String>.from(doc.data()['values'] ?? []);
        map[doc.id] = values;
        return map;
      },
    );

    return FilterCollection(
      cardType: data['cardType'] ?? [],
      category: data['category'] ?? [],
      cost: data['cost'] ?? [],
      elements: data['elements'] ?? [],
      power: data['power'] ?? [],
      rarity: data['rarity'] ?? [],
      set: data['set'] ?? [],
    );
  }

  Future<void> _updateCache(FilterCollection filters) async {
    _memoryCache = filters;
    final cache = FilterCollectionCache(
      filters: filters,
      lastUpdated: DateTime.now(),
    );
    await _hiveStorage.put(_filterCollectionCacheKey, cache.toJson());
  }

  Future<void> refreshFilters() async {
    state = const AsyncValue.loading();
    try {
      final filters = await _fetchFromFirestore();
      await _updateCache(filters);
      state = AsyncValue.data(filters);
    } catch (e, st) {
      talker.error(
          '[FilterCollectionNotifier] Error refreshing filters', e, st);
      state = AsyncError(e, st);
    }
  }
}

final filterCollectionProvider =
    AsyncNotifierProvider<FilterCollectionNotifier, FilterCollection>(
  () => FilterCollectionNotifier(),
);
