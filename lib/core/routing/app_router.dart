import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../providers/root_route_history_notifier.dart';
import '../utils/logger.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../features/cards/presentation/pages/card_details_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/theme_settings_page.dart';
import '../../features/profile/presentation/pages/login_page.dart';
import '../../features/profile/presentation/pages/register_page.dart';
import '../../features/profile/presentation/pages/reset_password_page.dart';
import '../../features/collection/presentation/pages/collection_page.dart';
import '../../features/collection/presentation/pages/collection_item_detail_page.dart';
import '../../features/collection/presentation/pages/collection_edit_page.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/collection/domain/models/collection_item.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const CardsPage(),
          ),
          GoRoute(
            path: '/collection',
            builder: (context, state) => const CollectionPage(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) {
                  final cardId = state.uri.queryParameters['cardId'] ?? '';
                  final startWithSearch =
                      state.uri.queryParameters['search'] == 'true';
                  return CollectionEditPage(
                    cardId: cardId.isNotEmpty ? cardId : null,
                    startWithSearch: startWithSearch,
                  );
                },
              ),
              GoRoute(
                path: 'edit/:cardId',
                builder: (context, state) {
                  final cardId = state.pathParameters['cardId'] ?? '';
                  final item = state.extra as CollectionItem?;
                  return CollectionEditPage(
                    cardId: cardId,
                    existingItem: item,
                  );
                },
              ),
              GoRoute(
                path: ':cardId',
                builder: (context, state) {
                  final cardId = state.pathParameters['cardId'] ?? '';
                  final item = state.extra as CollectionItem?;
                  return CollectionItemDetailPage(
                    cardId: cardId,
                    initialItem: item,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/decks',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Decks Screen')),
            ),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Scanner Screen')),
            ),
          ),
          GoRoute(
            path: '/cards',
            builder: (context, state) => const CardsPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final card = state.extra as models.Card;
                  return CardDetailsPage(initialCard: card);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
            routes: [
              GoRoute(
                path: 'theme',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const ThemeSettingsPage(),
                ),
              ),
              GoRoute(
                path: 'logs',
                builder: (context, state) => TalkerScreen(
                  talker: talker,
                  theme: const TalkerScreenTheme(
                    backgroundColor: Color(0xFF2D2D2D),
                    textColor: Colors.white,
                    cardColor: Color(0xFF1E1E1E),
                  ),
                ),
              ),
              GoRoute(
                path: 'login',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const LoginPage(),
                ),
              ),
              GoRoute(
                path: 'register',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const RegisterPage(),
                ),
              ),
              GoRoute(
                path: 'reset-password',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: const ResetPasswordPage(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class NavigationDestinationItem {
  final Key key;
  final Widget icon;
  final Widget? selectedIcon;
  final String label;

  const NavigationDestinationItem({
    required this.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
  });

  NavigationDestination toNavigationDestination() {
    return NavigationDestination(
      key: key,
      icon: icon,
      selectedIcon: selectedIcon ?? icon,
      label: label,
    );
  }
}

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final Widget child;

  const ScaffoldWithNavBar({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  static const String _backHandlerChannel =
      "com.mrw1986.fftcg_companion/back_handler";
  static const platform = MethodChannel(_backHandlerChannel);
  DateTime? _lastBackPress;

  static const List<NavigationDestinationItem> _destinations = [
    NavigationDestinationItem(
      key: Key('nav_cards'),
      icon: Icon(Icons.grid_view),
      label: 'Cards',
    ),
    NavigationDestinationItem(
      key: Key('nav_collection'),
      icon: Icon(Icons.collections_bookmark),
      label: 'Collection',
    ),
    NavigationDestinationItem(
      key: Key('nav_decks'),
      icon: Icon(Icons.style),
      label: 'Decks',
    ),
    NavigationDestinationItem(
      key: Key('nav_scanner'),
      icon: Icon(Icons.camera_alt),
      label: 'Scanner',
    ),
    NavigationDestinationItem(
      key: Key('nav_profile'),
      icon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethodCall);
    _enablePredictiveBack();
  }

  Future<void> _enablePredictiveBack() async {
    try {
      await platform.invokeMethod('enablePredictiveBack');
    } catch (e) {
      // Handle or ignore the error
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'handleBackPress':
        return _handleBackPress();
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'Method ${call.method} not implemented',
        );
    }
  }

  Future<bool> _handleBackPress() async {
    final historyNotifier = ref.read(rootRouteHistoryProvider.notifier);

    if (historyNotifier.canGoBack) {
      historyNotifier.removeLastHistory();
      final newIndex = historyNotifier.currentIndex;
      _navigateToIndex(newIndex);
      return true;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
            child: Text(
              'Press back again to exit',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          duration: const Duration(seconds: 2),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          margin: EdgeInsets.only(
            bottom: 24,
            left: MediaQuery.of(context).size.width * 0.25,
            right: MediaQuery.of(context).size.width * 0.25,
          ),
          elevation: 6,
        ),
      );
      return false;
    }

    _lastBackPress = null; // Reset the timer
    return false; // Let the platform handle the exit
  }

  void _navigateToIndex(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/collection');
        break;
      case 2:
        context.go('/decks');
        break;
      case 3:
        context.go('/scanner');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location == '/settings') {
      final router = GoRouter.of(context);
      final routes = router.routerDelegate.currentConfiguration.matches;

      for (var i = routes.length - 1; i >= 0; i--) {
        final route = routes[i].matchedLocation;
        if (route != '/settings') {
          return _getIndexForLocation(route);
        }
      }
    }

    return _getIndexForLocation(location);
  }

  static int _getIndexForLocation(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/collection')) return 1;
    if (location.startsWith('/decks')) return 2;
    if (location.startsWith('/scanner')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final historyNotifier = ref.read(rootRouteHistoryProvider.notifier);

    if (location == '/settings') {
      context.pop();
    }

    historyNotifier.addHistory(index);
    _navigateToIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldStayInApp = await _handleBackPress();
        if (!shouldStayInApp && mounted) {
          await platform.invokeMethod('exitApp');
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          destinations: _destinations
              .map((item) => item.toNavigationDestination())
              .toList(),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
        ),
      ),
    );
  }
}
