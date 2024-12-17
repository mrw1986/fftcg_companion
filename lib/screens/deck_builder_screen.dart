// lib/screens/deck_builder_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import '../models/models.dart';
import '../screens/login_prompt.dart'; // Add this import
import '../widgets/widgets.dart';

class DeckBuilderScreen extends StatelessWidget {
  const DeckBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPrompt();

    return Scaffold(
      body: FirestoreListView<Map<String, dynamic>>(
        query: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('decks')
            .orderBy('lastModified', descending: true),
        itemBuilder: (context, snapshot) {
          final deck = Deck.fromFirestore(snapshot.data());
          return DeckTile(
            deck: deck,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/deck_detail',
                arguments: deck,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/deck_editor');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
