import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/core/widgets/cached_card_image.dart';
import 'package:fftcg_companion/features/models.dart' as models;
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';

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
