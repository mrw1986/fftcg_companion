import 'package:flutter/material.dart';

/// Widget to display collection statistics
class CollectionStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const CollectionStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.collections_bookmark,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Collection Stats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Total Cards',
                  stats['totalCards'] ?? 0,
                  Icons.inventory_2,
                  colorScheme.primary,
                ),
                _buildStatItem(
                  context,
                  'Unique Cards',
                  stats['uniqueCards'] ?? 0,
                  Icons.grid_view,
                  colorScheme.secondary,
                ),
                _buildStatItem(
                  context,
                  'Regular',
                  stats['regularCards'] ?? 0,
                  Icons.copy,
                  colorScheme.tertiary,
                ),
                _buildStatItem(
                  context,
                  'Foil',
                  stats['foilCards'] ?? 0,
                  Icons.star,
                  Colors.amber,
                ),
              ],
            ),
            if (stats.containsKey('gradedCards') &&
                stats['gradedCards'] > 0) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatItem(
                    context,
                    'Graded Cards',
                    stats['gradedCards'] ?? 0,
                    Icons.verified,
                    colorScheme.primary,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
