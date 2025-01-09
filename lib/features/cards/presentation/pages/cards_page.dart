// lib/features/cards/presentation/pages/cards_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

final searchControllerProvider =
    StateProvider.autoDispose<TextEditingController>(
  (ref) => TextEditingController(),
);

class CardsPage extends ConsumerStatefulWidget {
  const CardsPage({super.key});

  @override
  ConsumerState<CardsPage> createState() => _CardsPageState();
}

class _CardsPageState extends ConsumerState<CardsPage> {
  final _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(cardsNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewPrefs = ref.watch(viewPreferencesProvider);
    final searchController = ref.watch(searchControllerProvider);
    final cards = ref.watch(cardsNotifierProvider);
    final searchResults = _isSearching && searchController.text.isNotEmpty
        ? ref.watch(cardSearchProvider(searchController.text))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search cards...',
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      setState(() => _isSearching = false);
                    },
                  ),
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Cards'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.cancel : Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) searchController.clear();
            },
          ),
          // View Type Toggle
          IconButton(
            icon: Icon(
              viewPrefs.type == ViewType.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () =>
                ref.read(viewPreferencesProvider.notifier).toggleViewType(),
          ),
          // View Size Menu
          PopupMenuButton<ViewSize>(
            icon: const Icon(Icons.format_size),
            initialValue: viewPrefs.type == ViewType.grid
                ? viewPrefs.gridSize
                : viewPrefs.listSize,
            onSelected: (ViewSize size) {
              if (viewPrefs.type == ViewType.grid) {
                ref.read(viewPreferencesProvider.notifier).setGridSize(size);
              } else {
                ref.read(viewPreferencesProvider.notifier).setListSize(size);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ViewSize.small,
                child: Text('Small'),
              ),
              const PopupMenuItem(
                value: ViewSize.normal,
                child: Text('Normal'),
              ),
              const PopupMenuItem(
                value: ViewSize.large,
                child: Text('Large'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final result = await showDialog<models.CardFilters>(
                context: context,
                builder: (context) => const FilterDialog(),
              );
              if (result != null) {
                ref.read(cardsNotifierProvider.notifier).applyFilters(result);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardsNotifierProvider.notifier).refresh(),
        child: cards.when(
          data: (cardList) {
            final displayedCards = searchResults?.value ?? cardList;

            if (displayedCards.isEmpty) {
              return const Center(
                child: Text('No cards found'),
              );
            }

            return viewPrefs.type == ViewType.grid
                ? _buildGridView(displayedCards, viewPrefs.gridSize)
                : _buildListView(displayedCards, viewPrefs.listSize);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => ErrorView(
            message: error.toString(),
            onRetry: () => ref.refresh(cardsNotifierProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildGridView(List<models.Card> cards, ViewSize viewSize) {
    return GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(viewSize.gridPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: viewSize.getColumnCount(
          MediaQuery.of(context).size.width,
        ),
        childAspectRatio: 223 / 311,
        crossAxisSpacing: viewSize.gridSpacing,
        mainAxisSpacing: viewSize.gridSpacing,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return CardGridItem(
          card: cards[index],
          viewSize: viewSize,
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 200),
              delay: Duration(milliseconds: 50 * (index % 10)),
            );
      },
    );
  }

  Widget _buildListView(List<models.Card> cards, ViewSize viewSize) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return CardListItem(
          card: cards[index],
          viewSize: viewSize,
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 200),
              delay: Duration(milliseconds: 50 * (index % 10)),
            );
      },
    );
  }
}

class CardGridItem extends StatelessWidget {
  final models.Card card;
  final ViewSize viewSize;

  const CardGridItem({
    super.key,
    required this.card,
    required this.viewSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/cards/${card.productId}', extra: card);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'card_${card.productId}',
                child: CachedNetworkImage(
                  imageUrl: card.fullResUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    card.primaryCardNumber,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardListItem extends StatelessWidget {
  final models.Card card;
  final ViewSize viewSize;

  const CardListItem({
    super.key,
    required this.card,
    required this.viewSize,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate dimensions based on view size
    final double height = switch (viewSize) {
      ViewSize.small => 60.0,
      ViewSize.normal => 80.0,
      ViewSize.large => 100.0,
    };

    final double imageWidth = height * (223 / 311); // Maintain aspect ratio
    final textTheme = Theme.of(context).textTheme;

    return Material(
      child: InkWell(
        onTap: () => context.push('/cards/${card.productId}', extra: card),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                // Card Image
                Hero(
                  tag: 'card_${card.productId}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: imageWidth,
                      height: height,
                      child: CachedNetworkImage(
                        imageUrl: card.lowResUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Card Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        card.name,
                        maxLines: viewSize == ViewSize.large ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: switch (viewSize) {
                          ViewSize.small => textTheme.bodyMedium,
                          ViewSize.normal => textTheme.titleMedium,
                          ViewSize.large => textTheme.titleLarge,
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.primaryCardNumber,
                        style: textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      if (viewSize == ViewSize.large) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (card.extendedData['Element']?.value != null)
                              _buildElementChip(
                                  context, card.extendedData['Element']!.value),
                            const SizedBox(width: 8),
                            if (card.extendedData['Type']?.value != null)
                              _buildTypeChip(
                                  context, card.extendedData['Type']!.value),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Cost Display (if available)
                if (card.extendedData['Cost']?.value != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        card.extendedData['Cost']!.value,
                        style: textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElementChip(BuildContext context, String element) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        element,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context, String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
