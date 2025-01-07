// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fftcg_companion/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // Initialize logger
  final talker = TalkerFlutter.init();

  // Set up error handling
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
  };

  runApp(
    ProviderScope(
      child: const FFTCGCompanionApp(),
    ),
  );
}
