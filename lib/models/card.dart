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
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      cleanName: data['cleanName']?.toString() ?? '',
      elements: List<String>.from(data['elements'] ?? []),
      type: data['type']?.toString() ?? '',
      cost: (data['cost'] as num?)?.toInt() ?? 0,
      power: data['power']?.toString() ?? '0',
      rarity: data['rarity']?.toString() ?? '',
      setId: data['setId']?.toString() ?? '',
      setNumber: data['setNumber']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      flavorText: data['flavorText']?.toString(),
      imageUrls: CardImageUrls.fromMap(
          data['imageUrls'] as Map<String, dynamic>? ?? {}),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      small: data['small']?.toString() ?? '',
      normal: data['normal']?.toString() ?? '',
      large: data['large']?.toString() ?? '',
    );
  }
}
