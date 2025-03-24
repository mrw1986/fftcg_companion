import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Migration script to set up the new security enhancements
/// This includes:
/// 1. Creating the admins collection for role-based access control
/// 2. Adding collectionCount field to user documents
class SecurityMigration {
  final FirebaseFirestore _firestore;
  final Talker talker = Talker();

  SecurityMigration({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Run the migration
  Future<void> run() async {
    try {
      talker.info('Starting security migration...');

      // Create admins collection and add authorized users
      await _setupAdminsCollection();

      // Update user documents with collectionCount field
      await _updateUserDocuments();

      talker.info('Security migration completed successfully');
    } catch (e) {
      talker.error('Error running security migration: $e');
      rethrow;
    }
  }

  /// Set up the admins collection with authorized users
  Future<void> _setupAdminsCollection() async {
    try {
      talker.info('Setting up admins collection...');

      // List of authorized admin emails
      final List<String> adminEmails = [
        'mrw1986@gmail.com',
        'preliatorzero@gmail.com',
        'fftcgcompanion@gmail.com',
      ];

      // Get user documents for these emails
      for (final email in adminEmails) {
        // Find user with this email
        final userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userId = userQuery.docs.first.id;

          // Check if admin document already exists
          final adminDoc =
              await _firestore.collection('admins').doc(userId).get();

          if (!adminDoc.exists) {
            // Create admin document
            await _firestore.collection('admins').doc(userId).set({
              'email': email,
              'createdAt': FieldValue.serverTimestamp(),
              'role': 'admin',
            });
            talker.info('Added admin role for user: $email');
          } else {
            talker.info('Admin role already exists for user: $email');
          }
        } else {
          talker.warning('Could not find user with email: $email');
        }
      }

      talker.info('Admins collection setup completed');
    } catch (e) {
      talker.error('Error setting up admins collection: $e');
      rethrow;
    }
  }

  /// Update user documents with collectionCount field
  Future<void> _updateUserDocuments() async {
    try {
      talker.info('Updating user documents with collectionCount field...');

      // Get all user documents
      final userDocs = await _firestore.collection('users').get();

      for (final userDoc in userDocs.docs) {
        final userId = userDoc.id;

        // Check if collectionCount field already exists
        if (!userDoc.data().containsKey('collectionCount')) {
          // Count user's collection items
          final collectionQuery = await _firestore
              .collection('collections')
              .where('userId', isEqualTo: userId)
              .count()
              .get();

          final collectionCount = collectionQuery.count;

          // Update user document with collectionCount
          await _firestore.collection('users').doc(userId).update({
            'collectionCount': collectionCount,
          });

          talker.info(
              'Updated user $userId with collectionCount: $collectionCount');
        } else {
          talker.info('User $userId already has collectionCount field');
        }
      }

      talker.info('User documents update completed');
    } catch (e) {
      talker.error('Error updating user documents: $e');
      rethrow;
    }
  }
}
