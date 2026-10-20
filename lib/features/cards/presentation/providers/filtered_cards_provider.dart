// lib/features/cards/presentation/providers/filtered_cards_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'filtered_cards_provider.g.dart';

/// Provider that reactively combines card repository data with current filters
/// This is the Riverpod 3.x way - watch both sources and compute the result
@riverpod
Future<List<models.Card>> filteredCards(Ref ref) async {
  // Watch the card repository for all cards
  final allCards = await ref.watch(cardRepositoryProvider.future);

  // Watch the current filter settings
  final filters = ref.watch(cardFilterProvider);

  talker.debug('Filtering ${allCards.length} cards with filters: ${filters.toString()}');

  // Use the repository's existing applyLocalFilters method
  final repository = ref.read(cardRepositoryProvider.notifier);
  final filteredResult = repository.applyLocalFilters(allCards, filters);

  talker.debug('Filtered to ${filteredResult.length} cards');

  return filteredResult;
}
