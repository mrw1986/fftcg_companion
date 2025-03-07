import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a card in a deck
class DeckCard {
  final String cardId;
  final int quantity;
  final bool isBackup;

  DeckCard({
    required this.cardId,
    required this.quantity,
    this.isBackup = false,
  });

  factory DeckCard.fromMap(Map<String, dynamic> map) {
    return DeckCard(
      cardId: map['cardId'],
      quantity: map['quantity'] ?? 1,
      isBackup: map['isBackup'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardId': cardId,
      'quantity': quantity,
      'isBackup': isBackup,
    };
  }
}

/// Represents statistics for a deck
class DeckStats {
  final int totalCards;
  final int backupCount;
  final Map<String, int> elementCounts;

  DeckStats({
    required this.totalCards,
    required this.backupCount,
    required this.elementCounts,
  });

  factory DeckStats.fromMap(Map<String, dynamic> map) {
    return DeckStats(
      totalCards: map['totalCards'] ?? 0,
      backupCount: map['backupCount'] ?? 0,
      elementCounts: Map<String, int>.from(map['elementCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCards': totalCards,
      'backupCount': backupCount,
      'elementCounts': elementCounts,
    };
  }

  /// Create empty stats
  factory DeckStats.empty() {
    return DeckStats(
      totalCards: 0,
      backupCount: 0,
      elementCounts: {},
    );
  }
}

/// Represents a deck format
enum DeckFormat {
  standard('standard'),
  title('title'),
  l3('l3'),
  l6('l6');

  final String code;
  const DeckFormat(this.code);

  factory DeckFormat.fromCode(String code) {
    return DeckFormat.values.firstWhere(
      (e) => e.code == code,
      orElse: () => DeckFormat.standard,
    );
  }
}

/// Represents a deck
class Deck {
  final String id; // Document ID in Firestore
  final String userId;
  final String name;
  final String? description;
  final DeckFormat format;
  final bool isPublic;
  final Timestamp created;
  final Timestamp modified;
  final List<DeckCard> cards;
  final DeckStats stats;
  final String? titleCategory;

  Deck({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.format,
    this.isPublic = false,
    Timestamp? created,
    Timestamp? modified,
    List<DeckCard>? cards,
    DeckStats? stats,
    this.titleCategory,
  })  : created = created ?? Timestamp.now(),
        modified = modified ?? Timestamp.now(),
        cards = cards ?? [],
        stats = stats ?? DeckStats.empty();

  /// Create a Deck from a Map (usually from Firestore)
  factory Deck.fromMap(Map<String, dynamic> map, {required String id}) {
    // Parse cards
    final cardsList = <DeckCard>[];
    if (map['cards'] != null) {
      final cardsData = map['cards'] as List;
      for (final cardData in cardsData) {
        cardsList.add(DeckCard.fromMap(cardData));
      }
    }

    return Deck(
      id: id,
      userId: map['userId'],
      name: map['name'],
      description: map['description'],
      format: DeckFormat.fromCode(map['format'] ?? 'standard'),
      isPublic: map['isPublic'] ?? false,
      created: map['created'] ?? Timestamp.now(),
      modified: map['modified'] ?? Timestamp.now(),
      cards: cardsList,
      stats: map['stats'] != null
          ? DeckStats.fromMap(map['stats'])
          : DeckStats.empty(),
      titleCategory: map['titleCategory'],
    );
  }

  /// Convert Deck to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'format': format.code,
      'isPublic': isPublic,
      'created': created,
      'modified': modified,
      'cards': cards.map((card) => card.toMap()).toList(),
      'stats': stats.toMap(),
      'titleCategory': titleCategory,
    };
  }

  /// Create a copy of Deck with some fields updated
  Deck copyWith({
    String? userId,
    String? name,
    String? description,
    DeckFormat? format,
    bool? isPublic,
    List<DeckCard>? cards,
    DeckStats? stats,
    String? titleCategory,
  }) {
    return Deck(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      isPublic: isPublic ?? this.isPublic,
      created: created,
      modified: Timestamp.now(),
      cards: cards ?? this.cards,
      stats: stats ?? this.stats,
      titleCategory: titleCategory ?? this.titleCategory,
    );
  }
}
