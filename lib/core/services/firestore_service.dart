import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/features/models.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;
  static const int _batchSize = 50;
  static const Duration _cacheDuration = Duration(minutes: 30);
  static const int maxQueryLimit = 1000; // Changed to public

  final _documentCache = <String, DocumentSnapshot<Map<String, dynamic>>>{};
  final _queryCacheTimestamps = <String, DateTime>{};
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
  CollectionReference<Map<String, dynamic>> get cardsCollection =>
      _firestore.collection('cards').withConverter<Map<String, dynamic>>(
            fromFirestore: (snapshot, _) => snapshot.data()!,
            toFirestore: (data, _) => data,
          );

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

  Future<void> prefetchPrices(List<String> cardIds) async {
    if (cardIds.isEmpty) return;

    try {
      final uncachedIds = cardIds.where((id) {
        final cacheKey = 'price_$id';
        final timestamp = _queryCacheTimestamps[cacheKey];
        return !_documentCache.containsKey(cacheKey) ||
            timestamp == null ||
            DateTime.now().difference(timestamp) > _cacheDuration;
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
          _queryCacheTimestamps[cacheKey] = DateTime.now();
        }
      }
    } catch (e, stack) {
      talker.error('Error prefetching prices', e, stack);
    }
  }

  // Cache management
  void clearCache() {
    _documentCache.clear();
    _queryCacheTimestamps.clear();
    _queryCache.clear();
    talker.debug('Cleared all caches');
  }
}
