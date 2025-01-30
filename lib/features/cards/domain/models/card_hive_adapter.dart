// lib/features/cards/domain/models/card_hive_adapter.dart
import 'package:hive_ce/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart';

@HiveType(typeId: 0)
class CardAdapter extends TypeAdapter<Card> {
  @override
  final int typeId = 0;

  @override
  Card read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);

    if (convertedMap['lastUpdated'] is DateTime) {
      convertedMap['lastUpdated'] = Timestamp.fromDate(
        convertedMap['lastUpdated'] as DateTime,
      );
    }

    return Card.fromFirestore(convertedMap);
  }

  @override
  void write(BinaryWriter writer, Card obj) {
    final Map<String, dynamic> map = obj.toFirestore();
    if (map['lastUpdated'] is Timestamp) {
      map['lastUpdated'] = (map['lastUpdated'] as Timestamp).toDate();
    }
    writer.writeMap(map);
  }
}
