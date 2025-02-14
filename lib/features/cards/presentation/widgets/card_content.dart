import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_grid_item.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_list_item.dart';

class CardContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        viewPrefs.type == ViewType.grid
            ? _buildSliverGrid(context)
            : _buildSliverList(context),
      ],
    );
  }

  Widget _buildSliverGrid(BuildContext context) {
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
            key: ValueKey(cards[index].productId),
            card: cards[index],
            viewSize: viewPrefs.listSize,
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
