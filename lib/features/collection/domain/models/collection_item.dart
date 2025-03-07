import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a card condition
enum CardCondition {
  nearMint('NM'),
  lightlyPlayed('LP'),
  moderatelyPlayed('MP'),
  heavilyPlayed('HP'),
  damaged('DMG');

  final String code;
  const CardCondition(this.code);

  factory CardCondition.fromCode(String code) {
    return CardCondition.values.firstWhere(
      (e) => e.code == code,
      orElse: () => CardCondition.nearMint,
    );
  }
}

/// Represents purchase information for a card
class PurchaseInfo {
  final double price;
  final Timestamp date;

  PurchaseInfo({
    required this.price,
    required this.date,
  });

  factory PurchaseInfo.fromMap(Map<String, dynamic> map) {
    return PurchaseInfo(
      price: (map['price'] as num).toDouble(),
      date: map['date'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'date': date,
    };
  }
}

/// Represents a card in a user's collection
class CollectionItem {
  final String id; // Document ID in Firestore
  final String userId;
  final String cardId;
  final int regularQty;
  final int foilQty;
  final Map<String, CardCondition> condition;
  final Map<String, PurchaseInfo> purchaseInfo;
  final Timestamp lastModified;

  CollectionItem({
    required this.id,
    required this.userId,
    required this.cardId,
    this.regularQty = 0,
    this.foilQty = 0,
    Map<String, CardCondition>? condition,
    Map<String, PurchaseInfo>? purchaseInfo,
    Timestamp? lastModified,
  })  : condition = condition ?? {},
        purchaseInfo = purchaseInfo ?? {},
        lastModified = lastModified ?? Timestamp.now();

  /// Create a CollectionItem from a Map (usually from Firestore)
  factory CollectionItem.fromMap(Map<String, dynamic> map,
      {required String id}) {
    // Parse condition map
    final conditionMap = <String, CardCondition>{};
    if (map['condition'] != null) {
      final conditionData = map['condition'] as Map<String, dynamic>;
      if (conditionData['regular'] != null) {
        conditionMap['regular'] =
            CardCondition.fromCode(conditionData['regular']);
      }
      if (conditionData['foil'] != null) {
        conditionMap['foil'] = CardCondition.fromCode(conditionData['foil']);
      }
    }

    // Parse purchase info map
    final purchaseInfoMap = <String, PurchaseInfo>{};
    if (map['purchaseInfo'] != null) {
      final purchaseData = map['purchaseInfo'] as Map<String, dynamic>;
      if (purchaseData['regular'] != null) {
        purchaseInfoMap['regular'] =
            PurchaseInfo.fromMap(purchaseData['regular']);
      }
      if (purchaseData['foil'] != null) {
        purchaseInfoMap['foil'] = PurchaseInfo.fromMap(purchaseData['foil']);
      }
    }

    return CollectionItem(
      id: id,
      userId: map['userId'],
      cardId: map['cardId'],
      regularQty: map['regularQty'] ?? 0,
      foilQty: map['foilQty'] ?? 0,
      condition: conditionMap,
      purchaseInfo: purchaseInfoMap,
      lastModified: map['lastModified'] ?? Timestamp.now(),
    );
  }

  /// Convert CollectionItem to a Map for Firestore
  Map<String, dynamic> toMap() {
    // Convert condition to map
    final conditionMap = <String, String>{};
    if (condition.containsKey('regular')) {
      conditionMap['regular'] = condition['regular']!.code;
    }
    if (condition.containsKey('foil')) {
      conditionMap['foil'] = condition['foil']!.code;
    }

    // Convert purchase info to map
    final purchaseInfoMap = <String, Map<String, dynamic>>{};
    if (purchaseInfo.containsKey('regular')) {
      purchaseInfoMap['regular'] = purchaseInfo['regular']!.toMap();
    }
    if (purchaseInfo.containsKey('foil')) {
      purchaseInfoMap['foil'] = purchaseInfo['foil']!.toMap();
    }

    return {
      'userId': userId,
      'cardId': cardId,
      'regularQty': regularQty,
      'foilQty': foilQty,
      'condition': conditionMap.isEmpty ? null : conditionMap,
      'purchaseInfo': purchaseInfoMap.isEmpty ? null : purchaseInfoMap,
      'lastModified': lastModified,
    };
  }

  /// Create a copy of CollectionItem with some fields updated
  CollectionItem copyWith({
    String? userId,
    String? cardId,
    int? regularQty,
    int? foilQty,
    Map<String, CardCondition>? condition,
    Map<String, PurchaseInfo>? purchaseInfo,
    Timestamp? lastModified,
  }) {
    return CollectionItem(
      id: id,
      userId: userId ?? this.userId,
      cardId: cardId ?? this.cardId,
      regularQty: regularQty ?? this.regularQty,
      foilQty: foilQty ?? this.foilQty,
      condition: condition ?? this.condition,
      purchaseInfo: purchaseInfo ?? this.purchaseInfo,
      lastModified: lastModified ?? Timestamp.now(),
    );
  }
}
