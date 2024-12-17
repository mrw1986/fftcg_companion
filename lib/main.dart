// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this for kDebugMode
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Add this import
import 'package:fftcg_companion/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
    // Add this line for debug builds
  );

  // Configure FirebaseUI Auth
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(
        clientId:
            '161248420888-o7tbfuahgloes35huibpcbceb9m3pgc7.apps.googleusercontent.com'),
  ]);

  runApp(const App());
}
