// lib/models/deck.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String name;
  final String description;
  final String format;
  final Map<String, int> cards;
  final DateTime created;
  final DateTime lastModified;
  final bool isPublic;
  final List<String> tags;
  final DeckValidation validation;

  const Deck({
    required this.id,
    required this.name,
    required this.description,
    required this.format,
    required this.cards,
    required this.created,
    required this.lastModified,
    this.isPublic = false,
    this.tags = const [],
    required this.validation,
  });

  bool get isValid => validation.isValid;
  int get totalCards => cards.values
      .fold(0, (accumulator, currentValue) => accumulator + currentValue);

  factory Deck.fromFirestore(Map<String, dynamic> data, {String? id}) {
    return Deck(
      id: id ?? data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String,
      format: data['format'] as String,
      cards: Map<String, int>.from(data['cards'] as Map),
      created: (data['created'] as Timestamp).toDate(),
      lastModified: (data['lastModified'] as Timestamp).toDate(),
      isPublic: data['isPublic'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List? ?? []),
      validation: DeckValidation.fromFirestore(
        data['validation'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'format': format,
      'cards': cards,
      'created': Timestamp.fromDate(created),
      'lastModified': Timestamp.fromDate(lastModified),
      'isPublic': isPublic,
      'tags': tags,
      'validation': validation.toFirestore(),
    };
  }

  Deck copyWith({
    String? id,
    String? name,
    String? description,
    String? format,
    Map<String, int>? cards,
    DateTime? created,
    DateTime? lastModified,
    bool? isPublic,
    List<String>? tags,
    DeckValidation? validation,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      cards: cards ?? this.cards,
      created: created ?? this.created,
      lastModified: lastModified ?? this.lastModified,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      validation: validation ?? this.validation,
    );
  }
}

class DeckValidation {
  final int totalCards;
  final int backups;
  final int forwards;
  final int summons;
  final int monsters;
  final Map<String, int> elements;

  const DeckValidation({
    required this.totalCards,
    required this.backups,
    required this.forwards,
    required this.summons,
    required this.monsters,
    required this.elements,
  });

  bool get isValid =>
      totalCards == 50 &&
      backups <= 3 &&
      forwards <= 3 &&
      summons <= 3 &&
      monsters <= 3;

  factory DeckValidation.fromFirestore(Map<String, dynamic> data) {
    return DeckValidation(
      totalCards: data['totalCards'] as int,
      backups: data['backups'] as int,
      forwards: data['forwards'] as int,
      summons: data['summons'] as int,
      monsters: data['monsters'] as int,
      elements: Map<String, int>.from(data['elements'] as Map),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalCards': totalCards,
      'backups': backups,
      'forwards': forwards,
      'summons': summons,
      'monsters': monsters,
      'elements': elements,
    };
  }
}
