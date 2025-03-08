import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fftcg_companion/core/providers/auto_auth_provider.dart';
import 'package:fftcg_companion/core/services/anonymous_auth_persistence.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';

/// Service class for handling Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();
  final AnonymousAuthPersistence _anonymousAuthPersistence =
      AnonymousAuthPersistence();
  final Ref? _ref;

  /// Creates an AuthService
  AuthService([this._ref]);

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if the user is signed in
  bool get isSignedIn => currentUser != null;

  /// Check if the user is anonymous
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      // Check if we have a saved anonymous user or device ID
      final hasSavedUser =
          await _anonymousAuthPersistence.hasSavedAnonymousUser();

      UserCredential credential;

      if (hasSavedUser) {
        // Get the device-specific anonymous ID
        final anonymousId =
            await _anonymousAuthPersistence.getSavedAnonymousUserId();

        if (anonymousId != null && anonymousId.startsWith('anon_')) {
          // This is a device-generated ID, not a Firebase UID
          // We need to create a new anonymous user but will associate it with this device
          talker.debug('Creating anonymous user with device-specific ID');
          credential = await _auth.signInAnonymously();
        } else {
          // We have a saved Firebase anonymous user
          talker.debug('Using existing anonymous user');
          credential = await _auth.signInAnonymously();
        }
      } else {
        // Create a new anonymous user
        talker.debug('Creating new anonymous user');
        credential = await _auth.signInAnonymously();
      }

      // Save the anonymous user credentials with device ID
      await _anonymousAuthPersistence.saveAnonymousUser();

      // Create user in Firestore with device ID for better tracking
      final deviceId = await _anonymousAuthPersistence.getDeviceId();

      // Add the device ID to the user's custom claims or metadata
      // This helps track the same user across reinstalls
      if (deviceId != null) {
        await _userRepository.createUserFromAuth(
          credential.user!,
          additionalData: {'deviceId': deviceId},
        );
      } else {
        await _userRepository.createUserFromAuth(credential.user!);
      }

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user in Firestore
      await _userRepository.createUserFromAuth(credential.user!);

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create a new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user in Firestore
      await _userRepository.createUserFromAuth(credential.user!);

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled by the user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create/update user in Firestore
      await _userRepository.createUserFromAuth(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Link anonymous account with email and password
  Future<UserCredential> linkWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final userCredential =
          await _auth.currentUser!.linkWithCredential(credential);

      // Update user in Firestore
      await _userRepository.createUserFromAuth(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Link anonymous account with Google
  Future<UserCredential> linkWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled by the user');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link with the credential
      final userCredential =
          await _auth.currentUser!.linkWithCredential(credential);

      // Update user in Firestore
      await _userRepository.createUserFromAuth(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Set the skip auto-auth flag to prevent creating a new anonymous user
      if (_ref != null) {
        _ref!.read(skipAutoAuthProvider.notifier).state = true;
      }

      // If the user is anonymous, just delete the user instead of signing out
      // This prevents the auto-auth provider from creating a new anonymous user
      if (isAnonymous) {
        // Clear the saved anonymous user credentials
        await _anonymousAuthPersistence.clearSavedAnonymousUser();

        // Delete the anonymous user
        await _auth.currentUser?.delete();
      } else {
        await _googleSignIn.signOut();
        await _auth.signOut();
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Update Firebase Auth profile
      if (displayName != null) await user.updateDisplayName(displayName);
      if (photoURL != null) await user.updatePhotoURL(photoURL);

      // Update user in Firestore
      await _userRepository.createUserFromAuth(user);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email.');
        case 'wrong-password':
          return Exception('Wrong password provided.');
        case 'email-already-in-use':
          return Exception('The email address is already in use.');
        case 'weak-password':
          return Exception('The password is too weak.');
        case 'operation-not-allowed':
          return Exception('This authentication method is not enabled.');
        case 'invalid-email':
          return Exception('The email address is invalid.');
        case 'account-exists-with-different-credential':
          return Exception(
              'An account already exists with the same email address but different sign-in credentials.');
        case 'invalid-credential':
          return Exception('The credential is invalid.');
        case 'user-disabled':
          return Exception('This user account has been disabled.');
        case 'requires-recent-login':
          return Exception(
              'This operation requires recent authentication. Please log in again.');
        case 'provider-already-linked':
          return Exception('This provider is already linked to your account.');
        case 'credential-already-in-use':
          return Exception(
              'This credential is already associated with a different user account.');
        default:
          return Exception('An error occurred: ${e.message}');
      }
    }
    return Exception('An unexpected error occurred: $e');
  }
}
