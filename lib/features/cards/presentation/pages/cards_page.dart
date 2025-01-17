// lib/features/cards/presentation/pages/cards_page.dart
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart';
import 'package:go_router/go_router.dart';
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
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final mediaQuery = MediaQuery.of(context);
                  final screenWidth = mediaQuery.size.width;
                  final isSmallScreen =
                      screenWidth <= mediaQuery.size.shortestSide;

                  return Row(
                    children: [
                      if (isSmallScreen)
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search cards...',
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => searchController.clear(),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        )
                      else
                        Flexible(
                          child: SizedBox(
                            width: screenWidth * 0.4,
                            child: TextField(
                              controller: searchController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: 'Search cards...',
                                border: InputBorder.none,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => searchController.clear(),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              )
            : const Text('Card Database'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.cancel),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() => _isSearching = !_isSearching);
                if (!_isSearching) searchController.clear();
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() => _isSearching = !_isSearching);
              },
            ),
          if (!_isSearching ||
              MediaQuery.of(context).size.width >
                  MediaQuery.of(context).size.shortestSide) ...[
            PopupMenuButton<(String, bool)>(
              icon: const Icon(Icons.sort),
              tooltip: 'Sort by',
              onSelected: (value) {
                ref
                    .read(cardsNotifierProvider.notifier)
                    .sort(value.$1, descending: value.$2);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: ('number', false),
                  child: Row(
                    children: [
                      Text('Number'),
                      Spacer(),
                      Icon(Icons.arrow_upward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('number', true),
                  child: Row(
                    children: [
                      Text('Number'),
                      Spacer(),
                      Icon(Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('name', false),
                  child: Row(
                    children: [
                      Text('Name'),
                      Spacer(),
                      Icon(Icons.arrow_upward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('name', true),
                  child: Row(
                    children: [
                      Text('Name'),
                      Spacer(),
                      Icon(Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('cost', false),
                  child: Row(
                    children: [
                      Text('Cost'),
                      Spacer(),
                      Icon(Icons.arrow_upward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('cost', true),
                  child: Row(
                    children: [
                      Text('Cost'),
                      Spacer(),
                      Icon(Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('power', false),
                  child: Row(
                    children: [
                      Text('Power'),
                      Spacer(),
                      Icon(Icons.arrow_upward, size: 16),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ('power', true),
                  child: Row(
                    children: [
                      Text('Power'),
                      Spacer(),
                      Icon(Icons.arrow_downward, size: 16),
                    ],
                  ),
                ),
              ],
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth <= mediaQuery.size.shortestSide;

    final int desiredColumns = switch (viewPrefs.gridSize) {
      ViewSize.small => isSmallScreen ? 4 : 6,
      ViewSize.normal => isSmallScreen ? 3 : 5,
      ViewSize.large => isSmallScreen ? 2 : 4,
    };

    final double dynamicPadding = isSmallScreen ? 8.0 : 16.0;

    return SliverPadding(
      padding: EdgeInsets.all(dynamicPadding),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: desiredColumns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 63 / 88,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => CardGridItem(
            key: ValueKey(cards[index].productId),
            card: cards[index],
            viewSize: viewPrefs.gridSize,
            showLabels: viewPrefs.showLabels,
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 200),
                delay: Duration(milliseconds: 50 * (index % 10)),
              ),
          childCount: cards.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  Widget _buildSliverList(List<models.Card> cards, ViewSize viewSize) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth <= mediaQuery.size.shortestSide;

    final double horizontalPadding = isSmallScreen ? 8.0 : 16.0;
    final double verticalPadding = isSmallScreen ? 4.0 : 8.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => CardListItem(
            key: ValueKey(cards[index].productId),
            card: cards[index],
            viewSize: viewSize,
            isSmallScreen: isSmallScreen,
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 200),
                delay: Duration(milliseconds: 50 * (index % 10)),
              ),
          childCount: cards.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}

class CardGridItem extends StatefulWidget {
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
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final TextStyle titleStyle = switch (widget.viewSize) {
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

    final TextStyle subtitleStyle = switch (widget.viewSize) {
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

    final (double cardRadius, double imageRadius) = switch (widget.viewSize) {
      ViewSize.small => (5.0, 4.0),
      ViewSize.normal => (7.0, 5.5),
      ViewSize.large => (9.0, 7.0),
    };

    return Card(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: InkWell(
        onTap: () {
          context.push('/cards/${widget.card.productId}', extra: widget.card);
        },
        child: Hero(
          tag: 'card_${widget.card.productId}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(imageRadius),
                child: CachedCardImage(
                  imageUrl: widget.card.fullResUrl,
                  fit: BoxFit.cover,
                ),
              ),
              if (widget.showLabels)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
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
                          widget.card.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        Text(
                          widget.card.primaryCardNumber,
                          style: subtitleStyle,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardListItem extends StatefulWidget {
  final models.Card card;
  final ViewSize viewSize;
  final bool isSmallScreen;

  const CardListItem({
    super.key,
    required this.card,
    required this.viewSize,
    required this.isSmallScreen,
  });

  @override
  State<CardListItem> createState() => _CardListItemState();
}

class _CardListItemState extends State<CardListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double height = switch (widget.viewSize) {
      ViewSize.small => widget.isSmallScreen ? 70.0 : 80.0,
      ViewSize.normal => widget.isSmallScreen ? 90.0 : 100.0,
      ViewSize.large => widget.isSmallScreen ? 110.0 : 120.0,
    };

    final double imageWidth = height * (223 / 311);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Material(
      child: InkWell(
        onTap: () =>
            context.push('/cards/${widget.card.productId}', extra: widget.card),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmallScreen ? 8.0 : 16.0,
            vertical: widget.isSmallScreen ? 4.0 : 8.0,
          ),
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                Hero(
                  tag: 'card_${widget.card.productId}',
                  child: Container(
                    width: imageWidth,
                    height: height,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: CachedCardImage(
                        imageUrl: widget.card.lowResUrl,
                        fit: BoxFit.contain,
                        width: imageWidth,
                        height: height,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: widget.isSmallScreen ? 8 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.card.name,
                        maxLines: widget.viewSize == ViewSize.small ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: (switch (widget.viewSize) {
                          ViewSize.small => widget.isSmallScreen
                              ? textTheme.titleSmall
                              : textTheme.titleMedium,
                          ViewSize.normal => widget.isSmallScreen
                              ? textTheme.titleMedium
                              : textTheme.titleLarge,
                          ViewSize.large => widget.isSmallScreen
                              ? textTheme.titleLarge
                              : textTheme.headlineSmall,
                        })
                            ?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.card.primaryCardNumber,
                        style: (switch (widget.viewSize) {
                          ViewSize.small => textTheme.bodySmall,
                          ViewSize.normal => textTheme.bodyMedium,
                          ViewSize.large => textTheme.bodyLarge,
                        })
                            ?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (widget.viewSize == ViewSize.large &&
                          (widget.card.extendedData['Element']?.value != null ||
                              widget.card.extendedData['Type']?.value !=
                                  null)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (widget.card.extendedData['Element']?.value !=
                                null)
                              _buildChip(
                                context,
                                widget.card.extendedData['Element']!.value,
                                colorScheme.primaryContainer,
                                colorScheme.onPrimaryContainer,
                              ),
                            if (widget.card.extendedData['Element']?.value !=
                                    null &&
                                widget.card.extendedData['Type']?.value != null)
                              const SizedBox(width: 8),
                            if (widget.card.extendedData['Type']?.value != null)
                              _buildChip(
                                context,
                                widget.card.extendedData['Type']!.value,
                                colorScheme.secondaryContainer,
                                colorScheme.onSecondaryContainer,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.card.extendedData['Cost']?.value != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: switch (widget.viewSize) {
                      ViewSize.small => 32,
                      ViewSize.normal => 40,
                      ViewSize.large => 48,
                    },
                    height: switch (widget.viewSize) {
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
                        widget.card.extendedData['Cost']!.value,
                        style: switch (widget.viewSize) {
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
