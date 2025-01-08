// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:fftcg_companion/app/app.dart';
import 'package:fftcg_companion/core/storage/hive_adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/firebase_options.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configure Talker
    talker.configure(
      settings: TalkerSettings(
        enabled: true,
        useHistory: true,
        maxHistoryItems: 1000,
        useConsoleLogs: true,
      ),
    );

    // Configure global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      talker.handle(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      talker.handle(error, stack);
      return true;
    };

    final appDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDir.path);

    // Register adapters
    _registerHiveAdapters();

    // Clear existing boxes to prevent corruption
    await _clearExistingBoxes();

    // Open boxes
    try {
      await Future.wait([
        Hive.openBox('settings'),
        Hive.openBox<models.Card>('cards'),
        Hive.openBox<models.Price>('prices'),
        Hive.openBox<models.HistoricalPrice>('historical_prices'),
        Hive.openBox('cache_metadata'),
      ]);
    } catch (e, stack) {
      talker.error('Error opening Hive boxes', e, stack);
      // If opening boxes fails, delete and recreate them
      await _clearExistingBoxes();
      await Future.wait([
        Hive.openBox('settings'),
        Hive.openBox<models.Card>('cards'),
        Hive.openBox<models.Price>('prices'),
        Hive.openBox<models.HistoricalPrice>('historical_prices'),
        Hive.openBox('cache_metadata'),
      ]);
    }

    runApp(
      ProviderScope(
        observers: [
          TalkerRiverpodObserver(
            talker: talker,
            settings: const TalkerRiverpodLoggerSettings(
              enabled: true,
              printProviderAdded: true, // Changed from printCreations
              printProviderUpdated: true, // Changed from printChanges
              printProviderDisposed: true, // Changed from printDisposals
              printProviderFailed: true, // Added this
              printStateFullData: true, // This one was correct
            ),
          ),
        ],
        child: const FFTCGCompanionApp(),
      ),
    );
  }, (error, stackTrace) {
    talker.handle(error, stackTrace);
  });
}

void _registerHiveAdapters() {
  try {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(CardAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExtendedDataAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PriceAdapter());
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(PriceDataAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HistoricalPriceAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(HistoricalPriceDataAdapter());
    }
  } catch (e, stack) {
    talker.error('Error registering Hive adapters', e, stack);
    rethrow;
  }
}

Future<void> _clearExistingBoxes() async {
  try {
    await Future.wait([
      Hive.deleteBoxFromDisk('cards'),
      Hive.deleteBoxFromDisk('prices'),
      Hive.deleteBoxFromDisk('historical_prices'),
      Hive.deleteBoxFromDisk('settings'),
      Hive.deleteBoxFromDisk('cache_metadata'),
    ]);
  } catch (e, stack) {
    talker.error('Error clearing Hive boxes', e, stack);
  }
}
