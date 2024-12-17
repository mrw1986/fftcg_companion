// lib/widgets/collection_card_tile.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

class CollectionCardTile extends StatelessWidget {
  final CollectionEntry entry;
  final VoidCallback? onTap;

  const CollectionCardTile({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text('Card ID: ${entry.cardId}'),
      subtitle:
          Text('Quantity: ${entry.quantity} (${entry.foilQuantity} foil)'),
      trailing: Text('Last Updated: ${entry.lastUpdated.toString()}'),
    );
  }
}
