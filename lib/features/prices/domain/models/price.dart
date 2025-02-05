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
  bool get hasNormalPrice => normal.lowPrice != null;
  bool get hasFoilPrice => foil.lowPrice != null;
  bool get hasPrices => hasNormalPrice || hasFoilPrice;

  double? get lowestPrice => [
        if (normal.lowPrice != null) normal.lowPrice,
        if (foil.lowPrice != null) foil.lowPrice,
      ].reduce((a, b) => a! < b! ? a : b);

  double? get highestPrice => [
        if (normal.lowPrice != null) normal.lowPrice,
        if (foil.lowPrice != null) foil.lowPrice,
      ].reduce((a, b) => a! > b! ? a : b);
}

@freezed
class PriceData with _$PriceData {
  const PriceData._();

  const factory PriceData({
    double? lowPrice,
  }) = _PriceData;

  factory PriceData.fromJson(Map<String, dynamic> json) =>
      _$PriceDataFromJson(json);

  factory PriceData.fromFirestore(Map<String, dynamic> data) {
    return PriceData(
      lowPrice: (data['lowPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (lowPrice != null) 'lowPrice': lowPrice,
    };
  }

  // Helper methods
  bool get hasPrice => lowPrice != null;
}
