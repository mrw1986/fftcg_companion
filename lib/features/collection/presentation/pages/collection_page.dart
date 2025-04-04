import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/loading_indicator.dart';
// Hide the incorrect search provider from this import
import '../../domain/providers/collection_providers.dart'
    hide collectionSearchQueryProvider; // Keep for collection data
// Import the new collection-specific view preferences provider
import '../providers/collection_view_preferences_provider.dart';
// Import the new collection-specific search provider
import '../providers/collection_search_provider.dart';
// Import the shared view preference enums (assuming they are still in cards feature or moved)
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart'
    show ViewType, ViewSize;
import '../widgets/collection_content.dart';
import '../widgets/collection_stats_card.dart';
import '../widgets/collection_sort_bottom_sheet.dart';
import '../widgets/collection_filter_dialog.dart';

/// Main page for displaying the user's collection
class CollectionPage extends ConsumerStatefulWidget {
  const CollectionPage({super.key});

  @override
  ConsumerState<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends ConsumerState<CollectionPage> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });

    if (!_isSearching) {
      _searchController.clear();
      // Use the correct search provider from collection_search_provider.dart
      ref.read(collectionSearchQueryProvider.notifier).setQuery('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(userCollectionProvider);
    final searchedCollection = ref.watch(searchedCollectionProvider);
    final statsAsync = ref.watch(collectionStatsProvider);
    final viewPrefs = ref.watch(collectionViewPreferencesProvider);
    final currentSize = viewPrefs.type == ViewType.grid
        ? viewPrefs.gridSize
        : viewPrefs.listSize;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search collection...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                      color: colorScheme.onPrimary
                          .withValues(alpha: 0.7)), // 70% opacity
                ),
                style: TextStyle(color: colorScheme.onPrimary),
                onChanged: (value) {
                  // Use the correct search provider from collection_search_provider.dart
                  ref
                      .read(collectionSearchQueryProvider.notifier)
                      .setQuery(value);
                },
                autofocus: true,
              )
            : const Text('My Collection'),
        actions: [
          // Search button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Cancel' : 'Search',
            onPressed: _toggleSearch,
          ),

          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: () => _showFilterDialog(context, ref),
          ),

          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: () => _showSortOptions(context, ref),
          ),

          // Card labels toggle
          IconButton(
            icon: Icon(
              viewPrefs.showLabels ? Icons.label : Icons.label_off,
            ),
            tooltip:
                viewPrefs.showLabels ? 'Hide Card Labels' : 'Show Card Labels',
            onPressed: () {
              ref
                  .read(collectionViewPreferencesProvider.notifier)
                  .toggleLabels();
            },
          ),

          // View type toggle
          IconButton(
            icon: Icon(
              viewPrefs.type == ViewType.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            tooltip: viewPrefs.type == ViewType.grid
                ? 'Switch to List View'
                : 'Switch to Grid View',
            onPressed: () {
              ref
                  .read(collectionViewPreferencesProvider.notifier)
                  .toggleViewType();
            },
          ),

          // View size toggle
          IconButton(
            icon: Icon(
              Icons.text_fields,
              size: switch (currentSize) {
                ViewSize.small => 18.0,
                ViewSize.normal => 24.0,
                ViewSize.large => 30.0,
              },
              color: colorScheme.onPrimary,
            ),
            tooltip: 'Change Size',
            onPressed: () {
              // Use the correct provider name
              ref.read(collectionViewPreferencesProvider.notifier).cycleSize();
            },
            constraints: const BoxConstraints(
              minWidth: 48.0,
              minHeight: 48.0,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(userCollectionProvider.notifier).refreshCollection(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Stats section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    16.0, 8.0, 16.0, 8.0), // Reduced top and bottom padding
                child: statsAsync.when(
                  data: (stats) => CollectionStatsCard(stats: stats),
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(child: LoadingIndicator()),
                  ),
                  error: (_, __) => const Text('Failed to load stats'),
                ),
              ),
            ),

            // Collection content
            SliverToBoxAdapter(
              child: Transform.translate(
                offset:
                    const Offset(0, -8), // Negative offset to move content up
                child: collectionAsync.when(
                  data: (_) => CollectionContent(
                    collection: searchedCollection,
                    onItemTap: (item) {
                      // Navigate to card details
                      context.push('/collection/${item.cardId}', extra: item);
                    },
                    scrollController: _scrollController,
                  ),
                  loading: () => const SizedBox(
                    height: 300,
                    child: Center(child: LoadingIndicator()),
                  ),
                  error: (_, __) => const SizedBox(
                    height: 300,
                    child: Center(child: Text('Failed to load collection')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCardDialog(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog<(dynamic, Map<String, dynamic>)>(
      context: context,
      builder: (context) => const CollectionFilterDialog(),
    ).then((result) {
      if (result != null) {
        // The filter providers are already updated by the dialog
        // We just need to ensure the UI reflects the changes
      }
    });
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2), // 0.2 * 255 = 51
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const CollectionSortBottomSheet(),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context) {
    // Navigate to the add card page with search enabled
    context.push('/collection/add?search=true');
  }
}
