import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import '../models/models.dart' as models;
import '../widgets/widgets.dart';

class CardDatabaseScreen extends StatelessWidget {
  const CardDatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FirestoreListView<Map<String, dynamic>>(
      query: FirebaseFirestore.instance.collection('cards').orderBy('name'),
      itemBuilder: (context, snapshot) {
        final card = models.Card.fromFirestore(snapshot.data());
        return CardTile(
          card: card,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/card_detail',
              arguments: card.id,
            );
          },
        );
      },
    );
  }
}
