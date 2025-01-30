// lib/features/prices/domain/models/price.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'price.freezed.dart';
part 'price.g.dart';

@freezed
class Price with _$Price {
  const Price._();

  const factory Price({
    required int productId,
    required DateTime lastUpdated,
    required PriceData normal,
    required PriceData foil,
  }) = _Price;

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);

  factory Price.fromFirestore(Map<String, dynamic> data) {
    return Price(
      productId: data['productId'] as int? ?? 0,
      lastUpdated: (data['lastUpdated'] is Timestamp)
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      normal: PriceData.fromFirestore(
          data['normal'] as Map<String, dynamic>? ?? {}),
      foil:
          PriceData.fromFirestore(data['foil'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'normal': normal.toFirestore(),
      'foil': foil.toFirestore(),
    };
  }

  // Helper methods
  bool get hasNormalPrice => normal.marketPrice != null;
  bool get hasFoilPrice => foil.marketPrice != null;
  bool get hasPrices => hasNormalPrice || hasFoilPrice;

  double? get lowestPrice => [
        if (normal.marketPrice != null) normal.marketPrice,
        if (foil.marketPrice != null) foil.marketPrice,
      ].reduce((a, b) => a! < b! ? a : b);

  double? get highestPrice => [
        if (normal.marketPrice != null) normal.marketPrice,
        if (foil.marketPrice != null) foil.marketPrice,
      ].reduce((a, b) => a! > b! ? a : b);

  // Price trend indicators
  bool get isNormalPriceIncreasing =>
      normal.marketPrice != null &&
      normal.oldPrice != null &&
      normal.marketPrice! > normal.oldPrice!;

  bool get isFoilPriceIncreasing =>
      foil.marketPrice != null &&
      foil.oldPrice != null &&
      foil.marketPrice! > foil.oldPrice!;

  double? getNormalPriceChange() {
    if (normal.marketPrice == null || normal.oldPrice == null) return null;
    return ((normal.marketPrice! - normal.oldPrice!) / normal.oldPrice!) * 100;
  }

  double? getFoilPriceChange() {
    if (foil.marketPrice == null || foil.oldPrice == null) return null;
    return ((foil.marketPrice! - foil.oldPrice!) / foil.oldPrice!) * 100;
  }
}

@freezed
class PriceData with _$PriceData {
  const PriceData._();

  const factory PriceData({
    double? marketPrice,
    double? oldPrice,
    double? lowPrice,
    double? midPrice,
    double? highPrice,
  }) = _PriceData;

  factory PriceData.fromJson(Map<String, dynamic> json) =>
      _$PriceDataFromJson(json);

  factory PriceData.fromFirestore(Map<String, dynamic> data) {
    return PriceData(
      marketPrice: (data['marketPrice'] as num?)?.toDouble(),
      oldPrice: (data['oldPrice'] as num?)?.toDouble(),
      lowPrice: (data['lowPrice'] as num?)?.toDouble(),
      midPrice: (data['midPrice'] as num?)?.toDouble(),
      highPrice: (data['highPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (marketPrice != null) 'marketPrice': marketPrice,
      if (oldPrice != null) 'oldPrice': oldPrice,
      if (lowPrice != null) 'lowPrice': lowPrice,
      if (midPrice != null) 'midPrice': midPrice,
      if (highPrice != null) 'highPrice': highPrice,
    };
  }

  // Helper methods
  bool get hasMarketPrice => marketPrice != null;
  bool get hasPriceRange => lowPrice != null && highPrice != null;
  double? get priceRange =>
      highPrice != null && lowPrice != null ? highPrice! - lowPrice! : null;
  double? get averagePrice => marketPrice ?? (midPrice);
}
