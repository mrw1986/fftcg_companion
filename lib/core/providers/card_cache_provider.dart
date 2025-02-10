import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/storage/card_cache.dart';

part 'card_cache_provider.g.dart';

@Riverpod(keepAlive: true)
class CardCacheNotifier extends _$CardCacheNotifier {
  @override
  Future<CardCache> build() async {
    final cache = CardCache();
    await cache.initialize();
    ref.onDispose(() => cache.dispose());
    return cache;
  }
}
