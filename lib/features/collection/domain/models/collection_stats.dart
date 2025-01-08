import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'collection_stats.freezed.dart';
part 'collection_stats.g.dart';

@freezed
@HiveType(typeId: 7)
class CollectionStats with _$CollectionStats {
  const factory CollectionStats({
    @HiveField(0) required int totalCards,
    @HiveField(1) required int uniqueCards,
    @HiveField(2) required Map<String, int> elementDistribution,
    @HiveField(3) required Map<String, int> typeDistribution,
    @HiveField(4) required Map<String, int> rarityDistribution,
    @HiveField(5) required Map<String, int> setDistribution,
    @HiveField(6) required int foilCount,
    @HiveField(7) required int normalCount,
    @HiveField(8) required double collectionCompleteness,
    @HiveField(9) required double estimatedValue,
  }) = _CollectionStats;

  factory CollectionStats.fromJson(Map<String, dynamic> json) =>
      _$CollectionStatsFromJson(json);
}
