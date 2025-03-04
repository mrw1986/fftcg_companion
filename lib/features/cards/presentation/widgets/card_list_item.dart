import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/widgets/card_metadata_chips.dart';

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
      ViewSize.small =>
        widget.isSmallScreen ? 100.0 : 110.0, // Increased for better spacing
      ViewSize.normal =>
        widget.isSmallScreen ? 120.0 : 130.0, // Increased for better spacing
      ViewSize.large =>
        widget.isSmallScreen ? 140.0 : 150.0, // Increased for better spacing
    };

    final double imageWidth = height * (223 / 311);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Calculate border radius based on view size
    final double imageRadius = switch (widget.viewSize) {
      ViewSize.small => 4.0,
      ViewSize.normal => 5.5,
      ViewSize.large => 7.0,
    };

    // Scale label text size based on view size
    final TextStyle labelStyle = switch (widget.viewSize) {
      ViewSize.small => textTheme.labelSmall ?? const TextStyle(fontSize: 10),
      ViewSize.normal => textTheme.labelMedium ?? const TextStyle(fontSize: 12),
      ViewSize.large => textTheme.labelLarge ?? const TextStyle(fontSize: 14),
    };

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
                      borderRadius: BorderRadius.circular(imageRadius),
                      child: CachedCardImage(
                        imageUrl: widget.card.getBestImageUrl(),
                        fit: BoxFit.contain,
                        width: imageWidth,
                        height: height,
                        borderRadius: BorderRadius.circular(imageRadius),
                        placeholder: ClipRRect(
                          borderRadius: BorderRadius.circular(imageRadius),
                          child: Image.asset(
                            'assets/images/card-back.jpeg',
                            fit: BoxFit.contain,
                          ),
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
                SizedBox(
                    width: widget.isSmallScreen ? 12 : 20), // Increased spacing
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
                          '${widget.card.displayNumber} · ${widget.card.set.join(' · ')}',
                          style: (switch (widget.viewSize) {
                            ViewSize.small => textTheme.bodySmall,
                            ViewSize.normal => textTheme.bodyMedium,
                            ViewSize.large => textTheme.bodyLarge,
                          })
                              ?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      const SizedBox(height: 12), // Increased spacing
                      Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.copyWith(
                                labelMedium: labelStyle,
                              ),
                        ),
                        child: CardMetadataChips(
                          card: widget.card,
                          colorScheme: colorScheme,
                        ),
                      ),
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
}
