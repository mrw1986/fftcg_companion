import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/providers/view_preferences_provider.dart';
import 'collection_grid.dart';
import 'collection_list.dart';

/// Widget to display collection content in either grid or list view
class CollectionContent extends ConsumerWidget {
  final List<CollectionItem> collection;
  final Function(CollectionItem) onItemTap;
  final bool isLoading;
  final ScrollController? scrollController;

  const CollectionContent({
    super.key,
    required this.collection,
    required this.onItemTap,
    this.isLoading = false,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPrefs = ref.watch(collectionViewPreferencesProvider);

    // Return the appropriate widget based on view type
    return viewPrefs.type == ViewType.grid
        ? CollectionGrid(
            collection: collection,
            onItemTap: onItemTap,
            isLoading: isLoading,
          )
        : CollectionList(
            collection: collection,
            onItemTap: onItemTap,
            viewSize: viewPrefs.listSize,
            isLoading: isLoading,
          );
  }
}
