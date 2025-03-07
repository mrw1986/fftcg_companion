import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';

/// Service class for handling Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();

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
      final credential = await _auth.signInAnonymously();

      // Create user in Firestore
      await _userRepository.createUserFromAuth(credential.user!);

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
      await _googleSignIn.signOut();
      await _auth.signOut();
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
