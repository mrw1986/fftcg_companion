import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/card_content_provider.dart';

class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterProvider);
    final textTheme = Theme.of(context).textTheme;
    final defaultSort = filters.sortField == null || filters.sortField!.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Sort Cards',
                style: textTheme.titleLarge,
              ),
            ),
            _buildSortOption(
              context: context,
              title: 'Name',
              subtitle: 'Sort by card name',
              icon: Icons.sort_by_alpha,
              isSelected: filters.sortField == 'name',
              onTap: () => _updateSort(context, ref, 'name'),
              showOrderIcon: filters.sortField == 'name',
              isDescending: filters.sortDescending,
            ),
            _buildSortOption(
              context: context,
              title: 'Number',
              subtitle: 'Sort by card number',
              icon: Icons.format_list_numbered,
              isSelected: filters.sortField == 'number' || defaultSort,
              onTap: () => _updateSort(context, ref, 'number'),
              showOrderIcon: filters.sortField == 'number' || defaultSort,
              isDescending: filters.sortDescending,
            ),
            _buildSortOption(
              context: context,
              title: 'Cost',
              subtitle: 'Sort by CP cost',
              icon: Icons.monetization_on,
              isSelected: filters.sortField == 'cost',
              onTap: () => _updateSort(context, ref, 'cost'),
              showOrderIcon: filters.sortField == 'cost',
              isDescending: filters.sortDescending,
            ),
            _buildSortOption(
              context: context,
              title: 'Power',
              subtitle: 'Sort by card power',
              icon: Icons.flash_on,
              isSelected: filters.sortField == 'power',
              onTap: () => _updateSort(context, ref, 'power'),
              showOrderIcon: filters.sortField == 'power',
              isDescending: filters.sortDescending,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool showOrderIcon,
    required bool isDescending,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: showOrderIcon
            ? Icon(
                isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.primary,
              )
            : null,
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _updateSort(BuildContext context, WidgetRef ref, String field) {
    final currentFilters = ref.read(filterProvider);

    // For number sort, treat null/empty sortField as 'number' since that's the default
    final isNumberSort = field == 'number';
    final isCurrentField = isNumberSort
        ? (currentFilters.sortField == null ||
            currentFilters.sortField!.isEmpty ||
            currentFilters.sortField == 'number')
        : currentFilters.sortField == field;

    ref.read(filterProvider.notifier).setSorting(
          field,
          isCurrentField ? !currentFilters.sortDescending : false,
        );

    // Apply the filters immediately
    ref.read(cardsNotifierProvider.notifier).applyFilters(
          ref.read(filterProvider),
        );

    // Close the bottom sheet
    Navigator.pop(context);

    // Schedule a microtask to scroll to top after the UI updates
    Future.microtask(() {
      // Use the extension method to scroll to top
      ref.scrollCardsToTop();
    });
  }
}
