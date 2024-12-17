// lib/models/card.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Card {
  final String id;
  final String name;
  final String cleanName;
  final List<String> elements;
  final String type;
  final int cost;
  final String power;
  final String rarity;
  final String setId;
  final String setNumber;
  final String text;
  final String? flavorText;
  final CardImageUrls imageUrls;
  final DateTime lastUpdated;

  Card({
    required this.id,
    required this.name,
    required this.cleanName,
    required this.elements,
    required this.type,
    required this.cost,
    required this.power,
    required this.rarity,
    required this.setId,
    required this.setNumber,
    required this.text,
    this.flavorText,
    required this.imageUrls,
    required this.lastUpdated,
  });

  factory Card.fromFirestore(Map<String, dynamic> data) {
    return Card(
      id: data['id'] as String,
      name: data['name'] as String,
      cleanName: data['cleanName'] as String,
      elements: List<String>.from(data['elements']),
      type: data['type'] as String,
      cost: data['cost'] as int,
      power: data['power'] as String,
      rarity: data['rarity'] as String,
      setId: data['setId'] as String,
      setNumber: data['setNumber'] as String,
      text: data['text'] as String,
      flavorText: data['flavorText'] as String?,
      imageUrls:
          CardImageUrls.fromMap(data['imageUrls'] as Map<String, dynamic>),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}

class CardImageUrls {
  final String small;
  final String normal;
  final String large;

  CardImageUrls({
    required this.small,
    required this.normal,
    required this.large,
  });

  factory CardImageUrls.fromMap(Map<String, dynamic> data) {
    return CardImageUrls(
      small: data['small'] as String,
      normal: data['normal'] as String,
      large: data['large'] as String,
    );
  }
}
