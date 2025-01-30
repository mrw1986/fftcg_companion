// lib/features/collection/domain/models/collection_stats_hive_adapter.dart

import 'package:hive_ce/hive.dart';
import 'package:fftcg_companion/features/collection/domain/models/collection_stats.dart';

@HiveType(typeId: 7)
class CollectionStatsAdapter extends TypeAdapter<CollectionStats> {
  @override
  final int typeId = 7;

  @override
  CollectionStats read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return CollectionStats.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, CollectionStats obj) {
    writer.writeMap(obj.toJson());
  }
}
