// lib/core/services/query_builder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fftcg_companion/core/storage/fftcg_cache_manager.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class FFTCGQueryBuilder {
  final CollectionReference _collection;
  final List<QueryPredicate> _filters = [];
  String? _sortField;
  bool _isDescending = false;
  int _limit = 20;
  DocumentSnapshot? _lastDoc;
  bool _useCache = true;

  FFTCGQueryBuilder(this._collection);

  /// Disable cache for this query
  void disableCache() {
    _useCache = false;
  }

  /// Add a filter for equality
  void addFilter(String field, dynamic value) {
    _filters.add(QueryPredicate(field: field, isEqualTo: value));
  }

  /// Add a filter for range comparisons
  void addRangeFilter({
    required String field,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
  }) {
    _filters.add(QueryPredicate(
      field: field,
      isGreaterThan: isGreaterThan,
      isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
      isLessThan: isLessThan,
      isLessThanOrEqualTo: isLessThanOrEqualTo,
    ));
  }

  /// Add a filter for inclusion in a list
  void addWhereInFilter(String field, List<dynamic> values) {
    _filters.add(QueryPredicate(field: field, whereIn: values));
  }

  /// Set the field for sorting
  void setSortField(String field, {bool descending = false}) {
    _sortField = field;
    _isDescending = descending;
  }

  /// Set the limit for the number of results
  void setLimit(int limit) {
    _limit = limit;
  }

  /// Set the starting document for pagination
  void setLastDoc(DocumentSnapshot? doc) {
    _lastDoc = doc;
  }

  /// Execute the query, with caching logic
  Future<List<Map<String, dynamic>>> execute() async {
    try {
      // Generate query key for caching
      final cacheManager = FFTCGCacheManager();
      final queryKey = cacheManager.generateQueryKey(_buildQueryParams());

      // Check cache
      if (_useCache) {
        final cachedResult = cacheManager.getCachedQueryResult(queryKey);
        if (cachedResult != null) {
          talker.debug('Returning cached query result');
          return cachedResult.map((card) => card.data).toList();
        }
      }

      // Build Firestore query
      Query query = _collection;
      for (final filter in _filters) {
        query = query.where(
          filter.field!,
          isEqualTo: filter.isEqualTo,
          isGreaterThan: filter.isGreaterThan,
          isGreaterThanOrEqualTo: filter.isGreaterThanOrEqualTo,
          isLessThan: filter.isLessThan,
          isLessThanOrEqualTo: filter.isLessThanOrEqualTo,
          whereIn: filter.whereIn,
        );
      }
      if (_sortField != null) {
        query = query.orderBy(_sortField!, descending: _isDescending);
      }
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      query = query.limit(_limit);

      // Execute query
      final querySnapshot = await query.get();

      // Cache results
      if (_useCache) {
        await cacheManager.cacheQueryResult(
          queryKey,
          querySnapshot.docs,
        );
      }

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e, stack) {
      talker.error('Error executing query', e, stack);
      rethrow;
    }
  }

  /// Build query parameters for caching
  Map<String, dynamic> _buildQueryParams() => {
        'filters': _filters.map((f) => f.toString()).toList(),
        'sort': {'field': _sortField, 'descending': _isDescending},
        'limit': _limit,
        'lastDocId': _lastDoc?.id,
      };
}

/// Represents a query condition
class QueryPredicate {
  final String? field;
  final dynamic isEqualTo;
  final dynamic isGreaterThan;
  final dynamic isGreaterThanOrEqualTo;
  final dynamic isLessThan;
  final dynamic isLessThanOrEqualTo;
  final List<dynamic>? whereIn;

  QueryPredicate({
    this.field,
    this.isEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.whereIn,
  });

  @override
  String toString() {
    return {
      'field': field,
      'isEqualTo': isEqualTo,
      'isGreaterThan': isGreaterThan,
      'isGreaterThanOrEqualTo': isGreaterThanOrEqualTo,
      'isLessThan': isLessThan,
      'isLessThanOrEqualTo': isLessThanOrEqualTo,
      'whereIn': whereIn,
    }.toString();
  }
}
