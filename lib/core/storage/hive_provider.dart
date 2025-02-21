import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/storage/hive_storage.dart';

part 'hive_provider.g.dart';

@Riverpod(keepAlive: true)
HiveStorage hiveStorage(ref) {
  final storage = HiveStorage();
  storage.initialize();
  return storage;
}
