// lib/models/collection_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionEntry {
  final String cardId;
  final int quantity;
  final int foilQuantity;
  final Map<String, int> conditions;
  final DateTime lastUpdated;

  CollectionEntry({
    required this.cardId,
    required this.quantity,
    required this.foilQuantity,
    required this.conditions,
    required this.lastUpdated,
  });

  factory CollectionEntry.fromFirestore(Map<String, dynamic> data) {
    return CollectionEntry(
      cardId: data['cardId'] as String,
      quantity: data['quantity'] as int,
      foilQuantity: data['foilQuantity'] as int,
      conditions: Map<String, int>.from(data['conditions'] as Map),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
