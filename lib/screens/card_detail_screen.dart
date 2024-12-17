import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' as models;
import '../widgets/widgets.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cardId = ModalRoute.of(context)!.settings.arguments as String;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cards')
          .doc(cardId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final card = models.Card.fromFirestore(
            snapshot.data!.data() as Map<String, dynamic>);

        return Scaffold(
          appBar: AppBar(
            title: Text(card.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareCard(context, card),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () => _toggleFavorite(context, card),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Hero(
                    tag: 'card_image_${card.id}',
                    child: CardImage(
                      imageUrl: card.imageUrls.large,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCardInfo(card),
                      const Divider(height: 32),
                      _buildCardText(card),
                      const Divider(height: 32),
                      _buildCollectionControls(context, card),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardInfo(models.Card card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          card.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoChip(label: 'Cost', value: card.cost.toString()),
            _buildInfoChip(label: 'Type', value: card.type),
            _buildInfoChip(label: 'Rarity', value: card.rarity),
            ...card.elements.map((element) => Chip(
                  label: Text(element),
                  avatar: Icon(_getElementIcon(element)),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip({required String label, required String value}) {
    return Chip(
      label: Text('$label: $value'),
    );
  }

  IconData _getElementIcon(String element) {
    switch (element.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'ice':
        return Icons.ac_unit;
      case 'earth':
        return Icons.landscape;
      case 'wind':
        return Icons.air;
      case 'lightning':
        return Icons.flash_on;
      case 'water':
        return Icons.water_drop;
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      default:
        return Icons.question_mark;
    }
  }

  Widget _buildCardText(models.Card card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Text',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(card.text),
        if (card.flavorText != null) ...[
          const SizedBox(height: 16),
          Text(
            card.flavorText!,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCollectionControls(BuildContext context, models.Card card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Collection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CollectionControls(
          cardId: card.id,
          onQuantityChanged: (quantity, isFoil) {
            // Implement quantity change logic
          },
        ),
      ],
    );
  }

  void _shareCard(BuildContext context, models.Card card) {
    // Implement share functionality
  }

  void _toggleFavorite(BuildContext context, models.Card card) {
    // Implement favorite functionality
  }
}
