import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cached_card_image.dart';
import '../../../../core/providers/card_cache_provider.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;

/// Widget to display a card in the collection
class CollectionCard extends ConsumerWidget {
  final CollectionItem item;
  final VoidCallback onTap;
  final ViewSize viewSize;
  final bool showLabels;

  const CollectionCard({
    super.key,
    required this.item,
    required this.onTap,
    this.viewSize = ViewSize.normal,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardCacheAsync = ref.watch(cardCacheNotifierProvider);

    final titleStyle = switch (viewSize) {
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

    final subtitleStyle = switch (viewSize) {
      ViewSize.small => const TextStyle(fontSize: 10, color: Colors.white),
      ViewSize.normal => const TextStyle(fontSize: 12, color: Colors.white),
      ViewSize.large => const TextStyle(fontSize: 14, color: Colors.white),
    };

    final (double cardRadius, double imageRadius) = switch (viewSize) {
      ViewSize.small => (5.0, 4.0),
      ViewSize.normal => (7.0, 5.5),
      ViewSize.large => (9.0, 7.0),
    };

    return Card(
      color: theme.scaffoldBackgroundColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Card image
            cardCacheAsync.when(
              data: (cardCache) {
                return FutureBuilder<List<models.Card>>(
                  future: cardCache.getCachedCards(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      );
                    }

                    // Find the card in the cache
                    final cards = snapshot.data!;
                    final card = cards.firstWhere(
                      (c) => c.productId.toString() == item.cardId,
                      orElse: () => const models.Card(
                        productId: 0,
                        name: 'Unknown Card',
                        cleanName: 'Unknown Card',
                        fullResUrl: '',
                        highResUrl: '',
                        lowResUrl: '',
                        groupId: 0,
                      ),
                    );

                    // Get the best image URL
                    final imageUrl = card.getBestImageUrl();

                    if (imageUrl == null || imageUrl.isEmpty) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(imageRadius),
                      child: Hero(
                        tag: 'collection_${item.id}',
                        child: CachedCardImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(imageRadius),
                          placeholder: Image.asset(
                            'assets/images/card-back.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(
                child: Icon(Icons.error, size: 48),
              ),
            ),

            // Card labels (if enabled)
            if (showLabels)
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
                  child: cardCacheAsync.when(
                    data: (cardCache) {
                      return FutureBuilder<List<models.Card>>(
                        future: cardCache.getCachedCards(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final cards = snapshot.data!;
                          final card = cards.firstWhere(
                            (c) => c.productId.toString() == item.cardId,
                            orElse: () => const models.Card(
                              productId: 0,
                              name: 'Unknown Card',
                              cleanName: 'Unknown Card',
                              fullResUrl: '',
                              highResUrl: '',
                              lowResUrl: '',
                              groupId: 0,
                            ),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                card.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              if (card.displayNumber != null)
                                Text(
                                  card.displayNumber!,
                                  style: subtitleStyle,
                                ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Quantity indicators
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(179), // 0.7 * 255 ≈ 179
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.regularQty > 0) ...[
                      const Icon(
                        Icons.copy,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.regularQty}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (item.regularQty > 0 && item.foilQty > 0)
                      const SizedBox(width: 4),
                    if (item.foilQty > 0) ...[
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.foilQty}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Graded badge
            if (item.gradingInfo.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Graded',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
