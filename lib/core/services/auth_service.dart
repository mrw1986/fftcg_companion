import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';

/// Enum for categorizing authentication errors
enum AuthErrorCategory {
  /// Authentication errors (wrong password, user not found, etc.)
  authentication,

  /// Network errors (timeout, no internet, etc.)
  network,

  /// Permission errors (insufficient permissions, etc.)
  permission,

  /// Validation errors (invalid email, weak password, etc.)
  validation,

  /// Unknown errors
  unknown
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String code;
  final String message;
  final AuthErrorCategory category;
  final dynamic originalException;

  AuthException({
    required this.code,
    required this.message,
    required this.category,
    this.originalException,
  });

  @override
  String toString() => 'AuthException: [$code] $message';
}

/// Service for handling Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;
  final talker = Talker();
  final Duration _timeout = const Duration(seconds: 30);

  AuthService()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(),
        _userRepository = UserRepository();

  /// Get the current user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //
  // Core Authentication Methods
  //

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _userRepository.createUserFromAuth(userCredential.user!);
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Create a new user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      try {
        await userCredential.user!.sendEmailVerification().timeout(_timeout);
        talker.info('Verification email sent to ${userCredential.user!.email}');
      } catch (verificationError) {
        talker.error('Error sending verification email: $verificationError');
        // Continue with account creation but log the error
      }

      await _userRepository.createUserFromAuth(userCredential.user!);
      return userCredential;
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
        throw FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Google sign in was cancelled.',
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      await _userRepository.createUserFromAuth(userCredential.user!);
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
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

  //
  // Account Linking Methods
  //

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
        // Try to link directly - if the email exists, we'll get an error
        userCredential =
            await _auth.currentUser!.linkWithCredential(credential);
      } catch (linkError) {
        talker.error('Error linking with email/password: $linkError');

        if (linkError is FirebaseAuthException) {
          switch (linkError.code) {
            case 'provider-already-linked':
              throw FirebaseAuthException(
                code: 'provider-already-linked',
                message: 'This email is already linked to your account.',
              );
            case 'invalid-credential':
              throw FirebaseAuthException(
                code: 'invalid-credential',
                message:
                    'The email/password combination is invalid. Please try again.',
              );
            case 'credential-already-in-use':
            case 'email-already-in-use':
              // Try to sign in with the existing account
              try {
                await signOut();
                return await signInWithEmailAndPassword(email, password);
              } catch (signInError) {
                if (signInError is FirebaseAuthException &&
                    signInError.code == 'wrong-password') {
                  throw FirebaseAuthException(
                    code: 'account-exists',
                    message:
                        'An account already exists with this email. Please sign in with your existing password.',
                  );
                }
                rethrow;
              }
            case 'operation-not-allowed':
              throw FirebaseAuthException(
                code: 'operation-not-allowed',
                message:
                    'Email/password accounts are not enabled. Please contact support.',
              );
            case 'too-many-requests':
              throw FirebaseAuthException(
                code: 'too-many-requests',
                message: 'Too many attempts. Please try again later.',
              );
            default:
              rethrow;
          }
        }
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

  /// Link with Google
  Future<UserCredential> linkWithGoogle() async {
    try {
      // Trigger the authentication flow
      late AuthCredential credential;
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'sign-in-cancelled',
            message: 'Google sign in was cancelled.',
          );
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Link the credential to the current user
        final userCredential =
            await _auth.currentUser!.linkWithCredential(credential);
        await _userRepository.createUserFromAuth(userCredential.user!);
        return userCredential;
      } catch (linkError) {
        if (linkError is FirebaseAuthException) {
          if (linkError.code == 'provider-already-linked') {
            // If the provider is already linked, just return the current user credential
            talker.debug(
                'Provider already linked to this account, signing out and signing in with Google');
            await signOut();
            return await signInWithGoogle();
          } else if (linkError.code == 'credential-already-in-use') {
            // If the credential is already in use by another account, retrieve the existing user and sign in
            talker.debug(
                'Credential already in use by another account, retrieving existing user and signing in');
            final existingUserCredential =
                await _auth.signInWithCredential(credential);
            await _userRepository
                .createUserFromAuth(existingUserCredential.user!);
            return existingUserCredential;
          }
        }
        rethrow;
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Link Email/Password to an existing Google-authenticated account
  Future<UserCredential> linkEmailPasswordToGoogleAccount(
      String email, String password) async {
    try {
      talker.debug('Linking Email/Password to Google account');

      // Check if the current user is authenticated with Google
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }

      // Check if the user is already using Email/Password
      final isUsingEmailPassword = currentUser.providerData
          .any((element) => element.providerId == 'password');
      if (isUsingEmailPassword) {
        throw FirebaseAuthException(
          code: 'provider-already-linked',
          message: 'Email/Password is already linked to your account.',
        );
      }

      // Create Email/Password credential
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Link the credential to the current user
      final userCredential = await currentUser.linkWithCredential(credential);

      // Update user in Firestore
      await _userRepository.createUserFromAuth(userCredential.user!);

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Unlink provider
  Future<User> unlinkProvider(String providerId) async {
    try {
      final user = await _auth.currentUser?.unlink(providerId);
      if (user == null) {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No user is currently signed in.',
        );
      }
      await _userRepository.createUserFromAuth(user);
      return user;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  //
  // Email and Password Management
  //

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification().timeout(_timeout);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email).timeout(_timeout);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update email
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    try {
      // Store the user ID before updating email
      final userId = _auth.currentUser?.uid;

      // Update the email in Firebase Auth
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);

      // Update the email in Firestore as well
      // This ensures that when the user logs back in, the email in Firestore matches
      if (userId != null) {
        await _userRepository.updateUserEmail(userId, newEmail);
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  //
  // Profile Management
  //

  /// Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
      if (_auth.currentUser != null) {
        await _userRepository.createUserFromAuth(_auth.currentUser!);
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Delete user
  Future<void> deleteUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _userRepository.deleteUser(user.uid);
        await user.delete();
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  //
  // Re-authentication Methods
  //

  /// Re-authenticate with email and password
  Future<UserCredential> reauthenticateWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final userCredential =
          await _auth.currentUser!.reauthenticateWithCredential(credential);
      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate with Google
  Future<UserCredential> reauthenticateWithGoogle() async {
    try {
      talker.debug('Starting Google re-authentication');

      // Store the current user's email for verification later
      final currentEmail = _auth.currentUser?.email;

      // First approach: Try to use the standard reauthentication flow
      try {
        // Sign out from Google (but not Firebase) to ensure a fresh authentication
        await _googleSignIn.signOut();

        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(
            code: 'sign-in-cancelled',
            message: 'Google sign in was cancelled.',
          );
        }

        // Verify it's the same email
        if (googleUser.email != currentEmail) {
          talker.warning(
              'User tried to reauthenticate with a different Google account');
          throw FirebaseAuthException(
            code: 'wrong-account',
            message:
                'Please use the same Google account you originally signed in with.',
          );
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Try to reauthenticate with the credential
        final userCredential =
            await _auth.currentUser!.reauthenticateWithCredential(credential);
        talker.debug('Standard Google reauthentication successful');
        return userCredential;
      } catch (reauthError) {
        // If the standard approach fails, log the error and try the alternative approach
        talker.error('Standard Google reauthentication failed: $reauthError');

        if (reauthError is FirebaseAuthException) {
          // If it's a token issue or requires recent login, try the alternative approach
          if (reauthError.code == 'user-token-expired' ||
              reauthError.code == 'requires-recent-login' ||
              reauthError.message?.contains('token') == true ||
              reauthError.message?.contains('BAD_REQUEST') == true) {
            talker.debug('Trying alternative Google reauthentication approach');

            // Alternative approach: Sign out completely and sign in again
            try {
              // Sign out from both Google and Firebase
              await signOut();

              // Sign in with Google again
              final newCredential = await signInWithGoogle();

              // Verify it's the same user (by email)
              if (newCredential.user?.email != currentEmail) {
                talker.warning(
                    'User signed in with a different Google account during reauthentication');
                throw FirebaseAuthException(
                  code: 'wrong-account',
                  message:
                      'You signed in with a different Google account. Please use your original account.',
                );
              }

              talker.debug('Alternative Google reauthentication successful');
              return newCredential;
            } catch (alternativeError) {
              talker.error(
                  'Alternative Google reauthentication failed: $alternativeError');
              rethrow;
            }
          }
        }

        // If it's not a token issue or the alternative approach failed, rethrow the original error
        rethrow;
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  //
  // Email Verification and Status Methods
  //

  /// Handle email verification completion
  Future<void> handleEmailVerificationComplete() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        await _userRepository.createUserFromAuth(user);
      }
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Check if a user's email is verified
  Future<bool> isEmailVerified() async {
    try {
      // Reload the user to get the latest email verification status
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      talker.error('Error checking email verification status: $e');
      return false;
    }
  }

  /// Check if a user's account is older than the specified number of days
  Future<bool> isAccountOlderThan(int days) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final metadata = user.metadata;
      final creationTime = metadata.creationTime;
      if (creationTime == null) return false;

      final now = DateTime.now();
      final difference = now.difference(creationTime);

      return difference.inDays > days;
    } catch (e) {
      talker.error('Error checking account age: $e');
      return false;
    }
  }

  /// Check if the current user is anonymous
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  //
  // Error Handling
  //

  /// Get readable auth error message
  String getReadableAuthError(FirebaseAuthException e) {
    // In production, use more generic error messages for security
    if (kReleaseMode) {
      return _getSecureErrorMessage(e);
    }

    // In development, provide detailed error messages
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'provider-already-linked':
        return 'This provider is already linked to your account.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'invalid-credential':
        return 'The provided credential is invalid.';
      case 'account-exists':
        return 'An account already exists with this email. Please sign in with your existing password.';
      case 'verification-throttled':
        return 'Too many verification emails sent. Please try again later.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  }

  /// Get secure error message for production
  String _getSecureErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';

      case 'email-already-in-use':
      case 'account-exists':
      case 'credential-already-in-use':
        return 'An account already exists with this email.';

      case 'weak-password':
      case 'invalid-email':
        return 'Please provide a valid email and a strong password.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';

      case 'too-many-requests':
      case 'verification-throttled':
        return 'Too many attempts. Please try again later.';

      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';

      case 'provider-already-linked':
        return 'This provider is already linked to your account.';

      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';

      default:
        return 'An error occurred. Please try again later.';
    }
  }

  /// Categorize authentication error
  AuthErrorCategory _categorizeError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'user-disabled':
        case 'requires-recent-login':
        case 'provider-already-linked':
          return AuthErrorCategory.authentication;

        case 'network-request-failed':
        case 'timeout':
          return AuthErrorCategory.network;

        case 'operation-not-allowed':
          return AuthErrorCategory.permission;

        case 'weak-password':
        case 'invalid-email':
        case 'email-already-in-use':
        case 'invalid-credential':
          return AuthErrorCategory.validation;

        default:
          return AuthErrorCategory.unknown;
      }
    } else if (e is TimeoutException) {
      return AuthErrorCategory.network;
    }

    return AuthErrorCategory.unknown;
  }

  /// Handle authentication exceptions
  Exception _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      final category = _categorizeError(e);
      final message = getReadableAuthError(e);

      talker.error(
          'Firebase Auth Exception: [${e.code}] ${e.message ?? "No message"} - Category: $category');

      return AuthException(
        code: e.code,
        message: message,
        category: category,
        originalException: e,
      );
    } else if (e is TimeoutException) {
      talker.error('Timeout Exception: ${e.message ?? "No message"}');

      return AuthException(
        code: 'timeout',
        message: 'The operation timed out. Please try again.',
        category: AuthErrorCategory.network,
        originalException: e,
      );
    } else {
      talker.error('Unknown Exception: ${e.toString()}');

      return AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred. Please try again.',
        category: AuthErrorCategory.unknown,
        originalException: e,
      );
    }
  }
}
