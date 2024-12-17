// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import '../screens/screens.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const HomeScreen(),
  '/auth': (context) => SignInScreen(
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) {
            Navigator.pushReplacementNamed(context, '/');
          }),
        ],
      ),
  '/card_detail': (context) => const CardDetailScreen(),
  '/deck_editor': (context) => const DeckBuilderScreen(),
  '/scanner': (context) => const CardScannerScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/import_export': (context) => const ImportExportScreen(),
  '/statistics': (context) => const StatisticsScreen(),
};
