import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:fftcg_companion/app.dart';
import 'firebase_options.dart';

// Global service holders
late final SharedPreferences prefs;
late final PackageInfo packageInfo;
late final FirebaseAnalytics analytics;

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Firebase App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );

    // Configure Firebase Auth Providers
    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
      GoogleProvider(
          clientId:
              '161248420888-o7tbfuahgloes35huibpcbceb9m3pgc7.apps.googleusercontent.com'),
    ]);

    // Initialize Analytics
    analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);

    // Initialize Crashlytics
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    rethrow;
  }
}

Future<void> _initializeLocalServices() async {
  try {
    // Initialize SharedPreferences
    prefs = await SharedPreferences.getInstance();

    // Initialize PackageInfo
    packageInfo = await PackageInfo.fromPlatform();

    // Initialize path provider
    final appDir = await getApplicationDocumentsDirectory();
    debugPrint('App directory: ${appDir.path}');

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint('No internet connection available');
    }

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  } catch (e) {
    debugPrint('Local services initialization error: $e');
    rethrow;
  }
}

Future<void> _initializeErrorHandling() async {
  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (!kDebugMode) {
      // Log to crash reporting service
      FirebaseCrashlytics.instance.recordFlutterError(details);
    }
  };
}

void main() async {
  try {
    // Preserve splash screen while initializing
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Initialize error handling first
    await _initializeErrorHandling();

    // Run other initializations in parallel
    await Future.wait([
      _initializeFirebase(),
      _initializeLocalServices(),
    ]);

    // Run the app
    runApp(const App());
  } catch (error, stackTrace) {
    debugPrint('Initialization error: $error');
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }

    // Show error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize the app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode ? error.toString() : 'Please try again later',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Restart app
                      main();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    // Remove splash screen
    FlutterNativeSplash.remove();
  }
}
