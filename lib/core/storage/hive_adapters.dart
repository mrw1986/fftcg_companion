// lib/core/storage/hive_adapters.dart
import 'package:hive/hive.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart';
import 'package:fftcg_companion/features/prices/domain/models/price.dart';

class CardAdapter extends TypeAdapter<Card> {
  @override
  final int typeId = 0;

  @override
  Card read(BinaryReader reader) {
    final map = reader.readMap();
    return Card.fromJson(Map<String, dynamic>.from(map));
  }

  @override
  void write(BinaryWriter writer, Card obj) {
    writer.writeMap(Map<String, dynamic>.from(obj.toJson()));
  }
}

class ExtendedDataAdapter extends TypeAdapter<ExtendedData> {
  @override
  final int typeId = 1;

  @override
  ExtendedData read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return ExtendedData.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, ExtendedData obj) {
    writer.writeMap(obj.toJson());
  }
}

class PriceAdapter extends TypeAdapter<Price> {
  @override
  final int typeId = 2;

  @override
  Price read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return Price.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, Price obj) {
    writer.writeMap(obj.toJson());
  }
}

class PriceDataAdapter extends TypeAdapter<PriceData> {
  @override
  final int typeId = 3;

  @override
  PriceData read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return PriceData.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, PriceData obj) {
    writer.writeMap(obj.toJson());
  }
}

class HistoricalPriceAdapter extends TypeAdapter<HistoricalPrice> {
  @override
  final int typeId = 4;

  @override
  HistoricalPrice read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return HistoricalPrice.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, HistoricalPrice obj) {
    writer.writeMap(obj.toJson());
  }
}

class HistoricalPriceDataAdapter extends TypeAdapter<HistoricalPriceData> {
  @override
  final int typeId = 5;

  @override
  HistoricalPriceData read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return HistoricalPriceData.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, HistoricalPriceData obj) {
    writer.writeMap(obj.toJson());
  }
}
