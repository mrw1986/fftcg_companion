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
    final heroTag = 'card_image_${card.id}_${card.setNumber}';

    return ListTile(
      onTap: card.id.isNotEmpty
          ? () {
              Navigator.pushNamed(
                context,
                '/card_detail',
                arguments: {'id': card.id, 'heroTag': heroTag},
              );
            }
          : null,
      leading: Hero(
        tag: heroTag,
        child: SizedBox(
          width: 56.0,
          height: 56.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: CardImage(
              imageUrl: card.imageUrls.small,
              fit: BoxFit.cover,
              isTest: isTest,
            ),
          ),
        ),
      ),
      title: Text(
        card.name,
        style: Theme.of(context).textTheme.titleMedium,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_getElementIcons(card.elements)} ${card.type} • ${card.setId}-${card.setNumber}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Cost: ${card.cost}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (card.power.isNotEmpty)
            Text(
              'Power: ${card.power}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  String _getElementIcons(List<String> elements) {
    return elements.map((element) {
      switch (element.toLowerCase()) {
        case 'fire':
          return '🔥';
        case 'ice':
          return '❄️';
        case 'earth':
          return '🌍';
        case 'wind':
          return '🌪️';
        case 'lightning':
          return '⚡';
        case 'water':
          return '💧';
        case 'light':
          return '✨';
        case 'dark':
          return '🌑';
        default:
          return '❓';
      }
    }).join(' ');
  }
}
