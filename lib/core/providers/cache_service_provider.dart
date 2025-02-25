import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/storage/cache_service.dart';

part 'cache_service_provider.g.dart';

@Riverpod(keepAlive: true)
class CacheServiceNotifier extends _$CacheServiceNotifier {
  @override
  Future<CacheService> build() async {
    final cache = CacheService();
    await cache.initialize();
    ref.onDispose(() => cache.dispose());
    return cache;
  }
}
