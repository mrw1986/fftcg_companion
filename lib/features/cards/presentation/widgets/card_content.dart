import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_grid_item.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_list_item.dart';

class CardContent extends StatefulWidget {
  final List<models.Card> cards;
  final ({
    ViewType type,
    ViewSize gridSize,
    ViewSize listSize,
    bool showLabels
  }) viewPrefs;

  const CardContent({
    super.key,
    required this.cards,
    required this.viewPrefs,
  });

  @override
  State<CardContent> createState() => CardContentState();
}

class CardContentState extends State<CardContent> {
  final ScrollController scrollController = ScrollController();

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        widget.viewPrefs.type == ViewType.grid
            ? _buildSliverGrid(context)
            : _buildSliverList(context),
      ],
    );
  }

  Widget _buildSliverGrid(BuildContext context) {
    final double spacing = 8.0;
    final size = MediaQuery.sizeOf(context);
    final isSmallScreen = size.width <= size.shortestSide;

    final int desiredColumns = switch (widget.viewPrefs.gridSize) {
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
            key: ValueKey(widget.cards[index].productId),
            card: widget.cards[index],
            viewSize: widget.viewPrefs.gridSize,
            showLabels: widget.viewPrefs.showLabels,
          ),
          childCount: widget.cards.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  Widget _buildSliverList(BuildContext context) {
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
            key: ValueKey(widget.cards[index].productId),
            card: widget.cards[index],
            viewSize: widget.viewPrefs.listSize,
            isSmallScreen: isSmallScreen,
          ),
          childCount: widget.cards.length,
          addAutomaticKeepAlives: true,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }
}
