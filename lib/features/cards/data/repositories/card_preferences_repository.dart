import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_card_preferences.dart';
import '../../../../core/utils/logger.dart';

/// Repository for managing user card preferences in Firestore
class CardPreferencesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CardPreferencesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Collection reference for user preferences
  CollectionReference<Map<String, dynamic>> get _preferencesCollection =>
      _firestore.collection('userCardPreferences');

  /// Stream of user preferences for the current user
  Stream<UserCardPreferences> getUserPreferencesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      // Return empty preferences if no user is signed in
      return Stream.value(UserCardPreferences.empty('anonymous'));
    }

    return _preferencesCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        // Create default preferences if document doesn't exist
        final defaultPrefs = UserCardPreferences.empty(userId);
        _saveUserPreferences(defaultPrefs).catchError((error) {
          talker.error('Failed to create default preferences: $error');
        });
        return defaultPrefs;
      }
      return UserCardPreferences.fromFirestore(snapshot);
    });
  }

  /// Get user preferences once (not as a stream)
  Future<UserCardPreferences> getUserPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return UserCardPreferences.empty('anonymous');
    }

    try {
      final doc = await _preferencesCollection.doc(userId).get();
      if (!doc.exists) {
        final defaultPrefs = UserCardPreferences.empty(userId);
        await _saveUserPreferences(defaultPrefs);
        return defaultPrefs;
      }
      return UserCardPreferences.fromFirestore(doc);
    } catch (e) {
      talker.error('Error getting user preferences: $e');
      return UserCardPreferences.empty(userId);
    }
  }

  /// Save user preferences to Firestore
  Future<void> _saveUserPreferences(UserCardPreferences preferences) async {
    try {
      await _preferencesCollection
          .doc(preferences.userId)
          .set(preferences.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      talker.error('Error saving user preferences: $e');
      throw Exception('Failed to save preferences: $e');
    }
  }

  /// Toggle a card's favorite status
  Future<void> toggleFavorite(String cardId) async {
    try {
      final prefs = await getUserPreferences();
      final updatedPrefs = prefs.toggleFavorite(cardId);
      await _saveUserPreferences(updatedPrefs);
    } catch (e) {
      talker.error('Error toggling favorite: $e');
      throw Exception('Failed to toggle favorite status: $e');
    }
  }

  /// Toggle a card's wishlist status
  Future<void> toggleWishlist(String cardId) async {
    try {
      final prefs = await getUserPreferences();
      final updatedPrefs = prefs.toggleWishlist(cardId);
      await _saveUserPreferences(updatedPrefs);
    } catch (e) {
      talker.error('Error toggling wishlist: $e');
      throw Exception('Failed to toggle wishlist status: $e');
    }
  }
}

/// Provider for the card preferences repository
final cardPreferencesRepositoryProvider =
    Provider<CardPreferencesRepository>((ref) {
  return CardPreferencesRepository();
});
