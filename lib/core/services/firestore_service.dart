import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  static const int _batchSize = 50;
  static const int maxQueryLimit = 1000;

  final _documentCache = <String, DocumentSnapshot<Map<String, dynamic>>>{};
  final _queryCache = <String, QuerySnapshot<Map<String, dynamic>>>{};

  FirestoreService(this._firestore) {
    _initializeIndexes();
  }

  void _initializeIndexes() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Collection References
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      _firestore.collection(name).withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

  CollectionReference<Map<String, dynamic>> get cardsCollection =>
      collection('cards');

  CollectionReference<Map<String, dynamic>> get pricesCollection =>
      _firestore.collection('prices').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

  CollectionReference<Map<String, dynamic>> get historicalPricesCollection =>
      _firestore
          .collection('historicalPrices')
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

  CollectionReference<Map<String, dynamic>> get groupsCollection =>
      _firestore.collection('groups').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

  DocumentReference<Map<String, dynamic>> get metadataDoc => _firestore
      .collection('metadata')
      .doc('cards')
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (snapshot, _) => snapshot.data() ?? {},
        toFirestore: (data, _) => data,
      );

  // Metadata methods
  Future<Map<String, dynamic>> getMetadata() async {
    try {
      final doc = await metadataDoc.get();
      if (!doc.exists) {
        // If metadata doesn't exist, just return default values
        // without attempting to create the document
        talker.info('Metadata document does not exist, using default values');
        return {
          'version': 1,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
      return doc.data() ?? {};
    } catch (e, stack) {
      // Log the error but don't crash - return default metadata
      talker.error('Error getting metadata', e, stack);

      // Return default metadata that won't trigger unnecessary syncs
      return {
        'version': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
        'offline': true // Flag to indicate we're using offline data
      };
    }
  }

  Future<void> updateMetadataVersion() async {
    try {
      final metadata = await getMetadata();
      final currentVersion = metadata['version'] as int? ?? 1;
      await metadataDoc.update({
        'version': currentVersion + 1,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      talker.debug('Updated metadata version to ${currentVersion + 1}');
    } catch (e, stack) {
      talker.error('Error updating metadata version', e, stack);
    }
  }

  // Card methods with versioning
  Future<List<Card>> getCardsUpdatedSince(int version) async {
    try {
      final snapshot = await cardsCollection
          .where('dataVersion', isGreaterThan: version)
          .get();

      return snapshot.docs
          .map((doc) => Card.fromFirestore(doc.data()))
          .toList();
    } catch (e, stack) {
      talker.error('Error getting updated cards', e, stack);
      return [];
    }
  }

  // Paginated card loading
  Future<List<Card>> getCardsPaginated({
    int limit = 50,
    DocumentSnapshot? startAfter,
    required String sortField,
    required bool sortDescending,
  }) async {
    try {
      Query<Map<String, dynamic>> query = cardsCollection
          .orderBy(sortField, descending: sortDescending)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => Card.fromFirestore(doc.data()))
          .toList();
    } catch (e, stack) {
      talker.error('Error getting paginated cards', e, stack);
      return [];
    }
  }

  // Price-specific methods
  Future<Price?> getPrice(String cardId) async {
    try {
      final doc = await pricesCollection.doc(cardId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Price.fromFirestore(doc.data()!);
    } catch (e, stack) {
      talker.error('Error getting price for card $cardId', e, stack);
      return null;
    }
  }

  // Batch loading for prices
  Future<Map<String, Price>> getPricesForCards(List<String> cardIds) async {
    final result = <String, Price>{};

    if (cardIds.isEmpty) return result;

    try {
      // Process in batches of 10 (Firestore limit for whereIn)
      for (var i = 0; i < cardIds.length; i += 10) {
        final end = (i + 10 < cardIds.length) ? i + 10 : cardIds.length;
        final batch = cardIds.sublist(i, end);

        final snapshot = await pricesCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          result[doc.id] = Price.fromFirestore(doc.data());
        }
      }

      return result;
    } catch (e, stack) {
      talker.error('Error batch loading prices', e, stack);
      return result;
    }
  }

  Future<void> prefetchPrices(List<String> cardIds) async {
    if (cardIds.isEmpty) return;

    try {
      final uncachedIds = cardIds.where((id) {
        final cacheKey = 'price_$id';
        return !_documentCache.containsKey(cacheKey);
      }).toList();

      if (uncachedIds.isEmpty) return;

      for (var i = 0; i < uncachedIds.length; i += _batchSize) {
        final batch = uncachedIds.skip(i).take(_batchSize).toList();
        final snapshot = await pricesCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in snapshot.docs) {
          final cacheKey = 'price_${doc.id}';
          _documentCache[cacheKey] = doc;
        }
      }
    } catch (e, stack) {
      talker.error('Error prefetching prices', e, stack);
    }
  }

  // Cache management
  void clearCache() {
    _documentCache.clear();
    _queryCache.clear();
    talker.debug('Cleared all caches');
  }
}
