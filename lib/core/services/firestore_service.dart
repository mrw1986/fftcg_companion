// lib/core/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filter_options.dart';

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

  Future<List<models.Card>> getCards({
    int limit = 20,
    String? startAfterId,
    Query<Object?>? Function(Query<Object?> query)? queryBuilder,
    String? sortField,
    bool descending = false,
  }) async {
    Query query = cardsCollection;

    // Apply custom query modifications if provided
    if (queryBuilder != null) {
      query = queryBuilder(query) ?? query;
    }

    // Apply sorting
    if (sortField != null) {
      query = query.orderBy(sortField, descending: descending);
    } else {
      // Default sorting by productId
      query = query.orderBy('productId', descending: descending);
    }

    // Apply pagination
    if (startAfterId != null) {
      DocumentSnapshot startAfterDoc =
          await cardsCollection.doc(startAfterId).get();
      query = query.startAfterDocument(startAfterDoc);
    }

    // Apply limit
    query = query.limit(limit);

    try {
      final snapshot = await query.get();
      return snapshot.docs.map(_convertToCard).toList();
    } catch (e, stack) {
      talker.error('Error fetching cards', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> searchCards(String query) async {
    try {
      final normalizedQuery = query.toLowerCase().trim();

      // Create compound query
      final nameQuery = cardsCollection
          .where('cleanName', isGreaterThanOrEqualTo: normalizedQuery)
          .where('cleanName', isLessThan: '${normalizedQuery}z')
          .limit(20);

      final numberQuery = cardsCollection
          .where('cardNumbers', arrayContains: normalizedQuery.toUpperCase())
          .limit(20);

      // Execute queries in parallel
      final results = await Future.wait([
        nameQuery.get(),
        numberQuery.get(),
      ]);

      // Combine and deduplicate results
      final cards = <String, models.Card>{};

      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          if (!cards.containsKey(doc.id)) {
            cards[doc.id] = _convertToCard(doc);
          }
        }
      }

      return cards.values.toList();
    } catch (e, stack) {
      talker.error('Error searching cards', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> getFilteredCards(models.CardFilters filters) async {
    try {
      Query query = cardsCollection;

      // Apply filters
      if (filters.elements.isNotEmpty) {
        // Handle multiple elements - requires compound queries
        List<Query> elementQueries = filters.elements.map((element) {
          return cardsCollection.where('extendedData.Element.value',
              isEqualTo: element);
        }).toList();

        // Get results from all element queries
        List<QuerySnapshot> snapshots = await Future.wait(
          elementQueries.map((q) => q.get()),
        );

        // Combine and deduplicate results
        Map<String, DocumentSnapshot> uniqueResults = {};
        for (var snapshot in snapshots) {
          for (var doc in snapshot.docs) {
            uniqueResults[doc.id] = doc;
          }
        }

        // Convert to list of Cards
        return uniqueResults.values.map(_convertToCard).toList();
      }

      if (filters.types.isNotEmpty) {
        query = query.where('extendedData.CardType.value',
            whereIn: filters.types.toList());
      }

      if (filters.categories.isNotEmpty) {
        query = query.where('extendedData.Category.value',
            whereIn: filters.categories.toList());
      }

      if (filters.jobs.isNotEmpty) {
        query = query.where('extendedData.Job.value',
            whereIn: filters.jobs.toList());
      }

      if (filters.rarities.isNotEmpty) {
        query = query.where('extendedData.Rarity.value',
            whereIn: filters.rarities.toList());
      }

      // Handle cost range
      if (filters.minCost != null) {
        query = query.where('extendedData.Cost.value',
            isGreaterThanOrEqualTo: filters.minCost.toString());
      }
      if (filters.maxCost != null) {
        query = query.where('extendedData.Cost.value',
            isLessThanOrEqualTo: filters.maxCost.toString());
      }

      // Apply default sorting
      query = query.orderBy('primaryCardNumber', descending: false);

      talker.debug('Executing filtered query: ${query.parameters}');

      final snapshot = await query.get();
      final results = snapshot.docs.map(_convertToCard).toList();

      talker.debug('Found ${results.length} cards matching filters');
      return results;
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> getSortedCards({
    required String sortField,
    bool descending = false,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = cardsCollection;

      // Map sort field to actual Firestore field path
      String fieldPath = switch (sortField) {
        'name' => 'cleanName',
        'number' => 'primaryCardNumber',
        'cost' => 'extendedData.Cost.value',
        'power' => 'extendedData.Power.value',
        _ => 'primaryCardNumber', // default sort
      };

      query = query.orderBy(fieldPath, descending: descending);

      // Add secondary sort by name for consistent ordering
      if (fieldPath != 'cleanName') {
        query = query.orderBy('cleanName', descending: false);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      query = query.limit(limit);

      talker
          .debug('Executing sorted query: $sortField, descending: $descending');

      final snapshot = await query.get();
      return snapshot.docs.map(_convertToCard).toList();
    } catch (e, stack) {
      talker.error('Error sorting cards', e, stack);
      rethrow;
    }
  }

  models.Card _convertToCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert Timestamp to DateTime
    if (data['lastUpdated'] is Timestamp) {
      data['lastUpdated'] =
          (data['lastUpdated'] as Timestamp).toDate().toIso8601String();
    }

    // Convert extendedData
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
    try {
      final snapshot = await _firestore.collection(collection).get();

      final values = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['extendedData'] != null &&
            data['extendedData'][field] != null &&
            data['extendedData'][field]['value'] != null) {
          values.add(data['extendedData'][field]['value'].toString());
        }
      }

      talker.debug('Found ${values.length} unique values for field: $field');
      return values;
    } catch (e, stack) {
      talker.error('Error getting unique field values', e, stack);
      rethrow;
    }
  }

  Future<CardFilterOptions> getFilterOptions() async {
    try {
      final elements = await getUniqueFieldValues('cards', 'Element');
      final types = await getUniqueFieldValues('cards', 'CardType');
      final categories = await getUniqueFieldValues('cards', 'Category');
      final jobs = await getUniqueFieldValues('cards', 'Job');
      final rarities = await getUniqueFieldValues('cards', 'Rarity');
      final sets = await getUniqueFieldValues('cards', 'Set');
      final (minCost, maxCost) = await _getCostRange();
      final (minPower, maxPower) = await _getPowerRange();

      return CardFilterOptions(
        elements: elements,
        types: types,
        categories: categories,
        jobs: jobs,
        rarities: rarities,
        sets: sets,
        costRange: (minCost, maxCost),
        powerRange: (minPower, maxPower),
      );
    } catch (e, stack) {
      talker.error('Error getting filter options', e, stack);
      rethrow;
    }
  }

  Future<(int, int)> _getCostRange() async {
    try {
      final snapshot = await _firestore
          .collection('cards')
          .orderBy('extendedData.Cost.value')
          .get();

      int minCost = 999;
      int maxCost = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['extendedData']?['Cost']?['value'] != null) {
          final costValue =
              int.tryParse(data['extendedData']['Cost']['value'].toString()) ??
                  0;
          minCost = costValue < minCost ? costValue : minCost;
          maxCost = costValue > maxCost ? costValue : maxCost;
        }
      }

      talker.debug('Cost range: $minCost - $maxCost');
      return (minCost, maxCost);
    } catch (e, stack) {
      talker.error('Error getting cost range', e, stack);
      rethrow;
    }
  }

  Future<(int, int)> _getPowerRange() async {
    try {
      final snapshot = await _firestore
          .collection('cards')
          .orderBy('extendedData.Power.value')
          .get();

      int minPower = 999999;
      int maxPower = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['extendedData']?['Power']?['value'] != null) {
          final powerValue =
              int.tryParse(data['extendedData']['Power']['value'].toString()) ??
                  0;
          minPower = powerValue < minPower ? powerValue : minPower;
          maxPower = powerValue > maxPower ? powerValue : maxPower;
        }
      }

      talker.debug('Power range: $minPower - $maxPower');
      return (minPower, maxPower);
    } catch (e, stack) {
      talker.error('Error getting power range', e, stack);
      rethrow;
    }
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
