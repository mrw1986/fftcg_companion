// lib/screens/collection_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import '../models/models.dart';
import '../screens/login_prompt.dart'; // Add this import
import '../widgets/widgets.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPrompt();

    return FirestoreListView<Map<String, dynamic>>(
      query: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collection')
          .orderBy('lastUpdated', descending: true),
      itemBuilder: (context, snapshot) {
        final collectionEntry = CollectionEntry.fromFirestore(snapshot.data());
        return CollectionCardTile(
          entry: collectionEntry,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/card_detail',
              arguments: collectionEntry.cardId,
            );
          },
        );
      },
    );
  }
}
