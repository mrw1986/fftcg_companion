// lib/features/prices/domain/models/historical_price.dart

import 'package:dart_mappable/dart_mappable.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart';

part 'historical_price.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class HistoricalPrice with HistoricalPriceMappable {
  // Added mixin
  final int productId;
  final String groupId;
  final DateTime date;
  final HistoricalPriceData normal;
  final HistoricalPriceData foil;

  const HistoricalPrice({
    // Changed to standard constructor
    required this.productId,
    required this.groupId,
    required this.date,
    required this.normal,
    required this.foil,
  });

  // fromJson factory removed

  // Keep custom Firestore factory
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

  // Keep custom Firestore method
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'groupId': groupId,
      'date': Timestamp.fromDate(date),
      'normal': normal.toFirestore(),
      'foil': foil.toFirestore(),
    };
  }

  // Helper methods (Keep as is)
  bool get hasNormalPrice => normal.low != null;
  bool get hasFoilPrice => foil.low != null;
  bool get hasPrices => hasNormalPrice || hasFoilPrice;

  double? get lowestPrice {
    final prices = [
      if (normal.low != null) normal.low,
      if (foil.low != null) foil.low,
    ].where((p) => p != null).cast<double>().toList();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  // Comparison methods (Keep as is)
  int compareByDate(HistoricalPrice other) {
    return date.compareTo(other.date);
  }

  // Price change calculation (Keep as is)
  static double? calculatePriceChange(
    HistoricalPrice? current,
    HistoricalPrice? previous,
  ) {
    if (current == null || previous == null) return null;

    final currentNormal = current.normal.low;
    final previousNormal = previous.normal.low;

    if (currentNormal != null &&
        previousNormal != null &&
        previousNormal != 0) {
      return ((currentNormal - previousNormal) / previousNormal) * 100;
    }

    final currentFoil = current.foil.low;
    final previousFoil = previous.foil.low;

    if (currentFoil != null && previousFoil != null && previousFoil != 0) {
      return ((currentFoil - previousFoil) / previousFoil) * 100;
    }

    return null;
  }
}

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class HistoricalPriceData with HistoricalPriceDataMappable {
  // Added mixin
  final double? low;

  const HistoricalPriceData({
    // Changed to standard constructor
    this.low,
  });

  // fromJson factory removed

  // Keep custom Firestore factory
  factory HistoricalPriceData.fromFirestore(Map<String, dynamic> data) {
    return HistoricalPriceData(
      low: (data['low'] as num?)?.toDouble(),
    );
  }

  // Keep custom Firestore method
  Map<String, dynamic> toFirestore() {
    return {
      if (low != null) 'low': low,
    };
  }

  // Helper methods (Keep as is)
  bool get hasPrice => low != null;

  // Price analysis (Keep as is)
  static double? calculateAveragePrice(List<HistoricalPriceData> data) {
    final prices = data.where((d) => d.low != null).map((d) => d.low!);
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a + b) / prices.length;
  }
}
