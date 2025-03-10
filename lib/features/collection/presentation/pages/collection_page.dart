import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../domain/providers/collection_providers.dart';
import '../../domain/providers/view_preferences_provider.dart';
import '../widgets/collection_content.dart';
import '../widgets/collection_stats_card.dart';
import '../widgets/collection_filter_bar.dart';

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
      ref.read(collectionSearchQueryProvider.notifier).state = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final collectionAsync = ref.watch(userCollectionProvider);
    final searchedCollection = ref.watch(searchedCollectionProvider);
    final statsAsync = ref.watch(collectionStatsProvider);
    final viewPrefs = ref.watch(collectionViewPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search collection...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  ref.read(collectionSearchQueryProvider.notifier).state =
                      value;
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
            icon: const Icon(Icons.format_size),
            tooltip: 'Change Size',
            onPressed: () {
              if (viewPrefs.type == ViewType.grid) {
                ref
                    .read(collectionViewPreferencesProvider.notifier)
                    .cycleGridSize();
              } else {
                ref
                    .read(collectionViewPreferencesProvider.notifier)
                    .cycleListSize();
              }
            },
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

          // Sort button
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onPressed: () => _showSortOptions(context, ref),
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
                padding: const EdgeInsets.all(16.0),
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

            // Filter bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CollectionFilterBar(
                  onFilterChanged: (_) {
                    // The filter provider is already updated by the filter bar
                  },
                ),
              ),
            ),

            // Collection content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
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
        tooltip: 'Add Card',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    final currentSort = ref.read(collectionSortProvider);
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 1.0, end: 0.0),
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 200 * value),
            child: child,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Sort By'),
                  tileColor: colorScheme.surfaceContainerHighest,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Last Modified',
                  'lastModified',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Card Number',
                  'cardId',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Regular Quantity',
                  'regularQty',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Foil Quantity',
                  'foilQty',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Total Quantity',
                  'totalQty',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Price (Market)',
                  'marketPrice',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Price (Low)',
                  'lowPrice',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Price (Mid)',
                  'midPrice',
                  currentSort,
                ),
                _buildSortOption(
                  context,
                  ref,
                  'Price (High)',
                  'highPrice',
                  currentSort,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    String currentSort,
  ) {
    final isSelected = currentSort == value;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: Text(label),
      trailing:
          isSelected ? Icon(Icons.check, color: colorScheme.primary) : null,
      tileColor: isSelected ? colorScheme.surfaceContainerLow : null,
      onTap: () {
        ref.read(collectionSortProvider.notifier).state = value;
        Navigator.pop(context);
      },
    );
  }

  void _showAddCardDialog(BuildContext context) {
    // Navigate to the add card page with search enabled
    context.push('/collection/add?search=true');
  }
}
