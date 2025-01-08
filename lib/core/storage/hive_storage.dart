// lib/core/storage/hive_storage.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:fftcg_companion/features/models.dart';

class HiveStorage {
  static Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    // Register adapters from hive_adapters.dart
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CardAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExtendedDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PriceAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PriceDataAdapter());
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HistoricalPriceAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(HistoricalPriceDataAdapter());
    }

    // Open boxes
    await Future.wait([
      Hive.openBox<Card>('cards'),
      Hive.openBox<Price>('prices'),
      Hive.openBox<HistoricalPrice>('historical_prices'),
      Hive.openBox('settings'),
      Hive.openBox('cache_metadata'),
    ]);
  }
}
