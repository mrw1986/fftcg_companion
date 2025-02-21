import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter_collection.freezed.dart';
part 'filter_collection.g.dart';

@freezed
class FilterCollection with _$FilterCollection {
  const factory FilterCollection({
    required List<String> cardType,
    required List<String> category,
    required List<String> cost,
    required List<String> elements,
    required List<String> power,
    required List<String> rarity,
    required List<String> set,
  }) = _FilterCollection;

  factory FilterCollection.fromJson(Map<String, dynamic> json) =>
      _$FilterCollectionFromJson(json);

  factory FilterCollection.empty() => const FilterCollection(
        cardType: [],
        category: [],
        cost: [],
        elements: [],
        power: [],
        rarity: [],
        set: [],
      );
}

@freezed
class FilterCollectionCache with _$FilterCollectionCache {
  const factory FilterCollectionCache({
    required FilterCollection filters,
    required DateTime lastUpdated,
  }) = _FilterCollectionCache;

  factory FilterCollectionCache.fromJson(Map<String, dynamic> json) =>
      _$FilterCollectionCacheFromJson(json);
}
