// lib/features/cards/presentation/providers/set_card_count_provider.dart
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/features/repositories.dart'; // Update this import

part 'set_card_count_provider.g.dart';

@riverpod
Future<int> setCardCount(ref, String setId) async {
  return ErrorBoundary.runAsync(
    () async {
      final firestoreService = ref.watch(firestoreServiceProvider);

      try {
        final query =
            firestoreService.cardsCollection.where('set', arrayContains: setId);
        final snapshot = await query.count().get();

        talker.debug('Got card count for set $setId: ${snapshot.count ?? 0}');
        return snapshot.count ?? 0;
      } catch (e, stack) {
        talker.error('Error getting card count for set $setId', e, stack);
        return 0;
      }
    },
    context: 'setCardCount($setId)',
    fallback: 0,
  );
}

@Riverpod(keepAlive: true)
class SetCardCountCache extends _$SetCardCountCache {
  final _cache = <String, int>{};

  @override
  Future<int> build(String setId) async {
    if (_cache.containsKey(setId)) {
      return _cache[setId]!;
    }

    final count = await ref.watch(setCardCountProvider(setId).future);
    _cache[setId] = count;
    return count;
  }

  void invalidateCache() {
    _cache.clear();
    ref.invalidateSelf();
  }
}
