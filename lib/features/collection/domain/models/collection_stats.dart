// lib/features/collection/domain/models/collection_stats.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection_stats.freezed.dart';
part 'collection_stats.g.dart';

@freezed
class CollectionStats with _$CollectionStats {
  const factory CollectionStats({
    required int totalCards,
    required int uniqueCards,
    required Map<String, int> elementDistribution,
    required Map<String, int> typeDistribution,
    required Map<String, int> rarityDistribution,
    required Map<String, int> setDistribution,
    required int foilCount,
    required int normalCount,
    required double collectionCompleteness,
    required double estimatedValue,
  }) = _CollectionStats;

  factory CollectionStats.fromJson(Map<String, dynamic> json) =>
      _$CollectionStatsFromJson(json);
}
