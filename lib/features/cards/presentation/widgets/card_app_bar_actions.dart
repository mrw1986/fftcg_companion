import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/active_filters_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';

class CardAppBarActions extends ConsumerWidget {
  final bool isSearching;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;

  const CardAppBarActions({
    super.key,
    required this.isSearching,
    required this.onSearchToggle,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPrefs = ref.watch(viewPreferencesProvider);
    final actions = <Widget>[];

    // Search action
    actions.add(
      IconButton(
        icon: Icon(isSearching ? Icons.close_outlined : Icons.search),
        onPressed: onSearchToggle,
      ),
    );

    // Only show additional actions if not searching or on a wide screen
    if (!isSearching ||
        MediaQuery.sizeOf(context).width >
            MediaQuery.sizeOf(context).shortestSide) {
      actions.addAll([
        Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(filterProvider);
            final filterCount = ref.watch(activeFilterCountProvider(filters));
            final colorScheme = Theme.of(context).colorScheme;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: onFilterTap,
                ),
                if (filterCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        filterCount.toString(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        PopupMenuButton<ViewSize>(
          icon: const Icon(Icons.format_size),
          initialValue: viewPrefs.type == ViewType.grid
              ? viewPrefs.gridSize
              : viewPrefs.listSize,
          onSelected: (ViewSize size) {
            if (viewPrefs.type == ViewType.grid) {
              ref.read(viewPreferencesProvider.notifier).setGridSize(size);
            } else {
              ref.read(viewPreferencesProvider.notifier).setListSize(size);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: ViewSize.small,
              child: Text('Small'),
            ),
            const PopupMenuItem(
              value: ViewSize.normal,
              child: Text('Normal'),
            ),
            const PopupMenuItem(
              value: ViewSize.large,
              child: Text('Large'),
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            viewPrefs.type == ViewType.grid ? Icons.view_list : Icons.grid_view,
          ),
          onPressed: () =>
              ref.read(viewPreferencesProvider.notifier).toggleViewType(),
        ),
        Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(filterProvider);
            final filterCount = ref.watch(activeFilterCountProvider(filters));
            if (filterCount > 0) {
              return IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear all filters',
                onPressed: () {
                  ref.read(filterProvider.notifier).reset();
                  ref.read(cardsNotifierProvider.notifier).applyFilters(
                        const CardFilters(),
                      );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ]);
    }

    return Row(children: actions);
  }
}
