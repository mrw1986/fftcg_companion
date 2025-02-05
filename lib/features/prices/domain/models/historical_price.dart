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
  bool get hasNormalPrice => normal.low != null;
  bool get hasFoilPrice => foil.low != null;
  bool get hasPrices => hasNormalPrice || hasFoilPrice;

  double? get lowestPrice => [
        if (normal.low != null) normal.low,
        if (foil.low != null) foil.low,
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

    final currentNormal = current.normal.low;
    final previousNormal = previous.normal.low;

    if (currentNormal != null && previousNormal != null) {
      return ((currentNormal - previousNormal) / previousNormal) * 100;
    }

    final currentFoil = current.foil.low;
    final previousFoil = previous.foil.low;

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
    double? low,
  }) = _HistoricalPriceData;

  factory HistoricalPriceData.fromJson(Map<String, dynamic> json) =>
      _$HistoricalPriceDataFromJson(json);

  factory HistoricalPriceData.fromFirestore(Map<String, dynamic> data) {
    return HistoricalPriceData(
      low: (data['low'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (low != null) 'low': low,
    };
  }

  // Helper methods
  bool get hasPrice => low != null;

  // Price analysis
  static double? calculateAveragePrice(List<HistoricalPriceData> data) {
    final prices = data.where((d) => d.low != null).map((d) => d.low!);
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a + b) / prices.length;
  }
}
