import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

final filterProvider =
    StateNotifierProvider<FilterNotifier, CardFilters>((ref) {
  return FilterNotifier();
});

class FilterNotifier extends StateNotifier<CardFilters> {
  FilterNotifier() : super(const CardFilters());

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
    talker.debug('Filter updated - Elements: $elements');
  }

  void toggleType(String type) {
    final types = Set<String>.from(state.types);
    if (types.contains(type)) {
      types.remove(type);
    } else {
      types.add(type);
    }
    state = state.copyWith(types: types);
  }

  void setCostRange(int? min, int? max) {
    state = state.copyWith(minCost: min, maxCost: max);
  }

  void setPowerRange(int? min, int? max) {
    state = state.copyWith(minPower: min, maxPower: max);
  }

  void toggleRarity(String rarity) {
    final rarities = Set<String>.from(state.rarities);
    if (rarities.contains(rarity)) {
      rarities.remove(rarity);
    } else {
      rarities.add(rarity);
    }
    state = state.copyWith(rarities: rarities);
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
    } finally {
      // Reset the flag after a short delay to allow the UI to update
      Future.delayed(const Duration(milliseconds: 500), () {
        _isTogglingSet = false;
      });
    }
  }

  void toggleShowSealedProducts() {
    state = state.copyWith(showSealedProducts: !state.showSealedProducts);
  }

  void reset() {
    state = const CardFilters();
  }

  void setSorting(String field, bool descending) {
    state = state.copyWith(
      sortField: field,
      sortDescending: descending,
    );
  }
}
