// lib/core/storage/cached_card_adapter.dart
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@HiveType(typeId: 10)
class CachedCard extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final Map<String, dynamic> data;

  @HiveField(2)
  final DateTime cacheTime;

  CachedCard({
    required this.id,
    required this.data,
    required this.cacheTime,
  });

  factory CachedCard.fromSnapshot(DocumentSnapshot snapshot) {
    return CachedCard(
      id: snapshot.id,
      data: snapshot.data() as Map<String, dynamic>,
      cacheTime: DateTime.now(),
    );
  }
}

class CachedCardAdapter extends TypeAdapter<CachedCard> {
  @override
  final int typeId = 10;

  @override
  CachedCard read(BinaryReader reader) {
    return CachedCard(
      id: reader.read(),
      data: Map<String, dynamic>.from(reader.read()),
      cacheTime: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, CachedCard obj) {
    writer.write(obj.id);
    writer.write(obj.data);
    writer.write(obj.cacheTime);
  }
}
