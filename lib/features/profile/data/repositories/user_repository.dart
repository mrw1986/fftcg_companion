import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/features/profile/domain/models/user_model.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Repository for managing user data in Firestore
class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Talker talker = Talker();

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get a user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, id: doc.id);
      }
      return null;
    } catch (e) {
      // Log error
      return null;
    }
  }

  /// Get the current user
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserById(user.uid);
  }

  /// Create or update a user in Firestore
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      talker.error('Error creating or updating user: $e');
      rethrow;
    }
  }

  /// Create a user from Firebase Auth user
  ///
  /// [additionalData] Optional additional data to store with the user
  Future<UserModel> createUserFromAuth(
    User authUser, {
    Map<String, dynamic>? additionalData,
  }) async {
    // Check if user already exists
    final existingUser = await getUserById(authUser.uid);
    if (existingUser != null) {
      // Update last login time and any additional data
      Map<String, dynamic> updatedSettings = {...existingUser.settings};

      // Add device ID to settings if provided
      if (additionalData != null) {
        updatedSettings = {...updatedSettings, ...additionalData};
      }

      final updatedUser = existingUser.copyWith(
        lastLogin: Timestamp.now(),
        lastAccessed: Timestamp.now(),
        // Always use the latest info from Firebase Auth, even if it's null
        // This ensures we don't have stale data
        displayName: authUser.displayName,
        email: authUser.email ?? existingUser.email,
        photoURL: authUser.photoURL ?? existingUser.photoURL,
        isVerified: authUser.emailVerified, // Update verification status
        settings: updatedSettings,
      );
      await createOrUpdateUser(updatedUser);
      return updatedUser;
    }

    // Create new user
    Map<String, dynamic> settings = {};

    // Add device ID to settings if provided
    if (additionalData != null) {
      settings = {...settings, ...additionalData};
    }

    final newUser = UserModel(
      id: authUser.uid,
      displayName: authUser.displayName,
      email: authUser.email,
      photoURL: authUser.photoURL,
      createdAt: Timestamp.now(),
      lastLogin: Timestamp.now(),
      lastAccessed: Timestamp.now(),
      isVerified: authUser.emailVerified, // Set initial verification status
      settings: settings,
    );
    await createOrUpdateUser(newUser);

    // Initialize collection count
    try {
      await updateCollectionCount(newUser.id, 0);
    } catch (e) {
      talker.error('Error initializing collection count: $e');
      // Continue with user creation even if collection count initialization fails
    }

    return newUser;
  }

  /// Update user settings
  Future<void> updateUserSettings(
      String userId, Map<String, dynamic> settings) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      // Merge existing settings with new settings
      final updatedSettings = {...user.settings, ...settings};
      final updatedUser = user.copyWith(settings: updatedSettings);
      await createOrUpdateUser(updatedUser);
    } catch (e) {
      talker.error('Error updating user settings: $e');
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      talker.error('Error deleting user: $e');
      rethrow;
    }
  }

  /// Update user email
  Future<void> updateUserEmail(
    String userId,
    String email,
  ) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw Exception('User not found');
      final updatedUser = user.copyWith(email: email);
      await createOrUpdateUser(updatedUser);
    } catch (e) {
      talker.error('Error updating user email: $e');
      rethrow;
    }
  }

  /// Update user collection count
  ///
  /// This method is used to increment or set the collection count for a user
  /// It's used by the CollectionRepository when adding or removing items
  Future<void> updateCollectionCount(String userId, int count,
      {bool increment = false}) async {
    try {
      final user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      int newCount;
      if (increment) {
        // Increment the current count
        newCount = user.collectionCount + count;
      } else {
        // Set to the specified count
        newCount = count;
      }

      // Ensure count is never negative
      newCount = newCount < 0 ? 0 : newCount;

      final updatedUser = user.copyWith(collectionCount: newCount);
      await createOrUpdateUser(updatedUser);

      talker.debug('Updated collection count for user $userId: $newCount');
    } catch (e) {
      talker.error('Error updating collection count: $e');
      rethrow;
    }
  }
}
