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

  // Define a timeout duration for auth operations
  static const Duration _timeout = Duration(seconds: 30);

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
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(_timeout);

      // Check if email is verified if required
      if (requireVerification &&
          credential.user != null &&
          !credential.user!.emailVerified &&
          credential.user!.providerData
              .any((element) => element.providerId == 'password')) {
        // Send a new verification email if not verified
        try {
          await credential.user!.sendEmailVerification().timeout(_timeout);
          talker.info('Verification email sent to ${credential.user!.email}');
          talker.debug('User ID: ${credential.user!.uid}');
        } catch (verificationError) {
          talker.error('Error sending verification email: $verificationError');
          // Continue with the error handling below
        }

        // Throw an exception to prevent login
        throw FirebaseAuthException(
          code: 'email-not-verified',
          message:
              'Email not verified. A new verification email has been sent. Please check your inbox and verify your email before logging in.',
        );
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
      // Create the user account
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email,
            password: password,
          )
          .timeout(_timeout);

      // Send email verification
      if (sendVerificationEmail && credential.user != null) {
        try {
          // Send verification email
          await credential.user!.sendEmailVerification().timeout(_timeout);
          talker.info('Verification email sent to ${credential.user!.email}');
          talker.debug('User created: ${credential.user!.uid}');
        } catch (verificationError) {
          talker.error(
              'Error sending verification email (createUser): $verificationError');
          // Continue with account creation but log the error
        }
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

      // Try to link the account
      UserCredential userCredential;
      try {
        userCredential =
            await _auth.currentUser!.linkWithCredential(credential);
      } catch (e) {
        talker.error('Error linking with email/password: $e');

        // If the error is related to reCAPTCHA, try a different approach
        if (e.toString().contains('reCAPTCHA') ||
            e.toString().contains('App Check') ||
            e.toString().contains('token')) {
          talker.debug('Attempting alternative linking approach');

          // Create a new user with the email/password
          final tempAuth = FirebaseAuth.instance;
          final tempUser = await tempAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Send verification email to the new user
          await tempUser.user!.sendEmailVerification().timeout(_timeout);

          // Sign out the temporary user
          await tempAuth.signOut();

          // Return to the original user and throw a custom exception
          throw FirebaseAuthException(
            code: 'manual-linking-required',
            message:
                'Please check your email for verification and then sign in with your new account.',
          );
        }

        // If it's another error, rethrow it
        rethrow;
      }

      // If the user had a displayName before linking, preserve it
      if (currentDisplayName != null && currentDisplayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(currentDisplayName);
      }

      // Send verification email
      try {
        await userCredential.user!.sendEmailVerification().timeout(_timeout);
        talker.info('Verification email sent to ${userCredential.user!.email}');
      } catch (verificationError) {
        talker.error(
            'Error sending verification email after linking: $verificationError');
        // Continue with account linking but log the error
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

  /// Delete the current user account (non-anonymous)
  ///
  /// This method deletes the current user account and all associated data.
  /// It requires recent authentication, so it may throw a requires-recent-login error.
  /// In that case, you should call reauthenticateUser first.
  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Check if the user is anonymous
      if (user.isAnonymous) {
        // For anonymous users, we can just delete them directly
        await user.delete();
        talker.debug('Anonymous user deleted successfully');
        return;
      }

      // For non-anonymous users, we need to delete their data from Firestore first
      // and then delete the user account
      try {
        // Delete user data from Firestore
        await _userRepository.deleteUser(user.uid);
        talker.debug('User data deleted from Firestore');

        // Delete the user account
        await user.delete();
        talker.debug('User account deleted successfully');
      } on FirebaseAuthException catch (e) {
        talker.error('FirebaseAuthException in deleteUser: ${e.code}');
        rethrow;
      } catch (e) {
        talker.error('Unexpected error in deleteUser: $e');
        rethrow;
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate a user for security-sensitive operations
  ///
  /// This method is required before performing security-sensitive operations
  /// such as deleting an account, changing email, or changing password.
  ///
  /// The method accepts different credential types:
  /// - For email/password: EmailAuthProvider.credential(email, password)
  /// - For Google: GoogleAuthProvider.credential(idToken, accessToken)
  ///
  /// @param credential The AuthCredential to use for re-authentication
  /// @return UserCredential if successful
  Future<UserCredential> reauthenticateUser(AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      talker.debug('Re-authenticating user: ${user.email}');

      // Re-authenticate the user
      final userCredential =
          await user.reauthenticateWithCredential(credential).timeout(_timeout);
      talker.debug('User re-authenticated successfully');

      return userCredential;
    } catch (e) {
      talker.error('Error re-authenticating user: $e');
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate with email and password
  ///
  /// Convenience method for re-authenticating with email and password
  Future<UserCredential> reauthenticateWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      return await reauthenticateUser(credential);
    } catch (e) {
      talker.error('Error re-authenticating with email/password: $e');
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate with Google
  ///
  /// Convenience method for re-authenticating with Google
  Future<UserCredential> reauthenticateWithGoogle() async {
    try {
      // Check if running on an emulator
      bool isEmulator = false;
      try {
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
      talker.debug('Starting Google Sign-In flow for re-authentication');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        talker.warning(
            'Google Sign-In was cancelled or failed during re-authentication');
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

      // Re-authenticate with the credential
      return await reauthenticateUser(credential);
    } catch (e) {
      talker.error('Error re-authenticating with Google: $e');
      throw _handleAuthException(e);
    }
  }

  /// Unlink an authentication provider from the current user
  ///
  /// @param providerId The provider ID to unlink (e.g., 'google.com', 'password')
  Future<User> unlinkProvider(String providerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Check if the user has more than one provider
      if (user.providerData.length <= 1) {
        throw Exception(
            'Cannot unlink the last authentication provider. You must have at least one way to sign in.');
      }

      talker.debug('Unlinking provider: $providerId');
      final updatedUser = await user.unlink(providerId);

      // Update user in Firestore
      await _userRepository.createUserFromAuth(updatedUser);

      talker.debug('Provider unlinked successfully');
      return updatedUser;
    } catch (e) {
      talker.error('Error unlinking provider: $e');
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email).timeout(_timeout);
      talker.info('Password reset email sent to $email');
    } catch (e) {
      talker.error('Error sending password reset email: $e');
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No user is signed in');

      // Force refresh to get the latest user data
      await currentUser.reload();
      final isVerified = currentUser.emailVerified;

      // Get the current user from Firestore
      final firestoreUser = await _userRepository.getUserById(currentUser.uid);
      if (firestoreUser == null) throw Exception('User not found in Firestore');

      // Update the verification status if it has changed
      if (firestoreUser.isVerified != isVerified) {
        await _userRepository.createOrUpdateUser(
          firestoreUser.copyWith(isVerified: isVerified),
        );
        talker.info(
            'Updated verification status to $isVerified for user ${currentUser.uid}');
      }

      return;
    } catch (e) {
      talker.error('Error updating verification status: $e');
      throw _handleAuthException(e);
    }
  }

  /// Send verification email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification().timeout(_timeout);
        talker.info('Verification email sent to ${user.email}');
      }
    } catch (e) {
      talker.error('Error sending email verification', e);
      rethrow;
    }
  }

  /// Send verification email before updating email
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user is signed in');

      // Send verification email before updating email
      try {
        // Send a simple verification email
        await user.verifyBeforeUpdateEmail(newEmail).timeout(_timeout);
        talker.info('Verification email sent to $newEmail');
        talker.debug('Email update verification sent for user: ${user.uid}');
      } catch (e) {
        talker.error('Error sending verification email (updateEmail): $e');
        throw FirebaseAuthException(
          code: 'verification-email-failed',
          message:
              'Failed to send verification email. Please try again later or contact support.',
        );
      }

      return;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle email verification completion
  /// This method is called when a user's email is verified
  Future<void> handleEmailVerificationComplete() async {
    talker.info('Handling email verification completion');
    try {
      final user = _auth.currentUser;
      if (user == null) {
        talker.warning(
            'No user found when handling email verification completion');
        return;
      }

      // Force refresh the user to get the latest verification status
      talker.info('Reloading user to get latest verification status');
      await user.reload();

      // Get the refreshed user
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        talker.warning(
            'User not found after reload in handleEmailVerificationComplete');
        return;
      }

      // Check if the email is verified
      if (!refreshedUser.emailVerified) {
        talker.warning('User email still not verified after reload');
        return;
      }

      talker.info(
          'Email verification confirmed for user: ${refreshedUser.email}');

      // Update the verification status in Firestore
      await updateVerificationStatus();

      // Force refresh the ID token to update the auth state
      talker.info('Refreshing auth tokens after email verification');
      final newToken = await refreshedUser.getIdToken(true);
      talker.debug('New ID token obtained, length: ${newToken?.length ?? 0}');

      // Get a fresh ID token result to ensure claims are updated
      final tokenResult = await refreshedUser.getIdTokenResult(true);
      talker.debug('Token issued at: ${tokenResult.issuedAtTime}');
      talker.debug('Token expiration: ${tokenResult.expirationTime}');

      // Sign out and sign back in to fully refresh the auth state
      // This is a more aggressive approach but ensures the UI updates
      if (refreshedUser.providerData
          .any((element) => element.providerId == 'password')) {
        talker.debug('Performing a re-authentication to refresh auth state');
        try {
          // We don't have the password here, so we can't do a full re-auth
          // Instead, we'll just reload the user again
          await refreshedUser.reload();
          talker.debug('User reloaded again after verification');
        } catch (reloadError) {
          talker.error('Error reloading user after verification', reloadError);
          // Continue with the process despite the error
        }
      }

      // Reload the user one more time to ensure we have the latest state
      await refreshedUser.reload();

      talker.info(
          'Email verification completed for user: ${refreshedUser.email}');
    } catch (e) {
      talker.error('Error handling email verification completion', e);
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

  /// Get a user-friendly error message for Firebase authentication errors
  String getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'cancelled-by-user':
        return 'Sign-in was cancelled. You can try again when you\'re ready.';
      case 'too-many-requests':
        return e.message ?? 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in or use a different email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'user-not-found':
        return 'No account found with this email. Please check the email or create an account.';
      case 'invalid-credential':
        return 'Invalid login credentials. Please check your email and password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'email-not-verified':
        return 'Please verify your email address. A verification email has been sent.';
      case 'app-check-failed':
        return 'App verification failed. Please try again or reinstall the app.';
      case 'no-connection':
        return 'No internet connection. Please check your connection and try again.';
      case 'google-sign-in-cancelled':
        return 'Google sign in was cancelled. Please try again.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    // Handle Google Sign-In cancellation
    if (e is Exception &&
        e.toString().contains('sign in was cancelled by the user')) {
      return FirebaseAuthException(
        code: 'cancelled-by-user',
        message: 'Sign-in was cancelled. You can try again when you\'re ready.',
      );
    }

    if (e is FirebaseAuthException) {
      switch (e.code) {
        // Email/Password Authentication Errors
        case 'user-not-found':
          return Exception(
              'No account found with this email address. Please check your email or create a new account.');
        case 'wrong-password':
          return Exception(
              'Incorrect password. Please try again or use the "Forgot Password" option.');
        case 'email-already-in-use':
          return Exception(
              'An account already exists with this email address. Please sign in or use a different email.');
        case 'weak-password':
          return Exception(
              'The password is too weak. Please use a stronger password with at least 8 characters, including uppercase, lowercase, numeric, and special characters.');
        case 'operation-not-allowed':
          return Exception(
              'This authentication method is not enabled. Please contact support or try a different sign-in method.');
        case 'invalid-email':
          return Exception('Please enter a valid email address.');
        case 'user-disabled':
          return Exception(
              'This account has been disabled. Please contact support for assistance.');
        case 'too-many-requests':
          return Exception(
              'Too many sign-in attempts. Please try again later or reset your password.');
        case 'user-token-expired':
          return Exception('Your session has expired. Please sign in again.');
        case 'network-request-failed':
          return Exception(
              'Network error. Please check your internet connection and try again.');
        case 'INVALID_LOGIN_CREDENTIALS':
          return Exception(
              'Invalid login credentials. Please check your email and password.');
        case 'invalid-credential':
          return Exception(
              'The authentication credentials are invalid. Please try again.');
        case 'email-not-verified':
          return Exception(
              'Email not verified. A verification email has been sent. Please check your inbox and verify your email before logging in.');
        case 'verification-email-failed':
          return Exception(
              'Failed to send verification email. Please try again later or contact support.');
        case 'manual-linking-required':
          return Exception(
              'Please check your email for verification and then sign in with your new account.');

        // Federated Identity Provider Errors
        case 'account-exists-with-different-credential':
          return Exception(
              'An account already exists with the same email address but different sign-in credentials. Please sign in using your original provider.');
        case 'invalid-verification-code':
          return Exception(
              'The verification code is invalid. Please try again with a new code.');
        case 'invalid-verification-id':
          return Exception(
              'The verification ID is invalid. Please restart the verification process.');

        // Re-authentication Errors
        case 'requires-recent-login':
          return Exception(
              'For security reasons, this operation requires recent authentication. Please sign in again before retrying.');
        case 'user-mismatch':
          return Exception(
              'The provided credentials do not correspond to the current user. Please use the credentials for this account.');

        // Provider Linking Errors

        case 'provider-already-linked':
          return Exception(
              'This authentication provider is already linked to your account.');
        case 'no-such-provider':
          return Exception(
              'The specified authentication provider is not linked to this account.');
        case 'credential-already-in-use':
          return Exception(
              'This credential is already associated with a different user account. Please use a different credential or sign in with the associated account.');

        // Multi-factor Authentication Errors
        case 'second-factor-required':
          return Exception(
              'Multi-factor authentication is required. Please complete the second authentication step.');
        case 'tenant-id-mismatch':
          return Exception(
              'The provided tenant ID does not match the Auth instance\'s tenant ID.');

        // Phone Authentication Errors
        case 'quota-exceeded':
          return Exception('SMS quota exceeded. Please try again later.');
        case 'missing-phone-number':
          return Exception('Please provide a phone number.');
        case 'invalid-phone-number':
          return Exception(
              'The phone number format is incorrect. Please enter a valid phone number.');
        case 'captcha-check-failed':
          return Exception(
              'The reCAPTCHA verification failed. Please try again.');

        // General Errors
        default:
          return Exception('Authentication error: ${e.message}');
      }
    }
    return Exception(
        'An unexpected error occurred. Please try again or contact support if the problem persists.');
  }
}
