import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class ScaffoldWithBottomNavBar extends ConsumerWidget {
  const ScaffoldWithBottomNavBar({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(selectedIndexProvider.notifier).state = index;
          switch (index) {
            case 0:
              context.go('/cards');
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
    );
  }
}
