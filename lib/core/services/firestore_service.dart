import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filter_options.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'firestore_service.g.dart';

class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  Map<String, dynamic> toJson() => {
        'items': (items as List<dynamic>)
            .map((e) => (e as dynamic).toJson())
            .toList(),
        'hasMore': hasMore,
        'timestamp': DateTime.now().toIso8601String(),
      };

  static PaginatedResult<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResult<T>(
      items: (json['items'] as List)
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      hasMore: json['hasMore'] as bool,
      lastDocument: null, // Can't restore from JSON
    );
  }
}

@riverpod
FirestoreService firestoreService(ref) {
  return FirestoreService(FirebaseFirestore.instance);
}

class FirestoreService {
  final FirebaseFirestore _firestore;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static const String _queryCacheBox = 'query_cache';

  // Helper method for case-insensitive text handling
  String normalizeText(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.toLowerCase().trim();
  }

  FirestoreService(this._firestore) {
    _initCache();
  }

  Future<void> _initCache() async {
    if (!Hive.isBoxOpen(_queryCacheBox)) {
      await Hive.openBox(_queryCacheBox);
      await _cleanOldCache();
    }
  }

  Future<void> _cleanOldCache() async {
    try {
      final box = await Hive.openBox(_queryCacheBox);
      final now = DateTime.now();

      final keysToDelete = box.keys.where((key) {
        final cached = box.get(key);
        if (cached == null || cached['timestamp'] == null) return true;

        final timestamp = DateTime.parse(cached['timestamp']);
        return now.difference(timestamp) > _cacheDuration;
      }).toList();

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        talker.debug('Cleaned ${keysToDelete.length} old cache entries');
      }
    } catch (e, stack) {
      talker.error('Error cleaning old cache', e, stack);
    }
  }

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

    try {
      // Apply custom query modifications if provided
      if (queryBuilder != null) {
        query = queryBuilder(query) ?? query;
      }

      // Apply sorting
      if (sortField != null) {
        // Handle nested fields properly
        switch (sortField) {
          case 'cost':
            query = query.orderBy('extendedData.Cost.value',
                descending: descending);
            break;
          case 'power':
            query = query.orderBy('extendedData.Power.value',
                descending: descending);
            break;
          case 'name':
            query = query.orderBy('cleanName', descending: descending);
            break;
          default:
            query = query.orderBy(sortField, descending: descending);
        }
      } else {
        // Default sorting by lastUpdated for freshness
        query = query.orderBy('lastUpdated', descending: true);
      }

      // Apply pagination
      if (startAfterId != null) {
        DocumentSnapshot startAfterDoc =
            await cardsCollection.doc(startAfterId).get();
        query = query.startAfterDocument(startAfterDoc);
      }

      // Apply limit
      query = query.limit(limit);

      // Execute query
      final snapshot = await query.get();

      // Convert documents with error handling
      final cards = <models.Card>[];
      for (final doc in snapshot.docs) {
        try {
          final card = _convertToCard(doc);
          cards.add(card);
        } catch (e, stack) {
          talker.error(
              'Error converting document ${doc.id}, skipping', e, stack);
          // Continue processing other documents
          continue;
        }
      }

      return cards;
    } catch (e, stack) {
      talker.error('Error fetching cards', e, stack);
      rethrow;
    }
  }

  Future<List<models.Card>> getFilteredCards(models.CardFilters filters) async {
    try {
      Query query = cardsCollection;

      // Apply filters
      if (filters.elements.isNotEmpty) {
        // Use array-contains-any for Elements since we can query multiple values
        query = query.where('extendedData.Elements.value',
            arrayContainsAny: filters.elements.toList());
      }

      if (filters.types.isNotEmpty) {
        query = query.where('extendedData.CardType.value',
            whereIn: filters.types.toList());
      }

      // Handle numeric fields with proper paths
      if (filters.minCost != null) {
        query = query.where('extendedData.Cost.value',
            isGreaterThanOrEqualTo: filters.minCost);
      }

      if (filters.maxCost != null) {
        query = query.where('extendedData.Cost.value',
            isLessThanOrEqualTo: filters.maxCost);
      }

      if (filters.minPower != null) {
        query = query.where('extendedData.Power.value',
            isGreaterThanOrEqualTo: filters.minPower);
      }

      if (filters.maxPower != null) {
        query = query.where('extendedData.Power.value',
            isLessThanOrEqualTo: filters.maxPower);
      }

      // Category filter
      if (filters.categories.isNotEmpty) {
        query = query.where('extendedData.Category.value',
            whereIn: filters.categories.toList());
      }

      // Job filter
      if (filters.jobs.isNotEmpty) {
        query = query.where('extendedData.Job.value',
            whereIn: filters.jobs.toList());
      }

      // Set filter
      if (filters.sets.isNotEmpty) {
        query = query.where('extendedData.Set.value',
            whereIn: filters.sets.toList());
      }

      // Rarity filter
      if (filters.rarities.isNotEmpty) {
        query = query.where('extendedData.Rarity.value',
            whereIn: filters.rarities.toList());
      }

      // Apply default sorting
      query = query.orderBy('lastUpdated', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map(_convertToCard).toList();
    } catch (e, stack) {
      talker.error('Error applying filters', e, stack);
      rethrow;
    }
  }

  Future<PaginatedResult<models.Card>> getSortedCards({
    required String sortField,
    bool descending = false,
    DocumentSnapshot? startAfter,
    int limit = 50,
  }) async {
    try {
      Query query = cardsCollection;

      // Apply sorting based on field type
      switch (sortField) {
        case 'cost':
          query = query
              .orderBy('extendedData.Cost.value', descending: descending)
              .orderBy('cleanName', descending: false);
          break;
        case 'power':
          query = query
              .orderBy('extendedData.Power.value', descending: descending)
              .orderBy('cleanName', descending: false);
          break;
        case 'name':
          query = query.orderBy('cleanName', descending: descending);
          break;
        case 'element':
          query = query
              .orderBy('extendedData.Elements.value', descending: descending)
              .orderBy('cleanName', descending: false);
          break;
        default:
          query = query.orderBy('lastUpdated', descending: true);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      query = query.limit(limit);

      final snapshot = await query.get();
      final cards = snapshot.docs.map(_convertToCard).toList();

      return PaginatedResult(
        items: cards,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length >= limit,
      );
    } catch (e, stack) {
      talker.error('Error sorting cards', e, stack);
      rethrow;
    }
  }

  models.Card _convertToCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      talker.debug('Converting document data: $data');

      // Handle extendedData first
      final extendedDataMap = <String, models.ExtendedData>{};
      if (data['extendedData'] != null) {
        (data['extendedData'] as Map<String, dynamic>).forEach((key, value) {
          extendedDataMap[key] = models.ExtendedData(
            name: value['displayName'] ?? key,
            displayName: value['displayName'] ?? key,
            value: value['value'],
          );
        });
      }

      // Handle timestamps
      final lastUpdated = data['lastUpdated'] is Timestamp
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now();

      return models.Card(
        productId: data['productId'] as int? ?? 0,
        name: data['name'] as String? ?? 'Unknown',
        cleanName: data['cleanName'] as String? ?? 'Unknown',
        highResUrl: data['highResUrl'] as String? ?? '',
        lowResUrl: data['lowResUrl'] as String? ?? '',
        fullResUrl: data['fullResUrl'] as String? ?? '',
        lastUpdated: lastUpdated,
        groupId: data['groupId'] as int? ?? 0,
        isNonCard: data['isNonCard'] as bool? ?? false,
        cardNumbers: data['cardNumbers'] != null
            ? List<String>.from(data['cardNumbers'])
            : [],
        primaryCardNumber: data['primaryCardNumber'] as String? ?? '',
        extendedData: extendedDataMap,
      );
    } catch (e, stack) {
      talker.error('Error converting document ${doc.id} to Card', e, stack);
      rethrow;
    }
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
      // Check cache first
      final box = await Hive.openBox(_queryCacheBox);
      final cacheKey = '${collection}_${field}_values';
      final cached = box.get(cacheKey);

      if (cached != null) {
        final timestamp = DateTime.parse(cached['timestamp']);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          talker.debug('Returning cached values for $field');
          return Set<String>.from(cached['values']);
        }
      }

      // If not cached or cache expired, fetch from Firestore
      final snapshot = await _firestore
          .collection(collection)
          .where('extendedData.$field', isNull: false)
          .get();

      final values = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['extendedData']?[field]?['value'] != null) {
          values.add(data['extendedData'][field]['value'].toString());
        }
      }

      // Cache the results
      await box.put(cacheKey, {
        'values': values.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });

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
      // Check cache first
      final box = await Hive.openBox(_queryCacheBox);
      final cacheKey = 'cost_range';
      final cached = box.get(cacheKey);

      if (cached != null) {
        final timestamp = DateTime.parse(cached['timestamp']);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return (cached['min'] as int, cached['max'] as int);
        }
      }

      final snapshot = await _firestore
          .collection('cards')
          .where('extendedData.Cost.value', isNull: false)
          .get();

      int minCost = 999;
      int maxCost = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final costValue = int.tryParse(
                data['extendedData']?['Cost']?['value']?.toString() ?? '') ??
            0;

        if (costValue > 0) {
          // Only consider valid costs
          minCost = costValue < minCost ? costValue : minCost;
          maxCost = costValue > maxCost ? costValue : maxCost;
        }
      }

      // Cache the results
      await box.put(cacheKey, {
        'min': minCost,
        'max': maxCost,
        'timestamp': DateTime.now().toIso8601String(),
      });

      talker.debug('Cost range: $minCost - $maxCost');
      return (minCost, maxCost);
    } catch (e, stack) {
      talker.error('Error getting cost range', e, stack);
      rethrow;
    }
  }

  Future<(int, int)> _getPowerRange() async {
    try {
      // Check cache first
      final box = await Hive.openBox(_queryCacheBox);
      final cacheKey = 'power_range';
      final cached = box.get(cacheKey);

      if (cached != null) {
        final timestamp = DateTime.parse(cached['timestamp']);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return (cached['min'] as int, cached['max'] as int);
        }
      }

      final snapshot = await _firestore
          .collection('cards')
          .where('extendedData.Power.value', isNull: false)
          .get();

      int minPower = 999999;
      int maxPower = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final powerValue = int.tryParse(
                data['extendedData']?['Power']?['value']?.toString() ?? '') ??
            0;

        if (powerValue > 0) {
          // Only consider valid power values
          minPower = powerValue < minPower ? powerValue : minPower;
          maxPower = powerValue > maxPower ? powerValue : maxPower;
        }
      }

      // Cache the results
      await box.put(cacheKey, {
        'min': minPower,
        'max': maxPower,
        'timestamp': DateTime.now().toIso8601String(),
      });

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

  Future<void> preloadFilterOptions() async {
    try {
      talker.debug('Preloading filter options...');
      await getFilterOptions();
      talker.debug('Filter options preloaded successfully');
    } catch (e, stack) {
      talker.error('Error preloading filter options', e, stack);
    }
  }
}
