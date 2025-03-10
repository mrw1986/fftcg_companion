import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/collection_providers.dart';

/// Widget to display filter options for the collection
class CollectionFilterBar extends ConsumerWidget {
  final Function(Map<String, dynamic>)? onFilterChanged;

  const CollectionFilterBar({
    super.key,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilters = ref.watch(collectionFilterProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withAlpha(128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filters',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (currentFilters.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      ref.read(collectionFilterProvider.notifier).state = {};
                      onFilterChanged?.call({});
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    ref,
                    'Regular',
                    'type',
                    'regular',
                    Icons.copy,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'Foil',
                    'type',
                    'foil',
                    Icons.star,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    'Graded',
                    'graded',
                    true,
                    Icons.verified,
                  ),
                  const SizedBox(width: 8),
                  _buildGradingCompanyFilter(context, ref),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    String filterKey,
    dynamic filterValue,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilters = ref.watch(collectionFilterProvider);
    final isSelected = currentFilters[filterKey] == filterValue;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        final newFilters = Map<String, dynamic>.from(currentFilters);
        if (selected) {
          newFilters[filterKey] = filterValue;
        } else {
          newFilters.remove(filterKey);
        }
        ref.read(collectionFilterProvider.notifier).state = newFilters;
        onFilterChanged?.call(newFilters);
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildGradingCompanyFilter(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentFilters = ref.watch(collectionFilterProvider);
    final hasGradingCompanyFilter =
        currentFilters.containsKey('gradingCompany');

    // Only show grading company filter if graded filter is selected
    if (!currentFilters.containsKey('graded') ||
        currentFilters['graded'] != true) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      initialValue: currentFilters['gradingCompany'],
      onSelected: (company) {
        final newFilters = Map<String, dynamic>.from(currentFilters);
        newFilters['gradingCompany'] = company;
        ref.read(collectionFilterProvider.notifier).state = newFilters;
        onFilterChanged?.call(newFilters);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('Any Company'),
        ),
        const PopupMenuItem(
          value: 'PSA',
          child: Text('PSA'),
        ),
        const PopupMenuItem(
          value: 'BGS',
          child: Text('BGS'),
        ),
        const PopupMenuItem(
          value: 'CGC',
          child: Text('CGC'),
        ),
      ],
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business,
              size: 16,
              color: hasGradingCompanyFilter
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              hasGradingCompanyFilter
                  ? currentFilters['gradingCompany'] ?? 'Any Company'
                  : 'Grading Company',
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: hasGradingCompanyFilter
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        backgroundColor: hasGradingCompanyFilter
            ? colorScheme.primaryContainer
            : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: hasGradingCompanyFilter
                ? colorScheme.primaryContainer
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
    );
  }
}
