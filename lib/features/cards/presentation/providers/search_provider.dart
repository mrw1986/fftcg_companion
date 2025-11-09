// lib/features/cards/presentation/providers/search_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart'; // Import Hive
import 'package:fftcg_companion/core/utils/logger.dart'; // Import Logger

// --- Refactored to NotifierProvider ---
final cardSearchQueryProvider =
    NotifierProvider.autoDispose<CardSearchQueryNotifier, String>(() {
  return CardSearchQueryNotifier();
});

class CardSearchQueryNotifier extends AutoDisposeNotifier<String> {
  static const _boxName = 'settings';
  static const _queryKey = 'card_search_query'; // Unique key

  late Box _box;

  @override
  String build() {
    // Load initial state synchronously during build
    _openBox(); // Ensure box is open
    final savedQuery = _box.get(_queryKey);
    if (savedQuery is String) {
      talker.debug('Loading saved card search query from Hive: "$savedQuery"');
      return savedQuery;
    }
    talker.debug('No saved card search query found, using default (empty).');
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
      talker.error('Error opening Hive box for card search query', e, stack);
      // Handle error appropriately, maybe rethrow or use a dummy box
      // For now, we'll let it potentially fail later if box isn't open.
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
      talker.debug('Saved card search query to Hive: "$query"');
    } catch (e, stack) {
      talker.error('Error saving card search query to Hive', e, stack);
    }
  }
}
// --- End Refactor ---

// Provider for the Cards page search query text controller
final cardSearchControllerProvider =
    StateProvider.autoDispose<TextEditingController>(
  (ref) {
    // Initialize controller without watching the query to avoid recreation
    final controller = TextEditingController();

    // Get initial query and set it without triggering listener
    final initialQuery = ref.read(cardSearchQueryProvider);
    controller.text = initialQuery;

    // Define the listener function
    void listener() {
      // Use read to avoid dependency loop and call the method on the notifier
      ref.read(cardSearchQueryProvider.notifier).setQuery(controller.text);
    }

    // Update the Notifier state when the controller text changes
    controller.addListener(listener);

    // Dispose the controller when the provider is disposed
    ref.onDispose(() {
      // Remove the listener first to prevent issues during disposal
      controller.removeListener(listener);
      // Use a microtask to defer disposal to avoid race conditions
      Future.microtask(() {
        controller.dispose();
      });
    });

    return controller;
  },
);
