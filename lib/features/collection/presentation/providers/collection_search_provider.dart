// lib/features/collection/presentation/providers/collection_search_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart'; // Import Hive
import 'package:fftcg_companion/core/utils/logger.dart'; // Import Logger

// --- Refactored to NotifierProvider ---
final collectionSearchQueryProvider =
    NotifierProvider.autoDispose<CollectionSearchQueryNotifier, String>(() {
  return CollectionSearchQueryNotifier();
});

class CollectionSearchQueryNotifier extends AutoDisposeNotifier<String> {
  static const _boxName = 'settings';
  static const _queryKey = 'collection_search_query'; // Unique key

  late Box _box;

  @override
  String build() {
    // Load initial state synchronously during build
    _openBox(); // Ensure box is open
    final savedQuery = _box.get(_queryKey);
    if (savedQuery is String) {
      talker.debug(
          'Loading saved collection search query from Hive: "$savedQuery"');
      return savedQuery;
    }
    talker.debug(
        'No saved collection search query found, using default (empty).');
    return ''; // Default to empty string
  }

  void _openBox() {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        // Note: Synchronous openBox might block UI if called frequently during init.
        // Consider async open elsewhere if performance issues arise.
        Hive.openBox(_boxName);
      }
      _box = Hive.box(_boxName);
    } catch (e, stack) {
      talker.error(
          'Error opening Hive box for collection search query', e, stack);
      // Handle error appropriately
    }
  }

  Future<void> setQuery(String newQuery) async {
    if (state != newQuery) {
      state = newQuery;
      await _saveQuery(newQuery);
    }
  }

  Future<void> _saveQuery(String query) async {
    try {
      if (!_box.isOpen) _openBox(); // Ensure box is open before writing
      await _box.put(_queryKey, query);
      talker.debug('Saved collection search query to Hive: "$query"');
    } catch (e, stack) {
      talker.error('Error saving collection search query to Hive', e, stack);
    }
  }
}
// --- End Refactor ---

// Provider for the collection search query text controller
// Updated to watch the NotifierProvider's state
final collectionSearchControllerProvider =
    StateProvider.autoDispose<TextEditingController>(
  (ref) {
    // Initialize controller with the query from the NotifierProvider
    final initialQuery = ref.watch(collectionSearchQueryProvider);
    final controller = TextEditingController(text: initialQuery);

    // Update the Notifier state when the controller text changes
    controller.addListener(() {
      // Use read to avoid dependency loop and call the method on the notifier
      ref
          .read(collectionSearchQueryProvider.notifier)
          .setQuery(controller.text);
    });

    // Dispose the controller when the provider is disposed
    ref.onDispose(() => controller.dispose());

    return controller;
  },
);
