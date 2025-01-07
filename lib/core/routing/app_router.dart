// lib/core/routing/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/widgets/scaffold_with_bottom_nav_bar.dart';
import 'package:fftcg_companion/features/cards/presentation/pages/cards_page.dart';
import 'package:fftcg_companion/features/collection/presentation/pages/collection_page.dart';
import 'package:fftcg_companion/features/decks/presentation/pages/decks_page.dart';
import 'package:fftcg_companion/features/scanner/presentation/pages/scanner_page.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_page.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/theme_settings_page.dart'; // Add this import

part 'app_router.g.dart';

@riverpod
GoRouter router(ref) {
  final key = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: key,
    initialLocation: '/cards',
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithBottomNavBar(
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/cards',
            builder: (context, state) => const CardsPage(),
          ),
          GoRoute(
            path: '/collection',
            builder: (context, state) => const CollectionPage(),
          ),
          GoRoute(
            path: '/decks',
            builder: (context, state) => const DecksPage(),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const ScannerPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'theme',
                builder: (context, state) => const ThemeSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
