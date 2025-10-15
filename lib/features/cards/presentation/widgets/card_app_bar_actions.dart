import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';

class CardAppBarActions extends ConsumerWidget {
  final bool isSearching;
  final VoidCallback onSearchToggle;
  final VoidCallback onFilterTap;
  final VoidCallback onSortTap;
  final Animation<double>? searchCoverAnimation;

  const CardAppBarActions({
    super.key,
    required this.isSearching,
    required this.onSearchToggle,
    required this.onFilterTap,
    required this.onSortTap,
    this.searchCoverAnimation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPrefs = ref.watch(cardViewPreferencesProvider);
    final currentSize = viewPrefs.type == ViewType.grid
        ? viewPrefs.gridSize
        : viewPrefs.listSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated row of other action buttons that fade out progressively
        if (searchCoverAnimation != null)
          AnimatedBuilder(
            animation: searchCoverAnimation!,
            builder: (context, child) {
              // Calculate opacity - icons fade out as search expands
              final opacity = 1.0 - searchCoverAnimation!.value;

              return Opacity(
                opacity: opacity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      _buildActionButtons(context, ref, viewPrefs, currentSize),
                ),
              );
            },
          )
        else
          // Fallback for when animation is not provided
          ...(_buildActionButtons(context, ref, viewPrefs, currentSize)),

        // Search Toggle - always visible, moved to the end
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Icon(
              isSearching ? Icons.close : Icons.search,
              key: ValueKey<bool>(isSearching),
            ),
          ),
          onPressed: () {
            if (isSearching) {
              // Clear search state when closing search
              ref.read(cardSearchQueryProvider.notifier).setQuery('');
            }
            onSearchToggle();
          },
        ),
      ],
    );
  }

  List<Widget> _buildActionButtons(
      BuildContext context,
      WidgetRef ref,
      ({
        ViewType type,
        ViewSize gridSize,
        ViewSize listSize,
        bool showLabels
      }) viewPrefs,
      ViewSize currentSize) {
    return [
      // Filter Button
      IconButton(
        icon: const Icon(Icons.filter_list),
        tooltip: 'Filter',
        onPressed: onFilterTap,
      ),

      // Sort Button
      IconButton(
        icon: const Icon(Icons.sort),
        tooltip: 'Sort',
        onPressed: onSortTap,
      ),

      // Card Labels Toggle
      IconButton(
        icon: Icon(
          viewPrefs.showLabels ? Icons.label : Icons.label_off,
        ),
        tooltip: viewPrefs.showLabels ? 'Hide Card Labels' : 'Show Card Labels',
        onPressed: () {
          ref.read(cardViewPreferencesProvider.notifier).toggleLabels();
        },
      ),

      // View Type Toggle
      IconButton(
        icon: Icon(
          viewPrefs.type == ViewType.grid ? Icons.view_list : Icons.grid_view,
        ),
        tooltip: viewPrefs.type == ViewType.grid
            ? 'Switch to List View'
            : 'Switch to Grid View',
        onPressed: () {
          ref.read(cardViewPreferencesProvider.notifier).toggleViewType();
        },
      ),

      // Size Toggle
      IconButton(
        icon: Icon(
          Icons.text_fields,
          size: switch (currentSize) {
            ViewSize.small => 18.0,
            ViewSize.normal => 24.0,
            ViewSize.large => 30.0,
          },
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        onPressed: () {
          ref.read(cardViewPreferencesProvider.notifier).cycleSize();
        },
        constraints: const BoxConstraints(
          minWidth: 48.0,
          minHeight: 48.0,
        ),
      ),
    ];
  }
}
