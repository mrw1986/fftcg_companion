import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fftcg_companion/app/app.dart';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final appDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDir.path);

  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CardAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExtendedDataAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PriceAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PriceDataAdapter());
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(HistoricalPriceAdapter());
  }
  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(HistoricalPriceDataAdapter());
  }

  await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox<models.Card>('cards'),
    Hive.openBox<models.Price>('prices'),
    Hive.openBox<models.HistoricalPrice>('historical_prices'),
    Hive.openBox('cache_metadata'),
  ]);

  final talker = TalkerFlutter.init();

  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
  };

  runApp(
    const ProviderScope(
      child: FFTCGCompanionApp(),
    ),
  );
}
