import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

class ScaffoldWithBottomNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithBottomNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<ScaffoldWithBottomNavBar> createState() =>
      _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState
    extends ConsumerState<ScaffoldWithBottomNavBar> {
  DateTime? _lastBackPress;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        final router = GoRouter.of(context);
        final location = GoRouterState.of(context).uri.path;

        // If we can pop the current route, do it
        if (router.canPop()) {
          if (mounted) {
            context.pop();
            talker.debug('Popped current route: $location');
          }
          return;
        }

        // Handle root route specially
        if (location == '/cards') {
          final now = DateTime.now();
          if (_lastBackPress == null ||
              now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
            _lastBackPress = now;
            if (!mounted) return;

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Press back again to exit'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
              );
            return;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            await SystemNavigator.pop(animated: true);
          }
          return;
        }

        // If not at root route, navigate to root
        if (mounted) {
          context.go('/cards');
          ref.read(selectedTabIndexProvider.notifier).state = 0;
          talker.debug('Navigated to root route from: $location');
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            final newLocation = switch (index) {
              0 => '/cards',
              1 => '/collection',
              2 => '/decks',
              3 => '/scanner',
              4 => '/profile',
              _ => '/cards',
            };

            ref.read(selectedTabIndexProvider.notifier).state = index;
            context.go(newLocation);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Cards',
            ),
            NavigationDestination(
              icon: Icon(Icons.collections_bookmark_rounded),
              label: 'Collection',
            ),
            NavigationDestination(
              icon: Icon(Icons.dashboard_customize_rounded),
              label: 'Decks',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_rounded),
              label: 'Scanner',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

final selectedTabIndexProvider = StateProvider<int>((ref) => 0);
