// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fftcg_companion/app/app.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:fftcg_companion/firebase_options.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/core/storage/cache_persistence.dart';

final _container = ProviderContainer();

Future<void> initializeApp() async {
  // Initialize Talker first
  initializeTalker();

  try {
    // Initialize Hive first
    await Hive.initFlutter();

    // Open required boxes before any other initialization
    await Future.wait([
      Hive.openBox<Map>('sort_cache'),
      Hive.openBox('settings').then((box) {
        talker.debug('Settings box opened successfully');
        talker.debug('Settings box path: ${box.path}');
        talker.debug('Settings box length: ${box.length}');
      }),
      Hive.openBox('cache_metadata'),
    ]);

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    talker.debug('Firebase initialized successfully');
    // Initialize CachePersistence
    await CachePersistence.initialize();

    // Initialize image cache
    CardImageCacheManager.initCache();

    talker.debug('Initializing theme settings');
    // Initialize theme settings
    try {
      await _container
          .read(themeModeControllerProvider.notifier)
          .initThemeMode();
      talker.debug('Theme mode initialized successfully');
    } catch (e, stack) {
      talker.error('Error initializing theme mode', e, stack);
    }
    try {
      await _container
          .read(themeColorControllerProvider.notifier)
          .initThemeColor();
      talker.debug('Theme color initialized successfully');
    } catch (e, stack) {
      talker.error('Error initializing theme color', e, stack);
    }

    talker.debug('App initialization completed');
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
        UncontrolledProviderScope(
          container: _container,
          child: const FFTCGCompanionApp(),
        ),
      );

      // Remove the native splash screen after the app is initialized
      FlutterNativeSplash.remove();
    } catch (e, stack) {
      talker.error('Error during app initialization', e, stack);
    }
  }, (error, stackTrace) {
    talker.handle(error, stackTrace);
  });
}
