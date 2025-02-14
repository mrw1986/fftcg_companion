// lib/features/cards/presentation/pages/cards_page.dart
import 'dart:async';

import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/data/repositories/card_repository.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/sort_bottom_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/filter_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/active_filters_provider.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';

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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Cards will be loaded automatically by the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchInitialImages();
    });
  }

  void _prefetchInitialImages() async {
    final cards = ref.read(cardsNotifierProvider).value;
    if (cards != null && cards.isNotEmpty) {
      await ref
          .read(cardRepositoryProvider.notifier)
          .prefetchVisibleCardImages(cards.take(20).toList());
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
        title: _buildAppBarTitle(searchController),
        actions: _buildAppBarActions(context, viewPrefs),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cardsNotifierProvider.notifier).refresh(),
        child: _isSearching
            ? searchController.text.isEmpty
                ? const SizedBox.shrink()
                : searchResults?.when(
                      data: (searchedCards) {
                        if (searchedCards.isEmpty) {
                          return const Center(
                            child: Text('No cards found'),
                          );
                        }
                        return CustomScrollView(
                          slivers: [
                            viewPrefs.type == ViewType.grid
                                ? _buildSliverGrid(searchedCards, viewPrefs)
                                : _buildSliverList(
                                    searchedCards, viewPrefs.listSize),
                          ],
                        );
                      },
                      loading: () => const LoadingIndicator(),
                      error: (error, stack) => ErrorView(
                        message: error.toString(),
                        onRetry: () => ref
                            .refresh(cardSearchProvider(searchController.text)),
                      ),
                    ) ??
                    const SizedBox.shrink()
            : cards.when(
                data: (cardList) {
                  if (cardList.isEmpty) {
                    return const Center(
                      child: Text('No cards found'),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      viewPrefs.type == ViewType.grid
                          ? _buildSliverGrid(cardList, viewPrefs)
                          : _buildSliverList(cardList, viewPrefs.listSize),
                    ],
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (error, stack) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.refresh(cardsNotifierProvider),
                ),
              ),
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final cardsState = ref.watch(cardsNotifierProvider);
          final colorScheme = Theme.of(context).colorScheme;
          final isLoading = cardsState.isLoading;

          return Stack(
            alignment: Alignment.center,
            children: [
              FloatingActionButton.extended(
                onPressed:
                    isLoading ? null : () => _showSortBottomSheet(context),
                icon: const Icon(Icons.sort),
                label: const Text('Sort'),
                tooltip: isLoading ? 'Loading...' : 'Sort cards',
                elevation: isLoading ? 0 : 4,
                backgroundColor: isLoading
                    ? colorScheme.surfaceContainerHighest
                    : colorScheme.primaryContainer,
                foregroundColor: isLoading
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onPrimaryContainer,
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
          child: const SortBottomSheet(),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle(TextEditingController searchController) {
    if (!_isSearching) {
      return const Text('Card Database');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final isSmallScreen = size.width <= size.shortestSide;

        return Row(
          children: [
            if (isSmallScreen)
              Expanded(child: _buildSearchField(searchController))
            else
              Flexible(
                child: SizedBox(
                  width: size.width * 0.4,
                  child: _buildSearchField(searchController),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(TextEditingController controller) {
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search cards...',
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.backspace_outlined,
          ),
          onPressed: () => controller.clear(),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    ({
      ViewType type,
      ViewSize gridSize,
      ViewSize listSize,
      bool showLabels
    }) viewPrefs,
  ) {
    final actions = <Widget>[];

    // Search action
    actions.add(
      IconButton(
        icon: Icon(_isSearching ? Icons.close_outlined : Icons.search),
        onPressed: () {
          setState(() => _isSearching = !_isSearching);
          if (!_isSearching) ref.read(searchControllerProvider).clear();
        },
      ),
    );

    // Only show additional actions if not searching or on a wide screen
    if (!_isSearching ||
        MediaQuery.sizeOf(context).width >
            MediaQuery.sizeOf(context).shortestSide) {
      actions.addAll([
        Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(filterProvider);
            final filterCount = ref.watch(activeFilterCountProvider(filters));
            final colorScheme = Theme.of(context).colorScheme;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: () => _showFilterDialog(context),
                ),
                if (filterCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        filterCount.toString(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
          icon: Icon(
            viewPrefs.type == ViewType.grid ? Icons.view_list : Icons.grid_view,
          ),
          onPressed: () =>
              ref.read(viewPreferencesProvider.notifier).toggleViewType(),
        ),
        Consumer(
          builder: (context, ref, _) {
            final filters = ref.watch(filterProvider);
            final filterCount = ref.watch(activeFilterCountProvider(filters));
            if (filterCount > 0) {
              return IconButton(
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear all filters',
                onPressed: () {
                  ref.read(filterProvider.notifier).reset();
                  ref.read(cardsNotifierProvider.notifier).applyFilters(
                        const CardFilters(),
                      );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ]);
    }

    return actions;
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    final result = await showDialog<CardFilters>(
      context: context,
      builder: (context) => const FilterDialog(),
    );
    if (result != null) {
      talker.debug('Applying filters from dialog: ${result.toString()}');
      ref.read(cardsNotifierProvider.notifier).applyFilters(result);
    }
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
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width <= size.shortestSide;

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
          ),
          childCount: cards.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  Widget _buildSliverList(List<models.Card> cards, ViewSize viewSize) {
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width <= size.shortestSide;

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

    final titleStyle = switch (widget.viewSize) {
      ViewSize.small => const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ViewSize.normal => const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ViewSize.large => const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
    };

    final subtitleStyle = switch (widget.viewSize) {
      ViewSize.small => const TextStyle(fontSize: 10, color: Colors.white),
      ViewSize.normal => const TextStyle(fontSize: 12, color: Colors.white),
      ViewSize.large => const TextStyle(fontSize: 14, color: Colors.white),
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
                  imageUrl: widget.card.getBestImageUrl(),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(imageRadius),
                  placeholder: Image.asset(
                    'assets/images/card-back.jpeg',
                    fit: BoxFit.cover,
                  ),
                  onImageError: () {
                    talker.error(
                      'Failed to load grid image for card: ${widget.card.productId}',
                    );
                  },
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
                        if (widget.card.displayNumber != null)
                          Text(
                            widget.card.displayNumber!,
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

  String? getExtendedValue(String key) {
    switch (key) {
      case 'Element':
        return widget.card.elements.isNotEmpty
            ? widget.card.elements.join(', ')
            : null;
      case 'Type':
        return widget.card.cardType;
      case 'Cost':
        return widget.card.cost?.toString();
      case 'Job':
        return widget.card.job;
      case 'Category':
        return widget.card.category;
      case 'Description':
        return widget.card.description;
      case 'Rarity':
        return widget.card.rarity;
      default:
        return null;
    }
  }

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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        imageUrl: widget.card.getBestImageUrl(),
                        fit: BoxFit.contain,
                        width: imageWidth,
                        height: height,
                        borderRadius: BorderRadius.circular(3),
                        placeholder: Image.asset(
                          'assets/images/card-back.jpeg',
                          fit: BoxFit.contain,
                        ),
                        onImageError: () {
                          talker.error(
                            'Failed to load list image for card: ${widget.card.productId}',
                          );
                        },
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
                      if (widget.card.displayNumber != null)
                        Text(
                          widget.card.displayNumber!,
                          style: (switch (widget.viewSize) {
                            ViewSize.small => textTheme.bodySmall,
                            ViewSize.normal => textTheme.bodyMedium,
                            ViewSize.large => textTheme.bodyLarge,
                          })
                              ?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      if (widget.viewSize == ViewSize.large) ...[
                        const SizedBox(height: 8),
                        _buildMetadataChips(context, colorScheme),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChips(BuildContext context, ColorScheme colorScheme) {
    final elements = widget.card.elements;
    final typeValue = getExtendedValue('Type');
    final jobValue = getExtendedValue('Job');
    final categoryValue = getExtendedValue('Category');
    final costValue = getExtendedValue('Cost');

    if (elements.isEmpty &&
        typeValue == null &&
        jobValue == null &&
        categoryValue == null &&
        costValue == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 2,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...elements.map((element) => _buildChip(
              context,
              element,
              colorScheme.primaryContainer,
              colorScheme.onPrimaryContainer,
            )),
        if (costValue != null)
          _buildChip(
            context,
            costValue,
            colorScheme.primary,
            colorScheme.onPrimary,
          ),
        if (typeValue != null)
          _buildChip(
            context,
            typeValue,
            colorScheme.secondaryContainer,
            colorScheme.onSecondaryContainer,
          ),
        if (jobValue != null)
          _buildChip(
            context,
            jobValue,
            colorScheme.tertiaryContainer,
            colorScheme.onTertiaryContainer,
          ),
        if (categoryValue != null)
          _buildChip(
            context,
            categoryValue,
            colorScheme.surface,
            colorScheme.onSurface,
          ),
      ],
    );
  }

  String? _getElementImagePath(String element) {
    // Only return image paths for actual elements
    final validElements = {
      'Fire',
      'Ice',
      'Wind',
      'Earth',
      'Lightning',
      'Water',
      'Light',
      'Dark'
    };

    if (!validElements.contains(element)) {
      return null;
    }

    final elementName = element.toLowerCase();
    return 'assets/images/elements/$elementName.png';
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color textColor,
  ) {
    // Check if this is an element chip
    final elementImagePath = _getElementImagePath(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: elementImagePath != null ? Colors.transparent : backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: elementImagePath != null
          ? Image.asset(
              elementImagePath,
              width: 24,
              height: 24,
              alignment: Alignment.center,
            )
          : Text(
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
