// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/core/utils/logger.dart';

part 'firestore_service.g.dart';

@riverpod
FirestoreService firestoreService(ref) {
  return FirestoreService(FirebaseFirestore.instance);
}

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // Collection References
  CollectionReference get cardsCollection => _firestore.collection('cards');
  CollectionReference get pricesCollection => _firestore.collection('prices');
  CollectionReference get historicalPricesCollection =>
      _firestore.collection('historicalPrices');

  // Converters
  models.Card _convertToCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Timestamp to DateTime
    if (data['lastUpdated'] is Timestamp) {
      data['lastUpdated'] =
          (data['lastUpdated'] as Timestamp).toDate().toIso8601String();
    }

    // Convert extendedData from subcollection if it exists
    final extendedDataMap = <String, models.ExtendedData>{};
    if (data['extendedData'] != null) {
      (data['extendedData'] as Map<String, dynamic>).forEach((key, value) {
        extendedDataMap[key] =
            models.ExtendedData.fromJson(value as Map<String, dynamic>);
      });
    }
    data['extendedData'] = extendedDataMap;

    return models.Card.fromJson(data);
  }

  models.Price _convertToPrice(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Timestamp to DateTime
    if (data['lastUpdated'] is Timestamp) {
      data['lastUpdated'] =
          (data['lastUpdated'] as Timestamp).toDate().toIso8601String();
    }

    return models.Price.fromJson(data);
  }

  models.HistoricalPrice _convertToHistoricalPrice(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Timestamp to DateTime
    if (data['date'] is Timestamp) {
      data['date'] = (data['date'] as Timestamp).toDate().toIso8601String();
    }

    return models.HistoricalPrice.fromJson(data);
  }

  // Card Methods
  Stream<List<models.Card>> watchCards({
    int? limit,
    Query<Object?>? Function(Query<Object?> query)? queryBuilder,
  }) {
    Query<Object?> query = cardsCollection;

    if (queryBuilder != null) {
      query = queryBuilder(query) ?? query;
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_convertToCard).toList());
  }

  Future<List<models.Card>> getCards({
    int limit = 20,
    String? startAfterId,
    Query<Object?>? Function(Query<Object?> query)? queryBuilder,
  }) async {
    Query query = cardsCollection.orderBy('productId');

    if (queryBuilder != null) {
      query = queryBuilder(query) ?? query;
    }

    if (startAfterId != null) {
      query = query.where('productId', isGreaterThan: int.parse(startAfterId));
    }

    query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map(_convertToCard).toList();
  }

  Future<models.Card?> getCard(String id) async {
    try {
      talker.debug('Fetching card document: $id');
      final doc = await cardsCollection.doc(id).get();
      if (!doc.exists) {
        talker.info('Card document does not exist');
        return null;
      }

      talker.debug('Fetching extended data subcollection');
      final extendedDataSnapshot =
          await doc.reference.collection('extendedData').get();

      talker.debug('Extended data docs: ${extendedDataSnapshot.docs.length}');

      final data = doc.data() as Map<String, dynamic>;

      final extendedData = <String, dynamic>{};
      for (var extDoc in extendedDataSnapshot.docs) {
        talker.debug('Extended data doc: ${extDoc.id} -> ${extDoc.data()}');
        extendedData[extDoc.id] = extDoc.data();
      }

      data['extendedData'] = extendedData;
      talker.debug('Final card data before conversion: $data');

      return models.Card.fromJson(data);
    } catch (e, stack) {
      talker.error('Error fetching card', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> searchCards(String query) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();
      talker.debug('Performing Firestore search for: $normalizedQuery');

      // Create queries
      final queries = <Future<QuerySnapshot>>[];

      // Query 1: Search by cleanName using prefix
      queries.add(cardsCollection
          .orderBy('cleanName')
          .startAt([normalizedQuery]).endAt(['$normalizedQuery\uf8ff']).get());

      // Query 2: Search by card numbers using array-contains
      queries.add(cardsCollection
          .where('cardNumbers', arrayContains: normalizedQuery.toUpperCase())
          .get());

      // Execute all queries concurrently
      final results = await Future.wait(queries);

      // Combine results and remove duplicates
      final resultMap = <String, models.Card>{};

      // Add results from cleanName query
      final nameResults = results[0];
      talker.debug('Name search results: ${nameResults.docs.length}');
      for (final doc in nameResults.docs) {
        resultMap[doc.id] = _convertToCard(doc);
      }

      // Add results from cardNumbers query
      final numberResults = results[1];
      talker.debug('Card number search results: ${numberResults.docs.length}');
      for (final doc in numberResults.docs) {
        if (!resultMap.containsKey(doc.id)) {
          resultMap[doc.id] = _convertToCard(doc);
        }
      }

      talker.debug('Total unique Firestore results: ${resultMap.length}');
      return resultMap.values.toList();
    } catch (e, stack) {
      talker.error('Error searching cards in Firestore', e, stack);
      rethrow;
    }
  }

  // Price Methods
  Future<models.Price?> getPrice(String cardId) async {
    final doc = await pricesCollection.doc(cardId).get();
    if (!doc.exists) return null;
    return _convertToPrice(doc);
  }

  Stream<List<models.HistoricalPrice>> watchHistoricalPrices(String cardId) {
    return historicalPricesCollection
        .where('productId', isEqualTo: int.parse(cardId))
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(_convertToHistoricalPrice).toList());
  }

  Future<List<models.HistoricalPrice>> getHistoricalPrices(
    String cardId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query query = historicalPricesCollection
        .where('productId', isEqualTo: int.parse(cardId))
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_convertToHistoricalPrice).toList();
  }

  // Cache Management Methods
  Future<void> updateLastSyncTimestamp(String collection) async {
    await _firestore.collection('syncMetadata').doc(collection).set({
      'lastSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<DateTime?> getLastSyncTimestamp(String collection) async {
    final doc =
        await _firestore.collection('syncMetadata').doc(collection).get();

    if (!doc.exists) return null;

    final timestamp = doc.get('lastSync') as Timestamp?;
    return timestamp?.toDate();
  }

  Future<Set<String>> getUniqueFieldValues(
      String collection, String field) async {
    final snapshot = await _firestore.collection(collection).get();
    final values = <String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['extendedData'] != null) {
        final fieldData = data['extendedData'][field];
        if (fieldData != null && fieldData['value'] != null) {
          values.add(fieldData['value'].toString());
        }
      }
    }

    return values;
  }

  Future<models.CardFilterOptions> getFilterOptions() async {
    return models.CardFilterOptions(
      elements: await getUniqueFieldValues('cards', 'Element'),
      types: await getUniqueFieldValues('cards', 'Type'),
      sets: await getUniqueFieldValues('cards', 'Set'),
      rarities: await getUniqueFieldValues('cards', 'Rarity'),
      costRange: await _getCostRange(),
      powerRange: await _getPowerRange(),
    );
  }

  Future<(int, int)> _getCostRange() async {
    final snapshot = await _firestore
        .collection('cards')
        .orderBy('extendedData.Cost.value')
        .get();

    int minCost = 999;
    int maxCost = 0;

    for (var doc in snapshot.docs) {
      final cost = doc.data()['extendedData']?['Cost']?['value'];
      if (cost != null) {
        final costValue = int.tryParse(cost.toString()) ?? 0;
        minCost = costValue < minCost ? costValue : minCost;
        maxCost = costValue > maxCost ? costValue : maxCost;
      }
    }

    return (minCost, maxCost);
  }

  Future<(int, int)> _getPowerRange() async {
    final snapshot = await _firestore
        .collection('cards')
        .orderBy('extendedData.Power.value')
        .get();

    int minPower = 999999;
    int maxPower = 0;

    for (var doc in snapshot.docs) {
      final power = doc.data()['extendedData']?['Power']?['value'];
      if (power != null) {
        final powerValue = int.tryParse(power.toString()) ?? 0;
        minPower = powerValue < minPower ? powerValue : minPower;
        maxPower = powerValue > maxPower ? powerValue : maxPower;
      }
    }

    return (minPower, maxPower);
  }

  // Cleanup Methods
  Future<void> cleanupOldData(String collection, Duration age) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(age),
    );

    final snapshot = await _firestore
        .collection(collection)
        .where('lastUpdated', isLessThan: cutoff)
        .get();

    final batches = <WriteBatch>[];
    for (var i = 0; i < snapshot.docs.length; i += 500) {
      final batch = _firestore.batch();
      final end =
          (i + 500 < snapshot.docs.length) ? i + 500 : snapshot.docs.length;

      for (var j = i; j < end; j++) {
        batch.delete(snapshot.docs[j].reference);
      }

      batches.add(batch);
    }

    await Future.wait(batches.map((b) => b.commit()));
  }
}
