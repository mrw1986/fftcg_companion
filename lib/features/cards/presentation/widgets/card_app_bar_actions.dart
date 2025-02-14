import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/search_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';

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
    final currentSize = viewPrefs.type == ViewType.grid
        ? viewPrefs.gridSize
        : viewPrefs.listSize;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Toggle
        IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search),
          onPressed: () {
            if (isSearching) {
              // Clear search state when closing search
              ref.read(searchQueryProvider.notifier).state = '';
            }
            onSearchToggle();
          },
        ),
        // Filter Button (only shown when not searching)
        if (!isSearching)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: onFilterTap,
          ),
        // View Type Toggle (only shown when not searching)
        if (!isSearching)
          IconButton(
            icon: Icon(
              viewPrefs.type == ViewType.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () {
              ref.read(viewPreferencesProvider.notifier).toggleViewType();
            },
          ),
        // Size Toggle (only shown when not searching)
        if (!isSearching)
          IconButton(
            icon: Icon(
              Icons.text_fields,
              size: switch (currentSize) {
                ViewSize.small => 18.0,
                ViewSize.normal => 24.0,
                ViewSize.large => 30.0,
              },
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              ref.read(viewPreferencesProvider.notifier).cycleSize();
            },
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
          ),
      ],
    );
  }
}
