// lib/core/routing/app_router.dart
import 'package:fftcg_companion/features/cards/presentation/pages/card_details_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fftcg_companion/core/widgets/scaffold_with_bottom_nav_bar.dart';
import 'package:fftcg_companion/features/cards/presentation/pages/cards_page.dart';
import 'package:fftcg_companion/features/collection/presentation/pages/collection_page.dart';
import 'package:fftcg_companion/features/decks/presentation/pages/decks_page.dart';
import 'package:fftcg_companion/features/scanner/presentation/pages/scanner_page.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_page.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/theme_settings_page.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

part 'app_router.g.dart';

@riverpod
GoRouter router(ref) {
  final key = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: key,
    initialLocation: '/cards',
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Handle any global redirects here if needed
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithBottomNavBar(
          child: child,
        ),
        navigatorKey: GlobalKey<NavigatorState>(),
        routes: [
          GoRoute(
            path: '/cards',
            builder: (context, state) => const CardsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final card = state.extra as models.Card;
                  return CardDetailsPage(card: card);
                },
              ),
            ],
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
                pageBuilder: (context, state) => MaterialPage<void>(
                  key: state.pageKey,
                  child: const ThemeSettingsPage(),
                ),
              ),
              GoRoute(
                path: 'logs',
                builder: (context, state) => TalkerScreen(
                  talker: talker,
                  theme: TalkerScreenTheme(
                    backgroundColor: const Color(0xFF2D2D2D),
                    textColor: Colors.white,
                    cardColor: const Color(0xFF1E1E1E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/cards'),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
