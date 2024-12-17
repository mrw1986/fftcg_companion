import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' as models;
import '../widgets/widgets.dart';

class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final String cardId = args['id'] as String;
    final String heroTag = args['heroTag'] as String;

    if (cardId.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Invalid card ID'),
        ),
      );
    }

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

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        try {
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
                      tag: heroTag,
                      child: CardImage(
                        imageUrl: card.imageUrls.large,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Rest of the detail view remains the same
                ],
              ),
            ),
          );
        } catch (e) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('Error parsing card data: $e'),
            ),
          );
        }
      },
    );
  }

  void _shareCard(BuildContext context, models.Card card) {
    // Implement share functionality
  }

  void _toggleFavorite(BuildContext context, models.Card card) {
    // Implement favorite functionality
  }
}
