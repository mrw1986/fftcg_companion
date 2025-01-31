// lib/features/cards/presentation/pages/cards_page.dart
import 'dart:async';

import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/shared/widgets/shimmer_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/cards_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/widgets/filter_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fftcg_companion/features/cards/domain/models/card_filters.dart';

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
  Timer? _scrollDebounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        ref.read(cardsNotifierProvider.notifier).loadMore();
      }
    });
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSortBottomSheet(context),
        icon: const Icon(Icons.sort),
        label: const Text('Sort'),
        tooltip: 'Sort cards',
        elevation: 4,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      )
          .animate()
          .fadeIn(duration: 400.ms)
          .slideY(begin: 1, end: 0)
          .then()
          .shimmer(duration: 1.seconds, delay: 2.seconds),
    );
  }

  Widget _buildAppBarTitle(TextEditingController searchController) {
    if (!_isSearching) {
      return const Text('Card Database');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final isSmallScreen = screenWidth <= mediaQuery.size.shortestSide;

        return Row(
          children: [
            if (isSmallScreen)
              Expanded(child: _buildSearchField(searchController))
            else
              Flexible(
                child: SizedBox(
                  width: screenWidth * 0.4,
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
          icon: const Icon(Icons.clear),
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
        icon: Icon(_isSearching ? Icons.cancel : Icons.search),
        onPressed: () {
          setState(() => _isSearching = !_isSearching);
          if (!_isSearching) ref.read(searchControllerProvider).clear();
        },
      ),
    );

    // Only show additional actions if not searching or on a wide screen
    if (!_isSearching ||
        MediaQuery.of(context).size.width >
            MediaQuery.of(context).size.shortestSide) {
      actions.addAll([
        IconButton(
          icon: Icon(
            viewPrefs.type == ViewType.grid ? Icons.view_list : Icons.grid_view,
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
          onPressed: () => _showFilterDialog(context),
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
  void initState() {
    super.initState();
    _preloadHighResImage();
  }

  bool _isPreloading = false;

  void _preloadHighResImage() async {
    if (_isPreloading) return;

    try {
      _isPreloading = true;
      await CardImageUtils.prefetchImage(
        widget.card.getImageUrl(quality: models.ImageQuality.high),
      );
    } catch (e, stack) {
      talker.error('Failed to preload image', e, stack);
    } finally {
      if (mounted) {
        setState(() => _isPreloading = false);
      }
    }
  }

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
                  imageUrl: widget.card.getImageUrl(
                    quality: models.ImageQuality.medium,
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(imageRadius),
                  placeholder: ShimmerPlaceholder(
                    borderRadius: BorderRadius.circular(imageRadius),
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
  void initState() {
    super.initState();
    _preloadHighResImage();
  }

  void _preloadHighResImage() {
    // Replace CachedCardImage.prefetchImage with CardImageUtils.prefetchImage
    CardImageUtils.prefetchImage(
      widget.card.getImageUrl(quality: models.ImageQuality.high),
    );
  }

  String? getExtendedValue(String key) {
    switch (key) {
      case 'Element':
        return widget.card.elements.isNotEmpty
            ? widget.card.elements.first
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
                        imageUrl: widget.card.getImageUrl(
                          quality: models.ImageQuality.medium,
                        ),
                        fit: BoxFit.contain,
                        width: imageWidth,
                        height: height,
                        borderRadius: BorderRadius.circular(3),
                        placeholder: ShimmerPlaceholder(
                          borderRadius: BorderRadius.circular(3),
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
                      if (widget.viewSize == ViewSize.large) ...[
                        const SizedBox(height: 8),
                        _buildMetadataChips(context, colorScheme),
                      ],
                    ],
                  ),
                ),
                _buildCostIndicator(colorScheme, textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChips(BuildContext context, ColorScheme colorScheme) {
    final elementValue = getExtendedValue('Element');
    final typeValue = getExtendedValue('Type');

    if (elementValue == null && typeValue == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (elementValue != null)
          _buildChip(
            context,
            elementValue,
            colorScheme.primaryContainer,
            colorScheme.onPrimaryContainer,
          ),
        if (elementValue != null && typeValue != null) const SizedBox(width: 8),
        if (typeValue != null)
          _buildChip(
            context,
            typeValue,
            colorScheme.secondaryContainer,
            colorScheme.onSecondaryContainer,
          ),
      ],
    );
  }

  Widget _buildCostIndicator(ColorScheme colorScheme, TextTheme textTheme) {
    final costValue = getExtendedValue('Cost');
    if (costValue == null) {
      return const SizedBox.shrink();
    }

    final size = switch (widget.viewSize) {
      ViewSize.small => 32.0,
      ViewSize.normal => 40.0,
      ViewSize.large => 48.0,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          costValue,
          style: (switch (widget.viewSize) {
            ViewSize.small => textTheme.titleSmall,
            ViewSize.normal => textTheme.titleMedium,
            ViewSize.large => textTheme.titleLarge,
          })
              ?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
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

class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterProvider);
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
              title: 'Name',
              subtitle: 'Sort by card name',
              icon: Icons.sort_by_alpha,
              isSelected: filters.sortField == 'name',
              onTap: () => _updateSort(ref, 'name', filters),
              showOrderIcon: filters.sortField == 'name',
              isDescending: filters.sortDescending,
            ),
            _buildSortOption(
              context: context,
              title: 'Number',
              subtitle: 'Sort by card number',
              icon: Icons.format_list_numbered,
              isSelected: filters.sortField == 'number',
              onTap: () => _updateSort(ref, 'number', filters),
              showOrderIcon: filters.sortField == 'number',
              isDescending: filters.sortDescending,
            ),
            _buildSortOption(
              context: context,
              title: 'Cost',
              subtitle: 'Sort by CP cost',
              icon: Icons.monetization_on,
              isSelected: filters.sortField == 'cost',
              onTap: () => _updateSort(ref, 'cost', filters),
              showOrderIcon: filters.sortField == 'cost',
              isDescending: filters.sortDescending,
            ),
            _buildSortOption(
              context: context,
              title: 'Power',
              subtitle: 'Sort by card power',
              icon: Icons.flash_on,
              isSelected: filters.sortField == 'power',
              onTap: () => _updateSort(ref, 'power', filters),
              showOrderIcon: filters.sortField == 'power',
              isDescending: filters.sortDescending,
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
    required bool isSelected,
    required VoidCallback onTap,
    required bool showOrderIcon,
    required bool isDescending,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

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
        trailing: showOrderIcon
            ? Icon(
                isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.primary,
              )
            : null,
        selected: isSelected,
        onTap: onTap,
      ),
    );
  }

  void _updateSort(WidgetRef ref, String field, CardFilters currentFilters) {
    final isCurrentField = currentFilters.sortField == field;
    ref.read(filterProvider.notifier).setSorting(
          field,
          isCurrentField ? !currentFilters.sortDescending : false,
        );

    // Apply the filters immediately
    ref.read(cardsNotifierProvider.notifier).applyFilters(
          ref.read(filterProvider),
        );

    // Close the bottom sheet
    Navigator.pop(ref.context);
  }
}
