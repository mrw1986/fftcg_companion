// lib/widgets/collection_controls.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

class CollectionControls extends StatelessWidget {
  final String cardId;
  final CollectionEntry? entry;
  final Function(int, bool) onQuantityChanged;

  const CollectionControls({
    super.key,
    required this.cardId,
    this.entry,
    this.onQuantityChanged = _defaultOnQuantityChanged,
  });

  static void _defaultOnQuantityChanged(int quantity, bool isFoil) {
    debugPrint('Quantity changed: $quantity, isFoil: $isFoil');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuantityControl(
                'Normal',
                entry?.quantity ?? 0,
                false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuantityControl(
                'Foil',
                entry?.foilQuantity ?? 0,
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildConditionControls(),
      ],
    );
  }

  Widget _buildQuantityControl(String label, int quantity, bool isFoil) {
    return Material(
      type: MaterialType.card,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 0
                      ? () => onQuantityChanged(quantity - 1, isFoil)
                      : null,
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onQuantityChanged(quantity + 1, isFoil),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionControls() {
    final conditions = entry?.conditions ?? {};

    return Material(
      type: MaterialType.card,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Condition',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildConditionChip('Near Mint', conditions['NM'] ?? 0),
                _buildConditionChip('Lightly Played', conditions['LP'] ?? 0),
                _buildConditionChip('Moderately Played', conditions['MP'] ?? 0),
                _buildConditionChip('Heavily Played', conditions['HP'] ?? 0),
                _buildConditionChip('Damaged', conditions['DMG'] ?? 0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionChip(String condition, int count) {
    return Chip(
      label: Text('$condition: $count'),
      deleteIcon:
          count > 0 ? const Icon(Icons.remove_circle_outline, size: 18) : null,
      onDeleted: count > 0
          ? () {
              // Implement condition count reduction
            }
          : null,
    );
  }
}
