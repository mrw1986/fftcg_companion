import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/features/profile/domain/models/user_model.dart';

/// Repository for managing user data in Firestore
class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

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
      // Log error
      rethrow;
    }
  }

  /// Create a user from Firebase Auth user
  Future<UserModel> createUserFromAuth(User authUser) async {
    // Check if user already exists
    final existingUser = await getUserById(authUser.uid);
    if (existingUser != null) {
      // Update last login time
      final updatedUser = existingUser.copyWith(
        lastLogin: Timestamp.now(),
        displayName: authUser.displayName ?? existingUser.displayName,
        email: authUser.email ?? existingUser.email,
        photoURL: authUser.photoURL ?? existingUser.photoURL,
      );
      await createOrUpdateUser(updatedUser);
      return updatedUser;
    }

    // Create new user
    final newUser = UserModel(
      id: authUser.uid,
      displayName: authUser.displayName,
      email: authUser.email,
      photoURL: authUser.photoURL,
      createdAt: Timestamp.now(),
      lastLogin: Timestamp.now(),
    );
    await createOrUpdateUser(newUser);
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
      // Log error
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      // Log error
      rethrow;
    }
  }
}
