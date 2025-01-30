// lib/features/prices/domain/models/historical_price.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'historical_price.freezed.dart';
part 'historical_price.g.dart';

@freezed
class HistoricalPrice with _$HistoricalPrice {
  const HistoricalPrice._();

  const factory HistoricalPrice({
    required int productId,
    required String groupId,
    required DateTime date,
    required HistoricalPriceData normal,
    required HistoricalPriceData foil,
  }) = _HistoricalPrice;

  factory HistoricalPrice.fromJson(Map<String, dynamic> json) =>
      _$HistoricalPriceFromJson(json);

  factory HistoricalPrice.fromFirestore(Map<String, dynamic> data) {
    return HistoricalPrice(
      productId: data['productId'] as int? ?? 0,
      groupId: data['groupId'] as String? ?? '',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      normal: HistoricalPriceData.fromFirestore(
          data['normal'] as Map<String, dynamic>? ?? {}),
      foil: HistoricalPriceData.fromFirestore(
          data['foil'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'groupId': groupId,
      'date': Timestamp.fromDate(date),
      'normal': normal.toFirestore(),
      'foil': foil.toFirestore(),
    };
  }

  // Helper methods
  bool get hasNormalPrice => normal.price != null;
  bool get hasFoilPrice => foil.price != null;
  bool get hasPrices => hasNormalPrice || hasFoilPrice;

  double? get lowestPrice => [
        if (normal.price != null) normal.price,
        if (foil.price != null) foil.price,
      ].reduce((a, b) => a! < b! ? a : b);

  // Comparison methods
  int compareByDate(HistoricalPrice other) {
    return date.compareTo(other.date);
  }

  // Price change calculation
  static double? calculatePriceChange(
    HistoricalPrice? current,
    HistoricalPrice? previous,
  ) {
    if (current == null || previous == null) return null;

    final currentNormal = current.normal.price;
    final previousNormal = previous.normal.price;

    if (currentNormal != null && previousNormal != null) {
      return ((currentNormal - previousNormal) / previousNormal) * 100;
    }

    final currentFoil = current.foil.price;
    final previousFoil = previous.foil.price;

    if (currentFoil != null && previousFoil != null) {
      return ((currentFoil - previousFoil) / previousFoil) * 100;
    }

    return null;
  }
}

@freezed
class HistoricalPriceData with _$HistoricalPriceData {
  const HistoricalPriceData._();

  const factory HistoricalPriceData({
    double? price,
    int? quantity,
  }) = _HistoricalPriceData;

  factory HistoricalPriceData.fromJson(Map<String, dynamic> json) =>
      _$HistoricalPriceDataFromJson(json);

  factory HistoricalPriceData.fromFirestore(Map<String, dynamic> data) {
    return HistoricalPriceData(
      price: (data['price'] as num?)?.toDouble(),
      quantity: data['quantity'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (price != null) 'price': price,
      if (quantity != null) 'quantity': quantity,
    };
  }

  // Helper methods
  bool get hasData => price != null && quantity != null;
  bool get hasPrice => price != null;
  bool get hasQuantity => quantity != null;

  // Price analysis
  static double? calculateAveragePrice(List<HistoricalPriceData> data) {
    final prices = data.where((d) => d.price != null).map((d) => d.price!);
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a + b) / prices.length;
  }

  static int? calculateTotalQuantity(List<HistoricalPriceData> data) {
    final quantities =
        data.where((d) => d.quantity != null).map((d) => d.quantity!);
    if (quantities.isEmpty) return null;
    return quantities.reduce((a, b) => a + b);
  }
}
