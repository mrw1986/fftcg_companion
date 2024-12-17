// lib/models/price.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Price {
  final String cardId;
  final PriceData normal;
  final PriceData? foil;
  final DateTime lastUpdated;

  const Price({
    required this.cardId,
    required this.normal,
    this.foil,
    required this.lastUpdated,
  });

  factory Price.fromFirestore(Map<String, dynamic> data, {String? cardId}) {
    return Price(
      cardId: cardId ?? data['cardId'] as String,
      normal: PriceData.fromFirestore(data['normal'] as Map<String, dynamic>),
      foil: data['foil'] != null
          ? PriceData.fromFirestore(data['foil'] as Map<String, dynamic>)
          : null,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cardId': cardId,
      'normal': normal.toFirestore(),
      'foil': foil?.toFirestore(),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class PriceData {
  final double? directLowPrice;
  final double highPrice;
  final double lowPrice;
  final double marketPrice;
  final double midPrice;
  final int productId;
  final String subTypeName;

  const PriceData({
    this.directLowPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.marketPrice,
    required this.midPrice,
    required this.productId,
    required this.subTypeName,
  });

  factory PriceData.fromFirestore(Map<String, dynamic> data) {
    return PriceData(
      directLowPrice: data['directLowPrice'] as double?,
      highPrice: data['highPrice'] as double,
      lowPrice: data['lowPrice'] as double,
      marketPrice: data['marketPrice'] as double,
      midPrice: data['midPrice'] as double,
      productId: data['productId'] as int,
      subTypeName: data['subTypeName'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'directLowPrice': directLowPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'marketPrice': marketPrice,
      'midPrice': midPrice,
      'productId': productId,
      'subTypeName': subTypeName,
    };
  }
}

class PriceHistory {
  final String cardId;
  final List<PricePoint> points;
  final DateTime startDate;
  final DateTime endDate;

  const PriceHistory({
    required this.cardId,
    required this.points,
    required this.startDate,
    required this.endDate,
  });

  factory PriceHistory.fromFirestore(Map<String, dynamic> data,
      {String? cardId}) {
    final pointsList = (data['points'] as List).map((point) {
      return PricePoint.fromFirestore(point as Map<String, dynamic>);
    }).toList();

    return PriceHistory(
      cardId: cardId ?? data['cardId'] as String,
      points: pointsList,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cardId': cardId,
      'points': points.map((point) => point.toFirestore()).toList(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }
}

class PricePoint {
  final DateTime date;
  final double normalPrice;
  final double? foilPrice;

  const PricePoint({
    required this.date,
    required this.normalPrice,
    this.foilPrice,
  });

  factory PricePoint.fromFirestore(Map<String, dynamic> data) {
    return PricePoint(
      date: (data['date'] as Timestamp).toDate(),
      normalPrice: data['normalPrice'] as double,
      foilPrice: data['foilPrice'] as double?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'normalPrice': normalPrice,
      'foilPrice': foilPrice,
    };
  }
}
