import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/features/collection/domain/models/collection_item.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Repository for managing collection data in Firestore
class CollectionRepository {
  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;
  final Talker talker = Talker();

  CollectionRepository({
    FirebaseFirestore? firestore,
    UserRepository? userRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userRepository = userRepository ?? UserRepository();

  /// Collection reference for collection items
  CollectionReference<Map<String, dynamic>> get _collectionRef =>
      _firestore.collection('collections');

  /// Get a user's collection
  Future<List<CollectionItem>> getUserCollection(String userId) async {
    try {
      final snapshot = await _collectionRef
          .where('userId', isEqualTo: userId)
          .orderBy('lastModified', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CollectionItem.fromMap(doc.data(), id: doc.id))
          .toList();
    } catch (e) {
      talker.error('Error getting user collection: $e');
      return [];
    }
  }

  /// Get a specific card in a user's collection
  Future<CollectionItem?> getUserCard(String userId, String cardId) async {
    try {
      final snapshot = await _collectionRef
          .where('userId', isEqualTo: userId)
          .where('cardId', isEqualTo: cardId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return CollectionItem.fromMap(doc.data(), id: doc.id);
      }
      return null;
    } catch (e) {
      talker.error('Error getting user card: $e');
      return null;
    }
  }

  /// Add or update a card in a user's collection
  Future<CollectionItem> addOrUpdateCard({
    required String userId,
    required String cardId,
    int? regularQty,
    int? foilQty,
    Map<String, CardCondition>? condition,
    Map<String, PurchaseInfo>? purchaseInfo,
    Map<String, GradingInfo>? gradingInfo,
  }) async {
    try {
      // Check if card already exists in collection
      final existingCard = await getUserCard(userId, cardId);

      if (existingCard != null) {
        // Update existing card
        final updatedCard = existingCard.copyWith(
          regularQty: regularQty ?? existingCard.regularQty,
          foilQty: foilQty ?? existingCard.foilQty,
          condition: condition ?? existingCard.condition,
          purchaseInfo: purchaseInfo ?? existingCard.purchaseInfo,
          gradingInfo: gradingInfo ?? existingCard.gradingInfo,
          lastModified: Timestamp.now(),
        );

        await _collectionRef.doc(existingCard.id).update(updatedCard.toMap());
        return updatedCard;
      } else {
        // Increment the user's collection count
        await _userRepository.updateCollectionCount(userId, 1, increment: true);

        // Create new card
        final newCard = CollectionItem(
          id: '', // Will be set after document creation
          userId: userId,
          cardId: cardId,
          regularQty: regularQty ?? 0,
          foilQty: foilQty ?? 0,
          condition: condition,
          purchaseInfo: purchaseInfo,
          gradingInfo: gradingInfo,
          lastModified: Timestamp.now(),
        );

        final docRef = await _collectionRef.add(newCard.toMap());
        // We can't use copyWith for id since it's final and not included in copyWith
        return CollectionItem(
          id: docRef.id,
          userId: newCard.userId,
          cardId: newCard.cardId,
          regularQty: newCard.regularQty,
          foilQty: newCard.foilQty,
          condition: newCard.condition,
          purchaseInfo: newCard.purchaseInfo,
          gradingInfo: newCard.gradingInfo,
          lastModified: newCard.lastModified,
        );
      }
    } catch (e) {
      talker.error('Error adding or updating card: $e');
      rethrow;
    }
  }

  /// Remove a card from a user's collection
  Future<void> removeCard(String documentId) async {
    try {
      // Get the card to find the userId
      final doc = await _collectionRef.doc(documentId).get();
      if (doc.exists) {
        final card = CollectionItem.fromMap(doc.data()!, id: doc.id);

        // Delete the card
        await _collectionRef.doc(documentId).delete();

        // Decrement the user's collection count
        await _userRepository.updateCollectionCount(card.userId, -1,
            increment: true);
      } else {
        talker.warning('Card not found for deletion: $documentId');
      }
    } catch (e) {
      talker.error('Error removing card: $e');
      rethrow;
    }
  }

  /// Get collection statistics for a user
  Future<Map<String, dynamic>> getUserCollectionStats(String userId) async {
    try {
      final collection = await getUserCollection(userId);

      int totalCards = 0;
      int uniqueCards = collection.length;
      int regularCards = 0;
      int foilCards = 0;
      int gradedCards = 0;

      for (final card in collection) {
        regularCards += card.regularQty;
        foilCards += card.foilQty;
        totalCards += card.regularQty + card.foilQty;

        // Count graded cards
        if (card.gradingInfo.isNotEmpty) {
          gradedCards++;
        }
      }

      return {
        'totalCards': totalCards,
        'uniqueCards': uniqueCards,
        'regularCards': regularCards,
        'foilCards': foilCards,
        'gradedCards': gradedCards,
      };
    } catch (e) {
      talker.error('Error getting user collection stats: $e');
      return {
        'totalCards': 0,
        'uniqueCards': 0,
        'regularCards': 0,
        'foilCards': 0,
        'gradedCards': 0,
      };
    }
  }

  /// Batch update multiple cards in a collection
  Future<void> batchUpdateCards(List<CollectionItem> cards) async {
    try {
      // Count new cards (those without an ID)
      final newCardCount = cards.where((card) => card.id.isEmpty).length;

      // If there are new cards, update the collection count
      if (newCardCount > 0 && cards.isNotEmpty) {
        final userId = cards.first.userId;
        await _userRepository.updateCollectionCount(userId, newCardCount,
            increment: true);
      }

      final batch = _firestore.batch();

      for (final card in cards) {
        if (card.id.isNotEmpty) {
          // Update existing card
          batch.update(_collectionRef.doc(card.id), card.toMap());
        } else {
          // Create new card
          batch.set(_collectionRef.doc(), card.toMap());
        }
      }

      await batch.commit();
    } catch (e) {
      talker.error('Error batch updating cards: $e');
      rethrow;
    }
  }
}
