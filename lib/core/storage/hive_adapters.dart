import 'package:hive/hive.dart';
import 'package:fftcg_companion/features/models.dart' as models;

class CardAdapter extends TypeAdapter<models.Card> {
  @override
  final int typeId = 0;

  @override
  models.Card read(BinaryReader reader) {
    final map = reader.readMap();
    // Convert all maps recursively to ensure proper type casting
    final convertedMap = _convertMap(map);
    return models.Card.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, models.Card obj) {
    writer.writeMap(obj.toJson());
  }

  Map<String, dynamic> _convertMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _convertMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _convertList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  List _convertList(List list) {
    return list.map((item) {
      if (item is Map) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
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

class PriceAdapter extends TypeAdapter<models.Price> {
  @override
  final int typeId = 2;

  @override
  models.Price read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return models.Price.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, models.Price obj) {
    writer.writeMap(obj.toJson());
  }
}

class PriceDataAdapter extends TypeAdapter<models.PriceData> {
  @override
  final int typeId = 3;

  @override
  models.PriceData read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return models.PriceData.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, models.PriceData obj) {
    writer.writeMap(obj.toJson());
  }
}

class HistoricalPriceAdapter extends TypeAdapter<models.HistoricalPrice> {
  @override
  final int typeId = 4;

  @override
  models.HistoricalPrice read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return models.HistoricalPrice.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, models.HistoricalPrice obj) {
    writer.writeMap(obj.toJson());
  }
}

class HistoricalPriceDataAdapter
    extends TypeAdapter<models.HistoricalPriceData> {
  @override
  final int typeId = 5;

  @override
  models.HistoricalPriceData read(BinaryReader reader) {
    final map = reader.readMap();
    final convertedMap = Map<String, dynamic>.from(map);
    return models.HistoricalPriceData.fromJson(convertedMap);
  }

  @override
  void write(BinaryWriter writer, models.HistoricalPriceData obj) {
    writer.writeMap(obj.toJson());
  }
}
