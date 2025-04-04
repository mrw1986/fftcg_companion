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
    final currentFilters = ref.watch(collectionSpecificFilterProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentFilters.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(collectionSpecificFilterProvider.notifier)
                        .clearFilters();
                    onFilterChanged?.call({});
                  },
                  child: const Text('Clear All'),
                ),
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
    final currentFilters = ref.watch(collectionSpecificFilterProvider);
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
        // No longer need to create a new map here, notifier handles state update.
        if (selected) {
          ref
              .read(collectionSpecificFilterProvider.notifier)
              .setFilter(filterKey, filterValue);
        } else {
          ref
              .read(collectionSpecificFilterProvider.notifier)
              .removeFilter(filterKey);
        }
        // State is updated within the notifier methods, no need to set it here.
        // We still need to call the callback if provided.
        final updatedFilters =
            ref.read(collectionSpecificFilterProvider); // Read the latest state
        onFilterChanged?.call(updatedFilters);
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
    final currentFilters = ref.watch(collectionSpecificFilterProvider);
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
        // No longer need to create a new map here, notifier handles state update.
        // Use setFilter to update the specific key
        ref
            .read(collectionSpecificFilterProvider.notifier)
            .setFilter('gradingCompany', company);
        // State is updated within the notifier method.
        // We still need to call the callback if provided.
        final updatedFilters =
            ref.read(collectionSpecificFilterProvider); // Read the latest state
        onFilterChanged?.call(updatedFilters);
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
