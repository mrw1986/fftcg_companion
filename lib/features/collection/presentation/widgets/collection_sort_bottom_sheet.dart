import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/collection_providers.dart';

class CollectionSortBottomSheet extends ConsumerStatefulWidget {
  const CollectionSortBottomSheet({super.key});

  @override
  ConsumerState<CollectionSortBottomSheet> createState() =>
      _CollectionSortBottomSheetState();
}

class _CollectionSortBottomSheetState
    extends ConsumerState<CollectionSortBottomSheet> {
  late String _currentSortField;
  late bool _isDescending;

  @override
  void initState() {
    super.initState();
    final currentSort = ref.read(collectionSortProvider);
    _currentSortField = currentSort.split(':').first;
    _isDescending = currentSort.contains(':desc');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              title: 'Last Modified',
              subtitle: 'Sort by last modified date',
              icon: Icons.access_time,
              sortField: 'lastModified',
            ),
            _buildSortOption(
              context: context,
              title: 'Card Number',
              subtitle: 'Sort by card number',
              icon: Icons.format_list_numbered,
              sortField: 'cardId',
            ),
            _buildSortOption(
              context: context,
              title: 'Regular Quantity',
              subtitle: 'Sort by regular card quantity',
              icon: Icons.copy,
              sortField: 'regularQty',
            ),
            _buildSortOption(
              context: context,
              title: 'Foil Quantity',
              subtitle: 'Sort by foil card quantity',
              icon: Icons.star,
              sortField: 'foilQty',
            ),
            _buildSortOption(
              context: context,
              title: 'Total Quantity',
              subtitle: 'Sort by total card quantity',
              icon: Icons.format_list_numbered,
              sortField: 'totalQty',
            ),
            _buildSortOption(
              context: context,
              title: 'Price (Market)',
              subtitle: 'Sort by market price',
              icon: Icons.monetization_on,
              sortField: 'marketPrice',
            ),
            _buildSortOption(
              context: context,
              title: 'Price (Low)',
              subtitle: 'Sort by low price',
              icon: Icons.monetization_on,
              sortField: 'lowPrice',
            ),
            _buildSortOption(
              context: context,
              title: 'Price (Mid)',
              subtitle: 'Sort by mid price',
              icon: Icons.monetization_on,
              sortField: 'midPrice',
            ),
            _buildSortOption(
              context: context,
              title: 'Price (High)',
              subtitle: 'Sort by high price',
              icon: Icons.monetization_on,
              sortField: 'highPrice',
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
    required String sortField,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentSortField == sortField;

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
        trailing: isSelected
            ? Icon(
                _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.primary,
              )
            : null,
        selected: isSelected,
        onTap: () => _updateSort(context, sortField),
      ),
    );
  }

  void _updateSort(BuildContext context, String field) {
    // If the same field is selected, toggle the direction
    if (_currentSortField == field) {
      _isDescending = !_isDescending;
    } else {
      // If a new field is selected, set it to ascending by default
      _currentSortField = field;
      _isDescending = false;
    }

    // Update the sort provider with the new field and direction
    final sortValue = _isDescending ? '$field:desc' : field;
    ref.read(collectionSortProvider.notifier).state = sortValue;

    // Close the bottom sheet
    Navigator.pop(context);
  }
}
