import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/cached_card_image.dart';
import '../../../../core/providers/card_cache_provider.dart';
import '../../domain/models/collection_item.dart';
import '../../domain/providers/collection_providers.dart';
import 'package:fftcg_companion/features/models.dart' as models;

/// Provider for a specific collection item
final collectionItemProvider =
    FutureProvider.family<CollectionItem?, String>((ref, cardId) async {
  final notifier = ref.read(userCollectionProvider.notifier);
  return await notifier.getCardFromCollection(cardId);
});

/// Page to display detailed information about a collection item
class CollectionItemDetailPage extends ConsumerWidget {
  final String cardId;
  final CollectionItem? initialItem;

  const CollectionItemDetailPage({
    super.key,
    required this.cardId,
    this.initialItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardCacheAsync = ref.watch(cardCacheNotifierProvider);

    // If we don't have the initial item, fetch it
    final itemAsync = initialItem != null
        ? AsyncValue.data(initialItem!)
        : ref.watch(collectionItemProvider(cardId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Details'),
        actions: [
          itemAsync.when(
            data: (item) => item != null && item.id.isNotEmpty
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                        onPressed: () {
                          context.push('/collection/edit/$cardId', extra: item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: () =>
                            _showDeleteConfirmation(context, ref, item),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.add),
                    tooltip: 'Add to Collection',
                    onPressed: () {
                      context.push('/collection/add?cardId=$cardId');
                    },
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: itemAsync.when(
        data: (item) => _buildContent(
            context,
            ref,
            item ??
                CollectionItem(
                  id: '',
                  userId: '',
                  cardId: cardId,
                  regularQty: 0,
                  foilQty: 0,
                ),
            cardCacheAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CollectionItem item,
    AsyncValue<dynamic> cardCacheAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card image and basic info
          cardCacheAsync.when(
            data: (cardCache) => FutureBuilder<List<models.Card>>(
              future: cardCache.getCachedCards(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(
                    height: 300,
                    child: Center(
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
                  return const SizedBox(
                    height: 300,
                    child: Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card image
                    Center(
                      child: SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedCardImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card name and set
                    Text(
                      card.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (card.displayNumber != null)
                      Text(
                        '${card.displayNumber} · ${card.set.join(' · ')}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                );
              },
            ),
            loading: () => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(
              height: 300,
              child: Center(
                child: Icon(Icons.error, size: 48),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Collection information
          if (item.id.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 64,
                    color: colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Not in your collection',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Collection'),
                    onPressed: () {
                      context.push('/collection/add?cardId=$cardId');
                    },
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantities section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantities',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildQuantityItem(
                              context,
                              'Regular',
                              item.regularQty,
                              Icons.copy,
                            ),
                            _buildQuantityItem(
                              context,
                              'Foil',
                              item.foilQty,
                              Icons.star,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Condition section
                if (item.condition.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Condition',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (item.condition.containsKey('regular'))
                                _buildConditionItem(
                                  context,
                                  'Regular',
                                  item.condition['regular']!,
                                  Icons.copy,
                                ),
                              if (item.condition.containsKey('foil'))
                                _buildConditionItem(
                                  context,
                                  'Foil',
                                  item.condition['foil']!,
                                  Icons.star,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Purchase info section
                if (item.purchaseInfo.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Information',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              if (item.purchaseInfo.containsKey('regular'))
                                _buildPurchaseInfoItem(
                                  context,
                                  'Regular',
                                  item.purchaseInfo['regular']!,
                                  Icons.copy,
                                ),
                              if (item.purchaseInfo.containsKey('foil'))
                                _buildPurchaseInfoItem(
                                  context,
                                  'Foil',
                                  item.purchaseInfo['foil']!,
                                  Icons.star,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Grading info section
                if (item.gradingInfo.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grading Information',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              for (final entry in item.gradingInfo.entries)
                                _buildGradingInfoItem(
                                  context,
                                  entry.key,
                                  entry.value,
                                  Icons.verified,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityItem(
    BuildContext context,
    String label,
    int value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: theme.textTheme.titleLarge,
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildConditionItem(
    BuildContext context,
    String label,
    CardCondition condition,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          condition.code,
          style: theme.textTheme.titleMedium,
        ),
        Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPurchaseInfoItem(
    BuildContext context,
    String label,
    PurchaseInfo info,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                'Price: \$${info.price.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Date: ${_formatDate(info.date.toDate())}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradingInfoItem(
    BuildContext context,
    String label,
    GradingInfo info,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label[0].toUpperCase() +
                    label.substring(1), // Capitalize first letter
                style: theme.textTheme.titleSmall,
              ),
              Text(
                'Company: ${info.company.name}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                'Grade: ${info.grade}',
                style: theme.textTheme.bodyMedium,
              ),
              if (info.certNumber != null)
                Text(
                  'Cert #: ${info.certNumber}',
                  style: theme.textTheme.bodyMedium,
                ),
              if (info.gradedDate != null)
                Text(
                  'Graded: ${_formatDate(info.gradedDate!.toDate())}',
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    CollectionItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: const Text(
          'Are you sure you want to remove this card from your collection?',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(userCollectionProvider.notifier).removeCard(item.id);
              context.go('/collection');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
