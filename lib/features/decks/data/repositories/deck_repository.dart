import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/features/decks/domain/models/deck_models.dart';

/// Repository for managing deck data in Firestore
class DeckRepository {
  final FirebaseFirestore _firestore;

  DeckRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for decks
  CollectionReference<Map<String, dynamic>> get _decksRef =>
      _firestore.collection('decks');

  /// Get a user's decks
  Future<List<Deck>> getUserDecks(String userId) async {
    try {
      final snapshot = await _decksRef
          .where('userId', isEqualTo: userId)
          .orderBy('modified', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Deck.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      // Log error
      return [];
    }
  }

  /// Get a user's decks by format
  Future<List<Deck>> getUserDecksByFormat(
      String userId, DeckFormat format) async {
    try {
      final snapshot = await _decksRef
          .where('userId', isEqualTo: userId)
          .where('format', isEqualTo: format.code)
          .orderBy('modified', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Deck.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      // Log error
      return [];
    }
  }

  /// Get public decks by format
  Future<List<Deck>> getPublicDecksByFormat(DeckFormat format,
      {int limit = 20}) async {
    try {
      final snapshot = await _decksRef
          .where('isPublic', isEqualTo: true)
          .where('format', isEqualTo: format.code)
          .orderBy('modified', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Deck.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      // Log error
      return [];
    }
  }

  /// Get a deck by ID
  Future<Deck?> getDeckById(String deckId) async {
    try {
      final doc = await _decksRef.doc(deckId).get();
      if (doc.exists && doc.data() != null) {
        return Deck.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      // Log error
      return null;
    }
  }

  /// Create a new deck
  Future<Deck> createDeck(Deck deck) async {
    try {
      final docRef = await _decksRef.add(deck.toMap());

      // Return the deck with the new ID
      return Deck(
        id: docRef.id,
        userId: deck.userId,
        name: deck.name,
        description: deck.description,
        format: deck.format,
        isPublic: deck.isPublic,
        created: deck.created,
        modified: deck.modified,
        cards: deck.cards,
        stats: deck.stats,
        titleCategory: deck.titleCategory,
      );
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  /// Update an existing deck
  Future<void> updateDeck(Deck deck) async {
    try {
      await _decksRef.doc(deck.id).update(deck.toMap());
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  /// Delete a deck
  Future<void> deleteDeck(String deckId) async {
    try {
      await _decksRef.doc(deckId).delete();
    } catch (e) {
      // Log error
      rethrow;
    }
  }

  /// Calculate deck statistics
  DeckStats calculateDeckStats(List<DeckCard> cards) {
    int totalCards = 0;
    int backupCount = 0;
    final elementCounts = <String, int>{};

    // TODO: Implement element counting based on card data
    // This would require access to the card database to get element information

    for (final card in cards) {
      totalCards += card.quantity;
      if (card.isBackup) {
        backupCount += card.quantity;
      }

      // For now, we'll leave element counts empty
      // In a real implementation, you would look up the card's element(s)
      // and increment the appropriate counter(s)
    }

    return DeckStats(
      totalCards: totalCards,
      backupCount: backupCount,
      elementCounts: elementCounts,
    );
  }

  /// Toggle a deck's public status
  Future<void> toggleDeckPublicStatus(String deckId, bool isPublic) async {
    try {
      await _decksRef.doc(deckId).update({
        'isPublic': isPublic,
        'modified': Timestamp.now(),
      });
    } catch (e) {
      // Log error
      rethrow;
    }
  }
}
