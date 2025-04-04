// lib/features/prices/domain/models/price.dart

import 'package:dart_mappable/dart_mappable.dart'; // Added
import 'package:cloud_firestore/cloud_firestore.dart';

part 'price.mapper.dart'; // Added

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class Price with PriceMappable {
  // Added mixin
  final int productId;
  final DateTime lastUpdated;
  final PriceData normal;
  final PriceData foil;

  const Price({
    // Changed to standard constructor
    required this.productId,
    required this.lastUpdated,
    required this.normal,
    required this.foil,
  });

  // fromJson factory removed

  // Keep custom Firestore factory
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

  // Keep custom Firestore method
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'normal': normal.toFirestore(),
      'foil': foil.toFirestore(),
    };
  }

  // Helper methods (Keep as is)
  bool get hasNormalPrice => normal.lowPrice != null;
  bool get hasFoilPrice => foil.lowPrice != null;
  bool get hasPrices => hasNormalPrice || hasFoilPrice;

  double? get lowestPrice {
    final prices = [
      if (normal.lowPrice != null) normal.lowPrice,
      if (foil.lowPrice != null) foil.lowPrice,
    ].where((p) => p != null).cast<double>().toList();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a < b ? a : b);
  }

  double? get highestPrice {
    final prices = [
      if (normal.lowPrice != null) normal.lowPrice,
      if (foil.lowPrice != null) foil.lowPrice,
    ].where((p) => p != null).cast<double>().toList();
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a > b ? a : b);
  }
}

@MappableClass(caseStyle: CaseStyle.camelCase) // Added
class PriceData with PriceDataMappable {
  // Added mixin
  final double? lowPrice;

  const PriceData({
    // Changed to standard constructor
    this.lowPrice,
  });

  // fromJson factory removed

  // Keep custom Firestore factory
  factory PriceData.fromFirestore(Map<String, dynamic> data) {
    return PriceData(
      lowPrice: (data['lowPrice'] as num?)?.toDouble(),
    );
  }

  // Keep custom Firestore method
  Map<String, dynamic> toFirestore() {
    return {
      if (lowPrice != null) 'lowPrice': lowPrice,
    };
  }

  // Helper methods (Keep as is)
  bool get hasPrice => lowPrice != null;
}
