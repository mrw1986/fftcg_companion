// lib/features/collection/presentation/providers/collection_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart'; // Import Hive
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart'; // Keep using the same model
import 'package:fftcg_companion/core/utils/logger.dart';

// Renamed provider for Collection page
final collectionFilterProvider =
    StateNotifierProvider<CollectionFilterNotifier, CardFilters>((ref) {
  // Load initial state from persistence
  return CollectionFilterNotifier._loadInitial();
});

// Renamed notifier for Collection page
class CollectionFilterNotifier extends StateNotifier<CardFilters> {
  static const _boxName = 'settings';
  static const _filtersKey =
      'collection_filters'; // Unique key for collection filters

  // Private constructor used by the factory - FIXED use_super_parameters
  CollectionFilterNotifier._(super.initialState);

  // Factory constructor to load initial state
  factory CollectionFilterNotifier._loadInitial() {
    try {
      if (!Hive.isBoxOpen(_boxName)) {
        Hive.openBox(_boxName); // Consider async open if issues arise
      }
      final box = Hive.box(_boxName);
      final savedData = box.get(_filtersKey);

      if (savedData is Map) {
        talker.debug('Loading saved collection filters from Hive.');
        // Use dart_mappable to deserialize
        return CollectionFilterNotifier._(
            CardFiltersMapper.fromMap(Map<String, dynamic>.from(savedData)));
      } else {
        talker.debug('No saved collection filters found, using defaults.');
        return CollectionFilterNotifier._(const CardFilters());
      }
    } catch (e, stack) {
      talker.error('Error loading collection filters from Hive', e, stack);
      return CollectionFilterNotifier._(
          const CardFilters()); // Fallback to default
    }
  }

  // Helper to save state
  Future<void> _saveFilters() async {
    try {
      final box = Hive.box(_boxName);
      // Use dart_mappable to serialize
      await box.put(_filtersKey, state.toMap());
      talker.debug('Saved collection filters to Hive.');
    } catch (e, stack) {
      talker.error('Error saving collection filters to Hive', e, stack);
    }
  }

  // Flag to indicate when a set is being toggled
  // This helps prevent unnecessary recalculations
  bool _isTogglingSet = false;
  bool get isTogglingSet => _isTogglingSet;

  void toggleElement(String element) {
    final elements = Set<String>.from(state.elements);
    if (elements.contains(element)) {
      elements.remove(element);
    } else {
      elements.add(element);
    }
    state = state.copyWith(elements: elements);
    talker.debug('Collection Filter updated - Elements: $elements');
    _saveFilters(); // Save state
  }

  void toggleType(String type) {
    final types = Set<String>.from(state.types);
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(types: types);
    _saveFilters(); // Save state
  }

  void setCostRange(int? min, int? max) {
    state = state.copyWith(minCost: min, maxCost: max);
    _saveFilters(); // Save state
  }

  void setPowerRange(int? min, int? max) {
    state = state.copyWith(minPower: min, maxPower: max);
    _saveFilters(); // Save state
  }

  void toggleRarity(String rarity) {
    final rarities = Set<String>.from(state.rarities);
    if (rarities.contains(rarity)) {
      rarities.remove(rarity);
    } else {
      rarities.add(rarity);
    }
    state = state.copyWith(rarities: rarities);
    _saveFilters(); // Save state
  }

  void toggleCategory(String category) {
    final categories = Set<String>.from(state.categories);
    if (categories.contains(category)) {
      categories.remove(category);
    } else {
      categories.add(category);
    }
    state = state.copyWith(categories: categories);
    talker.debug('Collection Filter updated - Categories: $categories');
    _saveFilters(); // Save state
  }

  void toggleSet(String setId) {
    _isTogglingSet = true;

    try {
      final set = Set<String>.from(state.set);
      if (set.contains(setId)) {
        set.remove(setId);
      } else {
        set.add(setId);
      }
      state = state.copyWith(set: set);
      _saveFilters(); // Save state
    } finally {
      // Reset the flag after a short delay to allow the UI to update
      Future.delayed(const Duration(milliseconds: 500), () {
        _isTogglingSet = false;
      });
    }
  }

  void toggleShowSealedProducts() {
    state = state.copyWith(showSealedProducts: !state.showSealedProducts);
    _saveFilters(); // Save state
  }

  // --- ADDED: Method to toggle favorites filter ---
  void toggleShowFavoritesOnly() {
    state = state.copyWith(showFavoritesOnly: !state.showFavoritesOnly);
    _saveFilters();
  }

  // --- ADDED: Method to toggle wishlist filter ---
  void toggleShowWishlistOnly() {
    state = state.copyWith(showWishlistOnly: !state.showWishlistOnly);
    _saveFilters();
  }
  // --- End Added Methods ---

  void reset() {
    state = const CardFilters();
    _saveFilters(); // Save state (reset)
  }

  void setSorting(String field, bool descending) {
    state = state.copyWith(
      sortField: field,
      sortDescending: descending,
    );
    _saveFilters(); // Save state
  }
}
