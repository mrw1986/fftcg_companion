// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

import 'package:fftcg_companion/app/app.dart';
import 'package:fftcg_companion/firebase_options.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/core/storage/cache_persistence.dart';

final _container = ProviderContainer();

Future<void> initializeApp() async {
  // Configure Talker for logging
  talker.configure(
    settings: TalkerSettings(
      enabled: true,
      useHistory: true,
      maxHistoryItems: 1000,
      useConsoleLogs: false, // Disable console logs except for errors
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

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize CachePersistence
    await CachePersistence.initialize();

    // Initialize image cache
    CardImageCacheManager.initCache();

    talker.debug('Basic initialization completed');
  } catch (e, stack) {
    talker.error('Error during basic initialization', e, stack);
    rethrow;
  }
}

void main() {
  // Ensure Flutter bindings are initialized in the same zone as runApp
  runZonedGuarded(() async {
    // Preserve the native splash screen until initialization is complete
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    try {
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
                printProviderAdded: false,
                printProviderUpdated: false,
                printProviderDisposed: false,
                printProviderFailed: true,
                printStateFullData: false,
              ),
            ),
          ],
          child: const FFTCGCompanionApp(),
        ),
      );

      // Remove the native splash screen after the app is initialized
      FlutterNativeSplash.remove();

      // Dispose the temporary container after app is running
      _container.dispose();
    } catch (e, stack) {
      talker.error('Error during app initialization', e, stack);
    }
  }, (error, stackTrace) {
    talker.handle(error, stackTrace);
  });
}
