import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fftcg_companion/core/providers/auto_auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:fftcg_companion/features/profile/domain/models/user_model.dart';

/// Service class for handling Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserRepository _userRepository = UserRepository();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
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
      // First check if we already have an anonymous user signed in
      // This works even after app restart if persistence is enabled
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        talker.debug('Already signed in anonymously, reusing current user');
        // We can't create a UserCredential directly, so we'll just return the current user's credential
        // by signing in anonymously again, which will return the same user
        return await _auth.signInAnonymously();
      }

      UserCredential credential;

      // Create a new anonymous user
      talker.debug('Creating new anonymous user');
      credential = await _auth.signInAnonymously();
      // Create user in Firestore
      await _userRepository.createUserFromAuth(credential.user!);

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password,
      {bool requireVerification = true}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if email is verified if required
      if (requireVerification &&
          credential.user != null &&
          !credential.user!.emailVerified &&
          credential.user!.providerData
              .any((element) => element.providerId == 'password')) {
        // Send a new verification email if not verified
        await credential.user!.sendEmailVerification();

        // Throw an exception to prevent login
        throw Exception(
            'Email not verified. A new verification email has been sent. Please check your inbox and verify your email before logging in.');
      }

      // Update user in Firestore
      await _userRepository.createUserFromAuth(credential.user!);

      // Update verification status
      await updateVerificationStatus();

      return credential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create a new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password,
      {bool sendVerificationEmail = true}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      if (sendVerificationEmail && credential.user != null) {
        await credential.user!.sendEmailVerification();
        talker.debug('Verification email sent to ${credential.user!.email}');
      }

      // Create user in Firestore with isVerified = false
      await _userRepository
          .createUserFromAuth(credential.user!, additionalData: {
        'isVerified': false,
      });

      return credential;
    } catch (e) {
      talker.error('Error creating user: $e');
      throw _handleAuthException(e);
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Check if running on an emulator
      bool isEmulator = false;
      try {
        // This is a simple check that might help identify emulators
        final androidId = await _getAndroidId();
        isEmulator =
            androidId == 'emulator' || androidId.startsWith('emulator');
        talker.debug(
            'Device check: isEmulator = $isEmulator, androidId = $androidId');
      } catch (e) {
        talker.debug('Failed to check if device is emulator: $e');
      }

      if (isEmulator) {
        talker.warning(
            'Running on emulator - Google Sign-In may not work properly');
      }

      // Trigger the authentication flow
      talker.debug('Starting Google Sign-In flow');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      talker.debug(
          'Google Sign-In attempt: ${googleUser?.email ?? "No user selected"}');

      if (googleUser == null) {
        talker.warning('Google Sign-In was cancelled or failed');
        throw Exception('Google sign in was cancelled by the user');
      }

      talker.debug('Google Auth completed for: ${googleUser.email}');

      // Obtain the auth details from the request
      talker.debug('Getting Google authentication details');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      talker.debug('Creating Firebase credential from Google auth');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      talker.debug('Google credential created, signing in with Firebase');

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      talker
          .debug('Firebase sign-in successful: ${userCredential.user?.email}');

      // Create/update user in Firestore
      await _userRepository.createUserFromAuth(userCredential.user!);

      return userCredential;
    } catch (e) {
      talker.error('Error signing in with Google: $e');

      // Provide more specific error messages
      if (e.toString().contains('network_error')) {
        throw Exception(
            'Network error occurred. Please check your internet connection and try again.');
      } else if (e.toString().contains('sign_in_failed') ||
          e.toString().contains('sign_in_canceled')) {
        throw Exception(
            'Google Sign-In was cancelled or failed. Please try again.');
      } else if (e.toString().contains('popup_closed')) {
        throw Exception(
            'Sign-in popup was closed before completing the process. Please try again.');
      }

      throw _handleAuthException(e);
    }
  }

  /// Link anonymous account with email and password
  Future<UserCredential> linkWithEmailAndPassword(
      String email, String password) async {
    try {
      talker.debug('Linking anonymous account with email/password');

      // Store the current displayName before linking
      final currentUser = _auth.currentUser;
      final currentDisplayName = currentUser?.displayName;

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final userCredential =
          await _auth.currentUser!.linkWithCredential(credential);

      // If the user had a displayName before linking, preserve it
      if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(currentDisplayName);
      }

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
      talker.debug('Linking anonymous account with Google');

      // Check if running on an emulator
      bool isEmulator = false;
      try {
        // This is a simple check that might help identify emulators
        final androidId = await _getAndroidId();
        isEmulator =
            androidId == 'emulator' || androidId.startsWith('emulator');
        talker.debug(
            'Device check: isEmulator = $isEmulator, androidId = $androidId');
      } catch (e) {
        talker.debug('Failed to check if device is emulator: $e');
      }

      if (isEmulator) {
        talker.warning(
            'Running on emulator - Google Sign-In may not work properly');
      }

      // Store the current displayName before linking
      final currentUser = _auth.currentUser;
      talker.debug(
          'Current user before linking: ${currentUser?.uid}, displayName: ${currentUser?.displayName}');
      final currentDisplayName = currentUser?.displayName;

      // Trigger the authentication flow
      talker.debug('Starting Google Sign-In flow for account linking');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      talker.debug(
          'Google Sign-In for linking: ${googleUser?.email ?? "No user selected"}');

      if (googleUser == null) {
        talker.warning('Google Sign-In was cancelled or failed during linking');
        throw Exception('Google sign in was cancelled by the user');
      }

      // Obtain the auth details from the request
      talker.debug('Getting Google authentication details for linking');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      talker.debug('Google Auth completed for linking');

      // Create a new credential
      talker.debug('Creating Firebase credential from Google auth for linking');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link with the credential
      talker.debug('Attempting to link with credential');
      try {
        final userCredential =
            await _auth.currentUser!.linkWithCredential(credential);

        talker.debug(
            'Account successfully linked: ${userCredential.user?.email}');

        // If the user had a displayName before linking, preserve it
        if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
          talker.debug('Preserving original displayName: $currentDisplayName');
          await userCredential.user!.updateDisplayName(currentDisplayName);
        }

        // Update user in Firestore
        await _userRepository.createUserFromAuth(userCredential.user!);

        return userCredential;
      } catch (linkError) {
        talker.error('Error during credential linking: $linkError');

        // Check for specific linking errors
        if (linkError.toString().contains('credential-already-in-use')) {
          throw Exception(
              'This Google account is already linked to another user. Please use a different Google account.');
        } else if (linkError.toString().contains('email-already-in-use')) {
          throw Exception(
              'An account already exists with the same email address. Please use a different Google account.');
        }

        rethrow;
      }
    } catch (e) {
      talker.error('Error linking with Google: $e');
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

      // Force refresh the user to get the latest data
      await user.reload();
      final updatedUser = _auth.currentUser;

      // Update user in Firestore with explicit displayName parameter
      // This ensures we're using the latest value
      await _userRepository.createOrUpdateUser(
        UserModel(
          id: updatedUser!.uid,
          displayName: displayName ?? updatedUser.displayName,
          email: updatedUser.email,
          photoURL: photoURL ?? updatedUser.photoURL,
          lastAccessed: Timestamp.now(),
          lastLogin: Timestamp.now(),
          createdAt: Timestamp
              .now(), // This will be ignored for existing users due to merge: true
        ),
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Check if the current user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Force refresh to get the latest user data
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      talker.error('Error checking email verification: $e');
      return false;
    }
  }

  /// Update the user's verification status in Firestore
  Future<void> updateVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Force refresh to get the latest user data
      await user.reload();
      final isVerified = user.emailVerified;

      // Get the current user from Firestore
      final firestoreUser = await _userRepository.getUserById(user.uid);
      if (firestoreUser == null) throw Exception('User not found in Firestore');

      // Update the verification status if it has changed
      if (firestoreUser.isVerified != isVerified) {
        await _userRepository.createOrUpdateUser(
          firestoreUser.copyWith(isVerified: isVerified),
        );
        talker.debug(
            'Updated verification status to $isVerified for user ${user.uid}');
      }

      return;
    } catch (e) {
      talker.error('Error updating verification status: $e');
      throw _handleAuthException(e);
    }
  }

  /// Send verification email before updating email
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Send verification email before updating email
      await user.verifyBeforeUpdateEmail(newEmail);

      return;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Helper method to check if running on an emulator
  Future<String> _getAndroidId() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;

      // Check various properties that might indicate an emulator
      final String manufacturer = androidInfo.manufacturer;
      final String model = androidInfo.model;
      final String brand = androidInfo.brand;
      final String id = androidInfo.id;

      talker.debug(
          'Device info: manufacturer=$manufacturer, model=$model, brand=$brand, id=$id');

      // Common emulator indicators
      final bool isEmulator =
          manufacturer.toLowerCase().contains('genymotion') ||
              manufacturer.toLowerCase().contains('google') ||
              model.toLowerCase().contains('sdk') ||
              model.toLowerCase().contains('emulator') ||
              model.toLowerCase().contains('android sdk') ||
              brand.toLowerCase().contains('generic') ||
              id.toLowerCase().contains('emulator');

      if (isEmulator) {
        talker.warning('Device appears to be an emulator');
        return 'emulator';
      }

      return id;
    } catch (e) {
      talker.error('Error getting Android ID: $e');
      return 'unknown';
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
