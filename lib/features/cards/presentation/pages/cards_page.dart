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
          IconButton(
            icon: Icon(
              viewPrefs.type == ViewType.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
            onPressed: () =>
                ref.read(viewPreferencesProvider.notifier).toggleViewType(),
          ),
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

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                viewPrefs.type == ViewType.grid
                    ? _buildSliverGrid(displayedCards, viewPrefs)
                    : _buildSliverList(displayedCards, viewPrefs.listSize),
              ],
            );
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

  Widget _buildSliverGrid(
    List<models.Card> cards,
    ({
      ViewType type,
      ViewSize gridSize,
      ViewSize listSize,
      bool showLabels
    }) viewPrefs,
  ) {
    final double spacing = 8.0;

    return SliverPadding(
      padding: EdgeInsets.all(spacing),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: switch (viewPrefs.gridSize) {
            ViewSize.small => 160.0,
            ViewSize.normal => 200.0,
            ViewSize.large => 300.0,
          },
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 63 / 88,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => CardGridItem(
            card: cards[index],
            viewSize: viewPrefs.gridSize,
            showLabels: viewPrefs.showLabels,
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 200),
                delay: Duration(milliseconds: 50 * (index % 10)),
              ),
          childCount: cards.length,
        ),
      ),
    );
  }

  Widget _buildSliverList(List<models.Card> cards, ViewSize viewSize) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => CardListItem(
            card: cards[index],
            viewSize: viewSize,
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 200),
                delay: Duration(milliseconds: 50 * (index % 10)),
              ),
          childCount: cards.length,
        ),
      ),
    );
  }
}

class CardGridItem extends StatelessWidget {
  final models.Card card;
  final ViewSize viewSize;
  final bool showLabels;

  const CardGridItem({
    super.key,
    required this.card,
    required this.viewSize,
    required this.showLabels,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = switch (viewSize) {
      ViewSize.small => const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ViewSize.normal => const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ViewSize.large => const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
    };

    final TextStyle subtitleStyle = switch (viewSize) {
      ViewSize.small => const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ViewSize.normal => const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ViewSize.large => const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push('/cards/${card.productId}', extra: card);
        },
        child: Hero(
          tag: 'card_${card.productId}',
          child: Material(
            color: Theme.of(context)
                .scaffoldBackgroundColor, // This matches the background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: card.fullResUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image),
                  ),
                ),
                if (showLabels)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(0, -0.5),
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                              Colors.black,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                            Text(
                              card.primaryCardNumber,
                              style: subtitleStyle,
                            ),
                          ],
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
    final double height = switch (viewSize) {
      ViewSize.small => 80.0,
      ViewSize.normal => 100.0,
      ViewSize.large => 120.0,
    };

    final double imageWidth = height * (223 / 311);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

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
                  child: Container(
                    width: imageWidth,
                    height: height,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3), // Smaller radius
                      child: CachedNetworkImage(
                        imageUrl: card.lowResUrl,
                        fit: BoxFit
                            .contain, // Ensures the full card is displayed
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
                        maxLines: viewSize == ViewSize.small ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: switch (viewSize) {
                          ViewSize.small => textTheme.titleMedium,
                          ViewSize.normal => textTheme.titleLarge,
                          ViewSize.large => textTheme.headlineSmall,
                        }
                            ?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.primaryCardNumber,
                        style: (switch (viewSize) {
                          ViewSize.small => textTheme.bodySmall,
                          ViewSize.normal => textTheme.bodyMedium,
                          ViewSize.large => textTheme.bodyLarge,
                        })
                            ?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (viewSize == ViewSize.large &&
                          (card.extendedData['Element']?.value != null ||
                              card.extendedData['Type']?.value != null)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (card.extendedData['Element']?.value != null)
                              _buildChip(
                                context,
                                card.extendedData['Element']!.value,
                                colorScheme.primaryContainer,
                                colorScheme.onPrimaryContainer,
                              ),
                            if (card.extendedData['Element']?.value != null &&
                                card.extendedData['Type']?.value != null)
                              const SizedBox(width: 8),
                            if (card.extendedData['Type']?.value != null)
                              _buildChip(
                                context,
                                card.extendedData['Type']!.value,
                                colorScheme.secondaryContainer,
                                colorScheme.onSecondaryContainer,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Cost Display
                if (card.extendedData['Cost']?.value != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: switch (viewSize) {
                      ViewSize.small => 32,
                      ViewSize.normal => 40,
                      ViewSize.large => 48,
                    },
                    height: switch (viewSize) {
                      ViewSize.small => 32,
                      ViewSize.normal => 40,
                      ViewSize.large => 48,
                    },
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        card.extendedData['Cost']!.value,
                        style: switch (viewSize) {
                          ViewSize.small => textTheme.titleSmall,
                          ViewSize.normal => textTheme.titleMedium,
                          ViewSize.large => textTheme.titleLarge,
                        }
                            ?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
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
