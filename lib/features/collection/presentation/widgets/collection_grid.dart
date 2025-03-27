import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/providers/view_preferences_provider.dart';
import 'collection_card.dart';

/// Widget to display a grid of collection items
class CollectionGrid extends ConsumerWidget {
  final List<CollectionItem> collection;
  final Function(CollectionItem) onItemTap;
  final bool isLoading;
  final ScrollController? scrollController;

  const CollectionGrid({
    super.key,
    required this.collection,
    required this.onItemTap,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPrefs = ref.watch(collectionViewPreferencesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width <= size.shortestSide;

    // Calculate grid dimensions based on view size
    final int desiredColumns = switch (viewPrefs.gridSize) {
      ViewSize.small => isSmallScreen ? 4 : 6,
      ViewSize.normal => isSmallScreen ? 3 : 5,
      ViewSize.large => isSmallScreen ? 2 : 4,
    };

    final double spacing = 8.0;
    final double dynamicPadding = isSmallScreen ? 8.0 : 16.0;
    final double childAspectRatio = 63 / 88; // Card aspect ratio

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (collection.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Your collection is empty',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add cards to your collection to see them here',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Use a simple GridView instead of CustomScrollView to avoid nesting scrollable widgets
    return Padding(
      padding: EdgeInsets.all(dynamicPadding),
      child: GridView.builder(
        // Disable scrolling in this grid view since it's inside a scrollable parent
        physics: const NeverScrollableScrollPhysics(),
        // Make the grid take up only as much space as it needs
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: desiredColumns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: collection.length,
        itemBuilder: (context, index) => CollectionCard(
          key: ValueKey(collection[index].id),
          item: collection[index],
          onTap: () => onItemTap(collection[index]),
          viewSize: viewPrefs.gridSize,
          showLabels: viewPrefs.showLabels,
        ),
      ),
    );
  }
}
