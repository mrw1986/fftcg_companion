// lib/features/prices/domain/models/price.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';

part 'price.freezed.dart';
part 'price.g.dart';

@freezed
@HiveType(typeId: 2)
class Price with _$Price {
  const factory Price({
    @HiveField(0) required int productId,
    @HiveField(1) PriceData? normal,
    @HiveField(2) PriceData? foil,
    @HiveField(3) required DateTime lastUpdated,
  }) = _Price;

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
}

@freezed
@HiveType(typeId: 3)
class PriceData with _$PriceData {
  const factory PriceData({
    @HiveField(0) double? directLowPrice,
    @HiveField(1) required double highPrice,
    @HiveField(2) required double lowPrice,
    @HiveField(3) required double marketPrice,
    @HiveField(4) required double midPrice,
    @HiveField(5) required String subTypeName,
  }) = _PriceData;

  factory PriceData.fromJson(Map<String, dynamic> json) =>
      _$PriceDataFromJson(json);
}

@freezed
@HiveType(typeId: 4)
class HistoricalPrice with _$HistoricalPrice {
  const factory HistoricalPrice({
    @HiveField(0) required int productId,
    @HiveField(1) required DateTime date,
    @HiveField(2) HistoricalPriceData? normal,
    @HiveField(3) HistoricalPriceData? foil,
    @HiveField(4) required String groupId,
  }) = _HistoricalPrice;

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) =>
      _$HistoricalPriceFromJson(json);
}

@freezed
@HiveType(typeId: 5)
class HistoricalPriceData with _$HistoricalPriceData {
  const factory HistoricalPriceData({
    @HiveField(0) double? directLow,
    @HiveField(1) required double high,
    @HiveField(2) required double low,
    @HiveField(3) required double market,
    @HiveField(4) required double mid,
  }) = _HistoricalPriceData;

  factory HistoricalPriceData.fromJson(Map<String, dynamic> json) =>
      _$HistoricalPriceDataFromJson(json);
}
