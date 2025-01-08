// lib/core/storage/hive_adapters.dart
import 'package:hive/hive.dart';
import 'package:fftcg_companion/features/cards/domain/models/card.dart'
    as models;
import 'package:fftcg_companion/features/prices/domain/models/price.dart';
import 'dart:convert';

class CardAdapter extends TypeAdapter<models.Card> {
  @override
  final int typeId = 0;

  @override
  models.Card read(BinaryReader reader) {
    final map = reader.readMap();
    return models.Card.fromJson(map.cast<String, dynamic>());
  }

  @override
  void write(BinaryWriter writer, models.Card obj) {
    // Use jsonEncode/jsonDecode to ensure proper serialization
    final json = jsonEncode(obj.toJson());
    writer.writeMap(jsonDecode(json) as Map);
  }
}

class ExtendedDataAdapter extends TypeAdapter<models.ExtendedData> {
  @override
  final int typeId = 1;

  @override
  models.ExtendedData read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return models.ExtendedData.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, models.ExtendedData obj) {
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
