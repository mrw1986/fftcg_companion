// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'package:fftcg_companion/app/app.dart';
import 'package:fftcg_companion/firebase_options.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_options_provider.dart';
import 'package:fftcg_companion/core/storage/cache_persistence.dart';

final _container = ProviderContainer();

Future<void> initializeApp() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Talker for logging
  talker.configure(
    settings: TalkerSettings(
      enabled: true,
      useHistory: true,
      maxHistoryItems: 1000,
      useConsoleLogs: true,
    ),
  );

  try {
    // Initialize Hive first
    await Hive.initFlutter();

    // Open required boxes before any other initialization
    await Future.wait([
      Hive.openBox<Map>('sort_cache'),
      Hive.openBox(
          'settings'), // Settings box should be dynamic to store different types
      Hive.openBox('cache_metadata'),
    ]);

    talker.debug('Hive boxes initialized successfully');

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    talker.debug('Firebase initialized successfully');

    // Initialize CachePersistence
    await CachePersistence.initialize();
    talker.debug('Cache persistence initialized');

    // Initialize image cache
    CardImageCacheManager.initCache();
    talker.debug('Image cache initialized successfully');

    // Pre-load filter options but don't await
    _container.read(filterOptionsNotifierProvider);
    talker.debug('Filter options loading started');
  } catch (e, stack) {
    talker.error('Error during initialization', e, stack);
    rethrow;
  }
}

Future<void> main() async {
  await runZonedGuarded(() async {
    await initializeApp();

    // Configure error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      talker.handle(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      talker.handle(error, stack);
      return true;
    };

    runApp(
      ProviderScope(
        observers: [
          TalkerRiverpodObserver(
            talker: talker,
            settings: const TalkerRiverpodLoggerSettings(
              enabled: true,
              printProviderAdded: true,
              printProviderUpdated: true,
              printProviderDisposed: true,
              printProviderFailed: true,
              printStateFullData: true,
            ),
          ),
        ],
        child: const FFTCGCompanionApp(),
      ),
    );

    // Dispose the temporary container after app is running
    _container.dispose();
  }, (error, stackTrace) {
    talker.handle(error, stackTrace);
  });
}
