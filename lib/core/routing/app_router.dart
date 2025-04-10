import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';
import 'package:fftcg_companion/app/theme/theme_provider.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../providers/root_route_history_notifier.dart';
import '../utils/logger.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../features/cards/presentation/pages/card_details_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/theme_settings_page.dart';
import '../../features/profile/presentation/pages/register_page.dart';
import '../../features/profile/presentation/pages/auth_page.dart';
import '../../features/profile/presentation/pages/account_settings_page.dart';
import '../../features/profile/presentation/pages/reset_password_page.dart';
import '../../features/collection/presentation/pages/collection_page.dart';
import '../../features/collection/presentation/pages/collection_item_detail_page.dart';
import '../../features/collection/presentation/pages/collection_edit_page.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/collection/domain/models/collection_item.dart';
// Import auth provider for redirect logic
import 'package:fftcg_companion/core/providers/auth_provider.dart';
// Import AppBarFactory for error page
import 'package:fftcg_companion/shared/widgets/app_bar_factory.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>(debugLabel: 'root');
});
// Define navigator keys for each branch of the StatefulShellRoute
final _shellNavigatorKeyCards =
    GlobalKey<NavigatorState>(debugLabel: 'shellCards');
final _shellNavigatorKeyCollection =
    GlobalKey<NavigatorState>(debugLabel: 'shellCollection');
final _shellNavigatorKeyDecks =
    GlobalKey<NavigatorState>(debugLabel: 'shellDecks');
final _shellNavigatorKeyScanner =
    GlobalKey<NavigatorState>(debugLabel: 'shellScanner');
final _shellNavigatorKeyProfile =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

// Provider for the GoRouter instance
final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = ref.watch(rootNavigatorKeyProvider);
  // Listen to auth state changes to trigger redirects
  // No longer needed as redirect directly watches the provider
  // final authStateListenable =
  //     ValueNotifier<AuthState>(const AuthState.loading());
  // ref.listen(authStateProvider, (_, next) {
  //   authStateListenable.value = next;
  // });

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    // REMOVED refreshListenable, using ref.watch in redirect instead
    // Add redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      // WATCH the NEW authStatusProvider to react ONLY to status changes
      final authStatus = ref.watch(authStatusProvider);
      final location = state.uri.toString(); // Use full path with query params

      talker.debug(
          'Router Redirect Check: Location="$location", AuthStatus=$authStatus');

      // Define public routes accessible without full authentication
      final publicRoutes = [
        '/auth',
        '/register',
        '/reset-password',
      ];

      // Check if the current route is one of the public routes
      final isPublicRoute =
          publicRoutes.any((route) => location.startsWith(route));

      // 1. Loading State
      if (authStatus == AuthStatus.loading) {
        talker.debug('Router Redirect: Auth loading, no redirect.');
        return null;
      }

      // 2. Unauthenticated on Protected Route -> /auth
      //    (Anonymous users are now ALLOWED on protected routes)
      if (authStatus == AuthStatus.unauthenticated && !isPublicRoute) {
        talker.debug(
            'Router Redirect: Unauthenticated on protected route -> /auth');
        return '/auth';
      }

      // 3. Authenticated or EmailNotVerified on Public Auth Route -> /profile/account
      if ((authStatus == AuthStatus.authenticated ||
              authStatus == AuthStatus.emailNotVerified) &&
          isPublicRoute &&
          location != '/reset-password') {
        // Allow authenticated users on reset password page
        talker.debug(
            'Router Redirect: Authenticated/EmailNotVerified on public auth route -> /profile/account');
        return '/profile/account';
      }

      // 4. Authenticated, EmailNotVerified, or Anonymous on a PROTECTED route
      //    No redirect needed.
      if ((authStatus == AuthStatus.authenticated ||
              authStatus == AuthStatus.emailNotVerified ||
              authStatus == AuthStatus.anonymous) && // Allow anonymous here
          !isPublicRoute) {
        talker.debug(
            'Router Redirect: Authenticated/EmailNotVerified/Anonymous on protected route ($location), staying put.');
        return null; // Explicitly stay
      }

      // 5. Default: Should theoretically not be reached if logic above is sound, but return null just in case.
      talker.debug('Router Redirect: No redirect needed (default/fallback).');
      return null;
    },
    // Add error handler
    errorBuilder: (context, state) => ErrorPage(error: state.error),
    routes: [
      // StatefulShellRoute for main app navigation with bottom bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Pass the navigationShell to the ScaffoldWithNavBar
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Cards Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCards,
            routes: [
              GoRoute(
                path: '/', // Root path for the first tab
                builder: (context, state) => const CardsPage(),
                routes: [
                  GoRoute(
                    path: 'cards/:id', // Nested route within Cards tab
                    builder: (context, state) {
                      final card = state.extra as models.Card;
                      return CardDetailsPage(initialCard: card);
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Collection Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyCollection,
            routes: [
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
                    path:
                        ':cardId', // Note: Path changed to avoid conflict with /collection/add and /collection/edit
                    builder: (context, state) {
                      final cardId = state.pathParameters['cardId'] ?? '';
                      final item = state.extra as CollectionItem?;
                      // Ensure cardId is not 'add' or 'edit' before proceeding
                      if (cardId == 'add' || cardId == 'edit') {
                        // Optionally handle this case, e.g., show an error or redirect
                        return ErrorPage(
                            error: Exception(
                                'Invalid path parameter for collection item detail: $cardId'));
                      }
                      return CollectionItemDetailPage(
                        cardId: cardId,
                        initialItem: item,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Decks Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyDecks,
            routes: [
              GoRoute(
                path: '/decks',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Decks Screen')),
                ),
              ),
            ],
          ),
          // Branch 4: Scanner Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyScanner,
            routes: [
              GoRoute(
                path: '/scanner',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Scanner Screen')),
                ),
              ),
            ],
          ),
          // Branch 5: Profile Tab
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfilePage(),
                routes: [
                  // Sub-routes within the Profile tab
                  GoRoute(
                    path: 'theme',
                    builder: (context, state) => const ThemeSettingsPage(),
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
                ],
              ),
            ],
          ),
        ],
      ),
      // Top-level routes (outside the shell) for authentication
      GoRoute(
        path: '/auth', // Changed from /profile/auth
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/register', // Changed from /profile/register
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/reset-password', // Changed from /profile/reset-password
        builder: (context, state) => const ResetPasswordPage(),
      ),
      // NEW: Top-level route for Account Settings
      GoRoute(
        path: '/profile/account',
        builder: (context, state) => const AccountSettingsPage(),
      ),
      // Redirect for old /profile/login path
      GoRoute(
        path: '/profile/login',
        redirect: (_, __) => '/auth', // Redirect to the new top-level auth path
      ),
      // Redirect for old /cards/:id path (now nested under '/')
      GoRoute(
        path: '/cards/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          // Assuming state.extra contains the card object needed by CardDetailsPage
          // We need to preserve the extra data during redirect if possible,
          // but GoRouter redirect doesn't directly support passing 'extra'.
          // A common workaround is to use query parameters or a state management solution
          // to pass the required data. For simplicity here, we redirect without 'extra'.
          // The target route might need adjustment to fetch the card data if 'extra' is missing.
          talker.warning(
              'Redirecting from old /cards/$id to /cards/$id. Extra data might be lost.');
          return '/cards/$id'; // Redirect to the new nested path
        },
      ),
    ],
  );
});

// Simple Error Page Widget
class ErrorPage extends StatelessWidget {
  final Exception? error;
  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarFactory.createAppBar(context, 'Page Not Found'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Oops! Page not found.'),
            const SizedBox(height: 10),
            if (error != null)
              Text(
                'Error: ${error.toString()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

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

  NavigationDestination toNavigationDestination(BuildContext context) {
    final themeColor =
        ProviderScope.containerOf(context).read(themeColorControllerProvider);
    final textColor = _getTextColorForBackground(themeColor);

    return NavigationDestination(
      key: key,
      icon: IconTheme(
        data: IconThemeData(
            color: textColor.withValues(alpha: 0.7)), // 0.7 * 255 = 179
        child: icon,
      ),
      selectedIcon: IconTheme(
        data: IconThemeData(color: textColor),
        child: selectedIcon ?? icon,
      ),
      label: label,
    );
  }
}

/// Helper method to determine text color based on background color
Color _getTextColorForBackground(Color backgroundColor) {
  // Calculate the luminance of the background color
  final luminance = backgroundColor.computeLuminance();

  // Use white text on dark backgrounds, black text on light backgrounds
  return luminance > 0.5 ? Colors.black : Colors.white;
}

// Updated ScaffoldWithNavBar to accept StatefulNavigationShell
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell; // Changed from Widget child

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell, // Accept navigationShell
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

  // Updated back press handling for StatefulShellRoute
  Future<bool> _handleBackPress() async {
    // Check if the current branch navigator can pop
    // Create a list of the navigator keys for easier access by index
    final List<GlobalKey<NavigatorState>> navigatorKeys = [
      _shellNavigatorKeyCards,
      _shellNavigatorKeyCollection,
      _shellNavigatorKeyDecks,
      _shellNavigatorKeyScanner,
      _shellNavigatorKeyProfile,
    ];
    final currentNavigator =
        navigatorKeys[widget.navigationShell.currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return true; // Stay in the app, handled pop within the branch
    }

    // If the current branch can't pop, check if we can switch to a previous branch
    final historyNotifier = ref.read(rootRouteHistoryProvider.notifier);
    if (historyNotifier.canGoBack) {
      historyNotifier.removeLastHistory();
      final previousIndex = historyNotifier.currentIndex;
      widget.navigationShell.goBranch(previousIndex,
          initialLocation:
              previousIndex == widget.navigationShell.currentIndex);
      return true; // Stay in the app, switched branch
    }

    // If no navigation handled, prompt to exit
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      if (!mounted) return false;
      SnackBarHelper.showSnackBar(
        context: context,
        message: 'Press back again to exit',
        duration: const Duration(seconds: 2),
        centered: true,
        width: MediaQuery.of(context).size.width * 0.5,
      );
      return true; // Stay in the app, showed exit prompt
    }

    _lastBackPress = null; // Reset the timer
    return false; // Allow exit
  }

  // Use navigationShell.goBranch to navigate between tabs
  void _onItemTapped(int index, BuildContext context) {
    final historyNotifier = ref.read(rootRouteHistoryProvider.notifier);
    // Only add to history if it's a different tab
    if (index != widget.navigationShell.currentIndex) {
      historyNotifier.addHistory(index);
    }
    widget.navigationShell.goBranch(
      index,
      // Use initialLocation: true to reset the branch stack if navigating to the same tab again
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use navigationShell.currentIndex for the selected index
    final selectedIndex = widget.navigationShell.currentIndex;
    final themeColor = ref.watch(themeColorControllerProvider);
    final textColor = _getTextColorForBackground(themeColor);

    return PopScope(
      canPop: false, // Let our custom handler manage pops
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return; // Should not happen with canPop: false
        final shouldStayInApp = await _handleBackPress();
        if (!shouldStayInApp && mounted) {
          // Use SystemNavigator.pop() for a cleaner exit on Android/iOS
          await SystemNavigator.pop();
          // Fallback for web or other platforms if needed
          // await platform.invokeMethod('exitApp');
        }
      },
      child: Scaffold(
        // Use the navigationShell as the body
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          backgroundColor: themeColor,
          indicatorColor: textColor.withValues(alpha: 0.2), // 0.2 * 255 = 51
          elevation: 1,
          height: 65,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(color: textColor);
            }
            return TextStyle(
                color: textColor.withValues(alpha: 0.7)); // 0.7 * 255 = 179
          }),
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: _destinations
              .map((item) => item.toNavigationDestination(context))
              .toList(),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onItemTapped(index, context),
        ),
      ),
    );
  }
}
