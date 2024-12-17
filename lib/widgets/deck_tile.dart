// lib/widgets/deck_tile.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

class DeckTile extends StatelessWidget {
  final Deck deck;
  final VoidCallback? onTap;

  const DeckTile({
    super.key,
    required this.deck,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(deck.name),
      subtitle: Text('${deck.totalCards} cards • ${deck.format}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!deck.isValid)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.warning,
                color: Colors.orange,
              ),
            ),
          Icon(
            deck.isPublic ? Icons.public : Icons.lock,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
