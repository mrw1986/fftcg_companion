import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/providers/view_preferences_provider.dart';
import 'collection_list_item.dart';

/// Widget to display a list of collection items
class CollectionList extends ConsumerWidget {
  final List<CollectionItem> collection;
  final Function(CollectionItem) onItemTap;
  final ViewSize viewSize;
  final bool isLoading;
  final ScrollController? scrollController;

  const CollectionList({
    super.key,
    required this.collection,
    required this.onItemTap,
    required this.viewSize,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width <= size.shortestSide;

    final double horizontalPadding = isSmallScreen ? 8.0 : 16.0;
    final double verticalPadding = isSmallScreen ? 4.0 : 8.0;

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
              color: colorScheme.primary.withAlpha(128),
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

    // Use a simple ListView instead of CustomScrollView to avoid nesting scrollable widgets
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: ListView.builder(
        // Disable scrolling in this list view since it's inside a scrollable parent
        physics: const NeverScrollableScrollPhysics(),
        // Make the list take up only as much space as it needs
        shrinkWrap: true,
        itemCount: collection.length,
        itemBuilder: (context, index) => CollectionListItem(
          key: ValueKey(collection[index].id),
          item: collection[index],
          onTap: () => onItemTap(collection[index]),
          viewSize: viewSize,
          isSmallScreen: isSmallScreen,
        ),
      ),
    );
  }
}
