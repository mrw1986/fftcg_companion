import 'package:flutter/material.dart';
import '../models/card.dart' as card_model;
import 'card_image.dart';

class CardTile extends StatelessWidget {
  final card_model.Card card;
  final VoidCallback? onTap;
  final bool isTest;

  const CardTile({
    super.key,
    required this.card,
    this.onTap,
    this.isTest = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: SizedBox(
        width: 56.0,
        height: 56.0,
        child: CardImage(
          imageUrl: card.imageUrls.small,
          fit: BoxFit.contain,
          isTest: isTest,
        ),
      ),
      title: Text(card.name),
      subtitle: Text('${card.type} • ${card.setNumber}'),
      trailing: Text('Cost: ${card.cost}'),
    );
  }
}
