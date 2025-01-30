// lib/features/prices/domain/models/price_hive_adapter.dart

import 'package:hive_ce/hive.dart';
import 'package:fftcg_companion/features/prices/domain/models/price.dart';
import 'package:fftcg_companion/features/prices/domain/models/historical_price.dart';

@HiveType(typeId: 2)
class PriceAdapter extends TypeAdapter<Price> {
  @override
  final int typeId = 2;

  @override
  Price read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return Price.fromFirestore(map);
  }

  @override
  void write(BinaryWriter writer, Price obj) {
    writer.writeMap(obj.toFirestore());
  }
}

@HiveType(typeId: 3)
class PriceDataAdapter extends TypeAdapter<PriceData> {
  @override
  final int typeId = 3;

  @override
  PriceData read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return PriceData.fromFirestore(map);
  }

  @override
  void write(BinaryWriter writer, PriceData obj) {
    writer.writeMap(obj.toFirestore());
  }
}

@HiveType(typeId: 4)
class HistoricalPriceAdapter extends TypeAdapter<HistoricalPrice> {
  @override
  final int typeId = 4;

  @override
  HistoricalPrice read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return HistoricalPrice.fromFirestore(map);
  }

  @override
  void write(BinaryWriter writer, HistoricalPrice obj) {
    writer.writeMap(obj.toFirestore());
  }
}

@HiveType(typeId: 5)
class HistoricalPriceDataAdapter extends TypeAdapter<HistoricalPriceData> {
  @override
  final int typeId = 5;

  @override
  HistoricalPriceData read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return HistoricalPriceData.fromFirestore(map);
  }

  @override
  void write(BinaryWriter writer, HistoricalPriceData obj) {
    writer.writeMap(obj.toFirestore());
  }
}
