import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/providers/card_cache_provider.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';

part 'initialization_provider.g.dart';

@Riverpod(keepAlive: true)
Future<void> initialization(ref) async {
  // Initialize cache first
  await ref.read(cardCacheNotifierProvider.future);

  // Then initialize repository and load cards
  final repository = ref.read(cardRepositoryProvider.notifier);
  await repository.initialize();
}
