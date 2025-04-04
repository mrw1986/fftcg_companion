// lib/features/collection/domain/models/collection_stats_hive_adapter.dart

import 'package:hive_ce/hive.dart';
import 'package:fftcg_companion/features/collection/domain/models/collection_stats.dart';
// import 'collection_stats.mapper.dart'; // Removed incorrect import

@HiveType(typeId: 7)
class CollectionStatsAdapter extends TypeAdapter<CollectionStats> {
  @override
  final int typeId = 7;

  @override
  CollectionStats read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    // Use dart_mappable's fromMap
    return CollectionStatsMapper.fromMap(map);
  }

  @override
  void write(BinaryWriter writer, CollectionStats obj) {
    // Use dart_mappable's toMap
    writer.writeMap(obj.toMap());
  }
}
