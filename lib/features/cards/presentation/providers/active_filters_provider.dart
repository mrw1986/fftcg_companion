// lib/features/cards/presentation/providers/active_filters_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';

part 'active_filters_provider.g.dart';

@riverpod
int activeFilterCount(ref, CardFilters filters) {
  int count = 0;

  // Count active element filters
  if (filters.elements.isNotEmpty) count++;

  // Count active type filters
  if (filters.types.isNotEmpty) count++;

  // Count active rarity filters
  if (filters.rarities.isNotEmpty) count++;

  // Count active set filters
  if (filters.set.isNotEmpty) count++;

  // Count active cost range filter
  if (filters.minCost != null || filters.maxCost != null) count++;

  // Count active power range filter
  if (filters.minPower != null || filters.maxPower != null) count++;

  return count;
}
