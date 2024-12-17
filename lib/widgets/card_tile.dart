import 'package:flutter/material.dart';
import '../models/models.dart' as models;
import '../widgets/card_image.dart';

class CardTile extends StatelessWidget {
  final models.Card card;
  final VoidCallback? onTap;

  const CardTile({
    super.key,
    required this.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CardImage(imageUrl: card.imageUrls.small),
      title: Text(card.name),
      subtitle: Text('${card.type} • ${card.setNumber}'),
      trailing: Text('Cost: ${card.cost}'),
    );
  }
}
