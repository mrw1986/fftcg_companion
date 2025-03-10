import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cached_card_image.dart';
import '../../../../core/providers/card_cache_provider.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/models.dart' as models;

/// Widget to display a collection item in a list
class CollectionListItem extends ConsumerWidget {
  final CollectionItem item;
  final VoidCallback onTap;
  final ViewSize viewSize;
  final bool isSmallScreen;

  const CollectionListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.viewSize,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final cardCacheAsync = ref.watch(cardCacheNotifierProvider);

    // Calculate dimensions based on view size
    final double height = switch (viewSize) {
      ViewSize.small => isSmallScreen ? 100.0 : 110.0,
      ViewSize.normal => isSmallScreen ? 120.0 : 130.0,
      ViewSize.large => isSmallScreen ? 140.0 : 150.0,
    };

    final double imageWidth = height * (223 / 311);
    final double imageRadius = switch (viewSize) {
      ViewSize.small => 4.0,
      ViewSize.normal => 5.5,
      ViewSize.large => 7.0,
    };

    // Scale label text size based on view size
    final TextStyle labelStyle = switch (viewSize) {
      ViewSize.small => textTheme.labelSmall ?? const TextStyle(fontSize: 10),
      ViewSize.normal => textTheme.labelMedium ?? const TextStyle(fontSize: 12),
      ViewSize.large => textTheme.labelLarge ?? const TextStyle(fontSize: 14),
    };

    return Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8.0 : 16.0,
            vertical: isSmallScreen ? 4.0 : 8.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: height,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card image
                cardCacheAsync.when(
                  data: (cardCache) {
                    return FutureBuilder<List<models.Card>>(
                      future: cardCache.getCachedCards(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            width: imageWidth,
                            height: height,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return SizedBox(
                            width: imageWidth,
                            height: height,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
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
                          return SizedBox(
                            width: imageWidth,
                            height: height,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        }

                        return Container(
                          width: imageWidth,
                          height: height,
                          color: theme.scaffoldBackgroundColor,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(imageRadius),
                            child: CachedCardImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              width: imageWidth,
                              height: height,
                              borderRadius: BorderRadius.circular(imageRadius),
                              placeholder: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(imageRadius),
                                child: Image.asset(
                                  'assets/images/card-back.jpeg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => SizedBox(
                    width: imageWidth,
                    height: height,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => SizedBox(
                    width: imageWidth,
                    height: height,
                    child: const Center(
                      child: Icon(Icons.error, size: 48),
                    ),
                  ),
                ),

                SizedBox(width: isSmallScreen ? 12 : 20),

                // Card details
                Expanded(
                  child: cardCacheAsync.when(
                    data: (cardCache) {
                      return FutureBuilder<List<models.Card>>(
                        future: cardCache.getCachedCards(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError || !snapshot.hasData) {
                            return const Center(
                              child: Text('Failed to load card details'),
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

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                card.name,
                                maxLines: viewSize == ViewSize.small ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: (switch (viewSize) {
                                  ViewSize.small => isSmallScreen
                                      ? textTheme.titleSmall
                                      : textTheme.titleMedium,
                                  ViewSize.normal => isSmallScreen
                                      ? textTheme.titleMedium
                                      : textTheme.titleLarge,
                                  ViewSize.large => isSmallScreen
                                      ? textTheme.titleLarge
                                      : textTheme.headlineSmall,
                                })
                                    ?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (card.displayNumber != null)
                                Text(
                                  '${card.displayNumber} · ${card.set.join(' · ')}',
                                  style: (switch (viewSize) {
                                    ViewSize.small => textTheme.bodySmall,
                                    ViewSize.normal => textTheme.bodyMedium,
                                    ViewSize.large => textTheme.bodyLarge,
                                  })
                                      ?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              const SizedBox(height: 12),

                              // Collection details
                              Row(
                                children: [
                                  if (item.regularQty > 0)
                                    _buildQuantityChip(
                                      context,
                                      'Regular',
                                      item.regularQty,
                                      Icons.copy,
                                      colorScheme.surfaceContainerHighest,
                                      colorScheme.onSurfaceVariant,
                                      labelStyle,
                                    ),
                                  if (item.regularQty > 0 && item.foilQty > 0)
                                    const SizedBox(width: 8),
                                  if (item.foilQty > 0)
                                    _buildQuantityChip(
                                      context,
                                      'Foil',
                                      item.foilQty,
                                      Icons.star,
                                      colorScheme.primaryContainer,
                                      colorScheme.onPrimaryContainer,
                                      labelStyle,
                                    ),
                                ],
                              ),

                              // Graded badge
                              if (item.gradingInfo.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    for (final entry
                                        in item.gradingInfo.entries)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: _buildGradedChip(
                                          context,
                                          entry.key,
                                          entry.value,
                                          colorScheme.tertiaryContainer,
                                          colorScheme.onTertiaryContainer,
                                          labelStyle,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(
                      child: Text('Failed to load card details'),
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

  Widget _buildQuantityChip(
    BuildContext context,
    String label,
    int quantity,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    TextStyle labelStyle,
  ) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$label: $quantity',
            style: labelStyle.copyWith(color: textColor),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildGradedChip(
    BuildContext context,
    String type,
    GradingInfo info,
    Color backgroundColor,
    Color textColor,
    TextStyle labelStyle,
  ) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            '${info.company.name} ${info.grade}',
            style: labelStyle.copyWith(color: textColor),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
