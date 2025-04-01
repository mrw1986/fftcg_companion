import 'dart:async';
import 'package:fftcg_companion/core/storage/hive_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:flutter/foundation.dart'; // Required for kReleaseMode
import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/merge_data_decision_dialog.dart';
import 'package:fftcg_companion/features/collection/data/repositories/collection_repository.dart';
import 'package:fftcg_companion/features/collection/data/repositories/collection_merge_helper.dart';
import 'package:fftcg_companion/features/profile/data/repositories/settings_merge_helper.dart';

/// Enum for categorizing authentication errors
enum AuthErrorCategory {
  authentication, // Wrong password, user not found, requires-recent-login, not-anonymous
  network, // Timeout, network request failed
  permission, // Operation not allowed, user disabled
  validation, // Invalid email, weak password, email-already-in-use
  conflict, // Credential already in use, provider already linked
  cancelled, // Sign in cancelled by user
  unknown, // Other errors
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
  String toString() => message; // User-facing message
}

/// Service for handling Firebase Authentication operations, rebuilt for simplicity.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;
  final Talker talker;
  final Duration _timeout = const Duration(seconds: 30);

  AuthService()
      : _auth = FirebaseAuth.instance,
        _googleSignIn = GoogleSignIn(),
        _userRepository = UserRepository(),
        talker = Talker();

  /// Get the current authenticated user.
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // --- Core Sign-in/Registration Methods ---

  /// Signs in a user anonymously. Creates a corresponding Firestore document.
  Future<UserCredential> signInAnonymously() async {
    talker.info('Attempting anonymous sign-in...');
    try {
      // Reset the last shown timestamp for account limits dialog
      // This ensures new anonymous users will see the dialog
      final storage = HiveStorage();
      final isBoxAvailable = await storage.isBoxAvailable('settings');
      if (isBoxAvailable) {
        await storage.put('last_limits_dialog_shown', 0, boxName: 'settings');
        talker.debug(
            'Reset account limits dialog timestamp for new anonymous user');
      }

      final userCredential = await _auth.signInAnonymously().timeout(_timeout);
      talker.info('Anonymous sign-in successful: ${userCredential.user?.uid}');
      if (userCredential.user != null) {
        // Reload the user to ensure we have the latest provider data
        await userCredential.user!.reload();
        // Get the refreshed user object
        final refreshedUser = _auth.currentUser;
        if (refreshedUser != null) {
          // Create user document AFTER successful sign-in and reload
          await _userRepository.createUserFromAuth(refreshedUser);
        }
      }
      return userCredential;
    } catch (e) {
      talker.error('Anonymous sign-in failed: $e');
      throw _handleAuthException(e);
    }
  }

  /// Signs in a user with email and password. Updates Firestore document on success.
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    talker.info('Attempting email/password sign-in for: $email');
    try {
      final userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(_timeout);
      talker.info(
          'Email/password sign-in successful: ${userCredential.user?.uid}');
      // Reload to ensure latest state (e.g., emailVerified) is fetched
      await userCredential.user?.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        // Create/update user document AFTER successful sign-in and reload
        await _userRepository.createUserFromAuth(refreshedUser);
      }
      // Return the original credential as it contains the user object
      return userCredential;
    } catch (e) {
      talker.error('Email/password sign-in failed: $e');
      throw _handleAuthException(e);
    }
  }

  /// Creates a new user with email and password, sends verification email, and creates Firestore document.
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    talker.info('Attempting to create email/password user for: $email');
    try {
      final userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(_timeout);
      talker.info(
          'Email/password user creation successful: ${userCredential.user?.uid}');

      // Send verification email (best effort)
      try {
        await userCredential.user?.sendEmailVerification().timeout(_timeout);
        talker.info('Verification email sent to: $email');
      } catch (verificationError) {
        talker.error(
            'Failed to send verification email (non-fatal): $verificationError');
        // Proceed even if email sending fails
      }

      if (userCredential.user != null) {
        // Create user document AFTER successful creation
        await _userRepository.createUserFromAuth(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      talker.error('Email/password user creation failed: $e');
      throw _handleAuthException(e);
    }
  }

  /// Signs in or registers a user with Google. Creates/updates Firestore document.
  Future<UserCredential> signInWithGoogle() async {
    talker.info('Attempting Google sign-in...');
    try {
      // Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        talker.info('Google sign-in cancelled by user.');
        throw AuthException(
            code: 'cancelled',
            message: 'Google sign-in was cancelled.',
            category: AuthErrorCategory.cancelled);
      }
      talker.debug('Google user obtained: ${googleUser.email}');

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      talker.debug('Google credential created.');

      // Sign in to Firebase with Google credential
      final userCredential =
          await _auth.signInWithCredential(credential).timeout(_timeout);
      talker.info(
          'Firebase sign-in with Google successful: ${userCredential.user?.uid}');

      // Reload to ensure latest state is fetched
      await userCredential.user?.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser != null) {
        // Create/update user document AFTER successful sign-in and reload
        await _userRepository.createUserFromAuth(refreshedUser);
      }
      return userCredential;
    } catch (e) {
      // Handle potential conflict where Google email matches existing Email/Password account
      if (e is FirebaseAuthException &&
          (e.code == 'account-exists-with-different-credential' ||
              e.code == 'email-already-in-use')) {
        talker.warning(
            'Google sign-in conflict: Email exists with different credential. $e');
        // Sign out from Google to allow potential linking later if needed
        await _googleSignIn.signOut();
        // Rethrow a specific error for the UI to handle (e.g., prompt user to sign in with email/pass first)
        throw AuthException(
          code: e.code, // Keep original code for potential UI logic
          message:
              'An account already exists with this email using a different sign-in method. Please sign in with your original method first.',
          category: AuthErrorCategory.conflict,
          originalException: e,
        );
      }
      talker.error('Google sign-in failed: $e');
      throw _handleAuthException(e);
    }
  }

  // --- Account Linking Methods ---

  /// Links Email/Password credentials to the currently signed-in anonymous user.
  Future<UserCredential> linkEmailAndPasswordToAnonymous(
      String email, String password) async {
    talker.info('Attempting to link Email/Password to anonymous user...');
    final currentUser = _auth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      talker.error('Link failed: No anonymous user is signed in.');
      throw AuthException(
          code: 'not-anonymous', // Specific code for this case
          message: 'No anonymous user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }

    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      final userCredential =
          await currentUser.linkWithCredential(credential).timeout(_timeout);
      talker.info(
          'Successfully linked Email/Password to anonymous user: ${userCredential.user?.uid}');

      // Send verification email (best effort)
      try {
        await userCredential.user?.sendEmailVerification().timeout(_timeout);
        talker.info('Verification email sent after linking: $email');
      } catch (verificationError) {
        talker.error(
            'Failed to send verification email after linking (non-fatal): $verificationError');
      }

      if (userCredential.user != null) {
        // Create/update user document AFTER successful linking
        await _userRepository.createUserFromAuth(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      // Handle case where email is already in use by another account
      if (e is FirebaseAuthException &&
          (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use')) {
        talker.warning('Link failed: Email/credential already in use. $e');
        // Suggest signing in directly
        throw AuthException(
          code: e.code, // Keep original code
          message:
              'This email is already associated with another account. Please sign in directly.',
          category: AuthErrorCategory.conflict,
          originalException: e,
        );
      }
      talker.error('Failed to link Email/Password to anonymous user: $e');
      throw _handleAuthException(e);
    }
  }

  /// Links Google credentials to the currently signed-in anonymous user.
  Future<UserCredential> linkGoogleToAnonymous(BuildContext context) async {
    talker.info('Attempting to link Google to anonymous user...');
    final currentUser = _auth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) {
      talker.error('Link failed: No anonymous user is signed in.');
      throw AuthException(
          code: 'not-anonymous', // Specific code for this case
          message: 'No anonymous user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }

    try {
      // Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        talker.info('Google sign-in cancelled during linking.');
        throw AuthException(
            code: 'cancelled',
            message: 'Google sign-in was cancelled.',
            category: AuthErrorCategory.cancelled);
      }
      talker.debug('Google user obtained for linking: ${googleUser.email}');

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      talker.debug('Google credential created for linking.');

      // Try linking credential
      UserCredential userCredential;
      try {
        userCredential =
            await currentUser.linkWithCredential(credential).timeout(_timeout);
        // Use the NEW user ID from the credential after successful link
        talker.info(
            'Successfully linked Google to anonymous user. New UID: ${userCredential.user?.uid}');

        // Reload user to ensure we have latest provider data
        if (userCredential.user != null) {
          await userCredential.user!.reload();

          // Sign out and sign back in to ensure clean state
          try {
            talker.debug(
                'Signing out and back in to ensure clean state after Google linking');
            final googleCredential = GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );
            talker.info('Current auth state before sign out: '
                'isAnonymous=${_auth.currentUser?.isAnonymous}, '
                'providers=${_auth.currentUser?.providerData.map((p) => p.providerId).join(", ")}');

            // Sign out from both services with delay
            await _googleSignIn.signOut();
            talker.debug('Signed out from Google.');
            await Future.delayed(const Duration(milliseconds: 500));

            await _auth.signOut();
            talker.info('Signed out from Firebase.');
            await Future.delayed(const Duration(milliseconds: 500));

            // Sign back in with Google
            userCredential = await _auth
                .signInWithCredential(googleCredential)
                .timeout(_timeout);
            talker.info(
                'Successfully signed back in with Google after linking. '
                'New auth state: isAnonymous=${userCredential.user?.isAnonymous}, '
                'providers=${userCredential.user?.providerData.map((p) => p.providerId).join(", ")}');

            // Reload one more time to ensure we have the latest state
            await userCredential.user?.reload();
            final finalUser = _auth.currentUser;
            if (finalUser != null) {
              // ** ADDED DEBUG LOG **
              talker.debug(
                  'Attempting Firestore write with UID: ${finalUser.uid}');
              // Create/update user document HERE, after state is settled
              await _userRepository.createUserFromAuth(finalUser);
              talker.info(
                  'Final user state after Google linking: isAnonymous=${finalUser.isAnonymous}, providers=${finalUser.providerData.map((p) => p.providerId).join(", ")}');
            }
          } catch (signInError) {
            talker.error('Error during sign out/sign in after Google linking',
                signInError);
            throw _handleAuthException(signInError);
          }
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          talker.warning(
              'Credential already in use. Attempting sign-in instead.');
          // Store the anonymous user's ID and data before signing in
          final anonymousUserId = currentUser.uid;

          final signedInCredential =
              await _auth.signInWithCredential(credential).timeout(_timeout);
          talker.info(
              'Signed in with Google instead of linking: ${signedInCredential.user?.uid}');
          userCredential = signedInCredential;

          // Then prompt user to merge data
          if (context.mounted) {
            final mergeAction = await showMergeDataDecisionDialog(context);
            if (mergeAction != null) {
              final collectionRepo = CollectionRepository();
              final userRepo = UserRepository();

              try {
                switch (mergeAction) {
                  case MergeAction.discard:
                    talker.debug('Discarding anonymous user data');
                    break;
                  case MergeAction.merge:
                    talker.debug('Merging anonymous user data');
                    await migrateCollectionData(
                      collectionRepository: collectionRepo,
                      fromUserId: anonymousUserId,
                      toUserId: userCredential.user!.uid,
                    );
                    await migrateUserSettings(
                      userRepository: userRepo,
                      fromUserId: anonymousUserId,
                      toUserId: userCredential.user!.uid,
                      overwrite: false,
                    );
                    break;
                  case MergeAction.overwrite:
                    talker.debug('Overwriting with anonymous user data');
                    await migrateCollectionData(
                      collectionRepository: collectionRepo,
                      fromUserId: anonymousUserId,
                      toUserId: userCredential.user!.uid,
                    );
                    await migrateUserSettings(
                      userRepository: userRepo,
                      fromUserId: anonymousUserId,
                      toUserId: userCredential.user!.uid,
                      overwrite: true,
                    );
                    break;
                }
              } catch (e) {
                talker.error('Error during data migration: $e');
                // Continue with sign-in process even if migration fails
              }
            }
          }

          // Now reload user and sign out/sign back in to ensure clean state
          if (userCredential.user != null) {
            await userCredential.user!.reload();

            try {
              talker.debug(
                  'Signing out and back in to ensure clean state after Google sign-in');
              final googleCredential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              // Sign out from both services with delay
              await _googleSignIn.signOut();
              talker.debug('Signed out from Google.');
              await Future.delayed(const Duration(milliseconds: 500));

              await _auth.signOut();
              talker.info('Signed out from Firebase.');
              await Future.delayed(const Duration(milliseconds: 500));

              // Sign back in with Google
              userCredential = await _auth
                  .signInWithCredential(googleCredential)
                  .timeout(_timeout);
              talker.info(
                  'Successfully signed back in with Google after sign-in');

              // Reload one more time to ensure we have the latest state
              await userCredential.user?.reload();
              final finalUser = _auth.currentUser;
              if (finalUser != null) {
                // ** ADDED DEBUG LOG **
                talker.debug(
                    'Attempting Firestore write with UID: ${finalUser.uid}');
                // Create/update user document HERE, after state is settled
                await _userRepository.createUserFromAuth(finalUser);
                talker.info(
                    'Final user state after Google sign-in: isAnonymous=${finalUser.isAnonymous}, providers=${finalUser.providerData.map((p) => p.providerId).join(", ")}');
              }
            } catch (signInError) {
              talker.error('Error during sign out/sign in after Google sign-in',
                  signInError);
              throw _handleAuthException(signInError);
            }
          }
        } else {
          rethrow;
        }
      }

      return userCredential;
    } catch (e) {
      // Handle specific conflict: Anonymous user tries to link Google, but Google email belongs to existing Email/Password account
      if (e is FirebaseAuthException &&
          (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use')) {
        talker.warning(
            'Link failed: Google email already associated with another account (likely Email/Password). $e');
        // Throw a specific error code for the UI to handle
        throw AuthException(
          code:
              'account-exists-with-different-credential', // Use this specific code
          message:
              'An account already exists with this email using Email/Password. Please sign in with Email/Password first, then link Google in settings.',
          category: AuthErrorCategory.conflict,
          originalException: e,
        );
      }
      // Handle other linking errors
      talker.error('Failed to link Google to anonymous user: $e');
      throw _handleAuthException(e); // Handle other errors generically
    }
  }

  /// Links Email/Password credentials to an existing Google-authenticated user.
  Future<UserCredential> linkEmailPasswordToGoogle(
      String email, String password) async {
    talker.info('Attempting to link Email/Password to Google user...');
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      talker.error(
          'Link failed: No authenticated (non-anonymous) user is signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No authenticated user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }
    if (!currentUser.providerData
        .any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID)) {
      talker.error('Link failed: Current user is not signed in with Google.');
      throw AuthException(
          code: 'not-google-user',
          message: 'Current user is not signed in with Google.',
          category: AuthErrorCategory.authentication);
    }

    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      final userCredential =
          await currentUser.linkWithCredential(credential).timeout(_timeout);
      talker.info(
          'Successfully linked Email/Password to Google user: ${userCredential.user?.uid}');

      // Send verification email (best effort)
      try {
        await userCredential.user?.sendEmailVerification().timeout(_timeout);
        talker.info('Verification email sent after linking to Google: $email');
      } catch (verificationError) {
        talker.error(
            'Failed to send verification email after linking to Google (non-fatal): $verificationError');
      }

      if (userCredential.user != null) {
        // Create/update user document AFTER successful linking
        await _userRepository.createUserFromAuth(userCredential.user!);
      }
      return userCredential;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'provider-already-linked') {
          talker.warning(
              'Link failed: Email/Password provider already linked. $e');
          throw AuthException(
              code: e.code,
              message: 'Email/Password is already linked to this account.',
              category: AuthErrorCategory.conflict,
              originalException: e);
        } else if (e.code == 'email-already-in-use' ||
            e.code == 'credential-already-in-use') {
          talker.warning(
              'Link failed: Email/credential already in use by another account. $e');
          throw AuthException(
              code: e.code,
              message: 'This email is already associated with another account.',
              category: AuthErrorCategory.conflict,
              originalException: e);
        }
      }
      talker.error('Failed to link Email/Password to Google user: $e');
      throw _handleAuthException(e);
    }
  }

  /// Links Google credentials to an existing Email/Password-authenticated user.
  Future<UserCredential> linkGoogleToEmailPassword() async {
    talker.info('Attempting to link Google to Email/Password user...');
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.isAnonymous) {
      talker.error(
          'Link failed: No authenticated (non-anonymous) user is signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No authenticated user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }
    if (!currentUser.providerData
        .any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID)) {
      talker.error(
          'Link failed: Current user is not signed in with Email/Password.');
      throw AuthException(
          code: 'not-email-user',
          message: 'Current user is not signed in with Email/Password.',
          category: AuthErrorCategory.authentication);
    }

    try {
      // Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        talker.info('Google sign-in cancelled during linking.');
        throw AuthException(
            code: 'cancelled',
            message: 'Google sign-in was cancelled.',
            category: AuthErrorCategory.cancelled);
      }
      talker.debug('Google user obtained for linking: ${googleUser.email}');

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      talker.debug('Google credential created for linking.');

      // Link credential
      final userCredential =
          await currentUser.linkWithCredential(credential).timeout(_timeout);
      // Use the NEW user ID from the credential after successful link
      talker.info(
          'Successfully linked Google to Email/Password user: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        // Reload the user to ensure we have the latest provider data
        await userCredential.user!.reload();
        // Get the refreshed user object
        final refreshedUser = _auth.currentUser;
        if (refreshedUser != null) {
          // Create/update user document AFTER successful linking and reload
          await _userRepository.createUserFromAuth(refreshedUser);
        }
      }
      return userCredential;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'provider-already-linked') {
          talker.warning('Link failed: Google provider already linked. $e');
          throw AuthException(
              code: e.code,
              message: 'Google is already linked to this account.',
              category: AuthErrorCategory.conflict,
              originalException: e);
        } else if (e.code == 'credential-already-in-use') {
          talker.warning(
              'Link failed: Google credential already in use by another account. $e');
          throw AuthException(
              code: e.code,
              message:
                  'This Google account is already associated with another user.',
              category: AuthErrorCategory.conflict,
              originalException: e);
        }
      }
      talker.error('Failed to link Google to Email/Password user: $e');
      throw _handleAuthException(e);
    }
  }

  // --- Account Management Methods ---

  /// Sends a password reset email to the specified email address.
  Future<void> sendPasswordResetEmail(String email) async {
    talker.info('Sending password reset email to: $email');
    try {
      await _auth.sendPasswordResetEmail(email: email).timeout(_timeout);
      talker.info('Password reset email sent successfully.');
    } catch (e) {
      talker.error('Failed to send password reset email: $e');
      throw _handleAuthException(e);
    }
  }

  /// Sends a verification link to the user's current email to allow updating it.
  /// Also updates the email in Firestore upon successful verification by Firebase Auth.
  Future<void> verifyBeforeUpdateEmail(String newEmail) async {
    talker
        .info('Attempting to send verification for email update to: $newEmail');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Email update failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }

    try {
      await currentUser.verifyBeforeUpdateEmail(newEmail).timeout(_timeout);
      talker.info('Verification email sent for email update.');

      // Note: Firebase handles the actual email update after the user clicks the link.
      // Firestore will be updated automatically when the auth state changes reflect the new email.
      // No need for optimistic update here.
    } catch (e) {
      talker.error('Failed to send verification for email update: $e');
      throw _handleAuthException(e);
    }
  }

  /// Updates the current user's password. Requires recent login.
  Future<void> updatePassword(String newPassword) async {
    talker.info('Attempting to update password...');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Password update failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }

    try {
      await currentUser.updatePassword(newPassword);
      talker.info('Password updated successfully.');
    } catch (e) {
      talker.error('Failed to update password: $e');
      throw _handleAuthException(e);
    }
  }

  /// Signs out the current user from Firebase and Google (if applicable).
  Future<void> signOut() async {
    talker.info('Attempting sign out...');
    try {
      // Check which providers are linked to sign out appropriately
      final providers =
          _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
              [];

      // Always sign out from Google first if it's a provider
      if (providers.contains(GoogleAuthProvider.PROVIDER_ID)) {
        await _googleSignIn.signOut();
        talker.debug('Signed out from Google.');
        // Add a small delay to ensure Google sign out completes
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Reset the last shown timestamp for account limits dialog
      // This ensures new anonymous users will see the dialog
      final storage = HiveStorage();
      final isBoxAvailable = await storage.isBoxAvailable('settings');
      if (isBoxAvailable) {
        await storage.put('last_limits_dialog_shown', 0, boxName: 'settings');
        talker.debug('Reset account limits dialog timestamp');
      }

      // Then sign out from Firebase
      await _auth.signOut();
      talker.info('Signed out from Firebase.');

      // Add a small delay to ensure auth state updates properly
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      talker.error('Sign out failed: $e');
      throw _handleAuthException(e);
    }
  }

  /// Deletes the current user's account from Firebase Auth and Firestore. Requires recent login.
  Future<void> deleteUser() async {
    talker.warning('Attempting to delete user account...');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Account deletion failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }
    final userId = currentUser.uid;

    try {
      // Delete Firestore data first
      await _userRepository.deleteUser(userId);
      talker.debug('Firestore data deleted for user: $userId');

      // Delete Firebase Auth user
      await currentUser.delete();
      talker.warning('Firebase Auth user deleted: $userId');
    } catch (e) {
      talker.error('Account deletion failed: $e');
      throw _handleAuthException(e);
    }
  }

  // --- Re-authentication Methods ---

  /// Re-authenticates the current user with their email and password.
  Future<UserCredential> reauthenticateWithEmailAndPassword(
      String email, String password) async {
    talker.info('Attempting Email/Password re-authentication...');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Re-authentication failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }

    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      final userCredential = await currentUser
          .reauthenticateWithCredential(credential)
          .timeout(_timeout);
      talker.info('Email/Password re-authentication successful.');
      return userCredential;
    } catch (e) {
      talker.error('Email/Password re-authentication failed: $e');
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticates the current user with Google.
  /// Uses a sign-out/sign-in approach for simplicity and robustness against token issues.
  Future<UserCredential> reauthenticateWithGoogle() async {
    talker.info(
        'Attempting Google re-authentication (sign-out/sign-in approach)...');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Re-authentication failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }
    final originalEmail =
        currentUser.email; // Store original email for verification

    try {
      // Sign out from Google first to force a fresh login prompt
      await _googleSignIn.signOut();
      talker.debug('Signed out from Google for re-authentication.');

      // Start Google sign-in flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        talker.info('Google sign-in cancelled during re-authentication.');
        throw AuthException(
            code: 'cancelled',
            message: 'Google sign-in was cancelled.',
            category: AuthErrorCategory.cancelled);
      }
      talker.debug(
          'Google user obtained for re-authentication: ${googleUser.email}');

      // Verify it's the same Google account
      if (googleUser.email != originalEmail) {
        talker.warning(
            'Re-authentication failed: Different Google account used.');
        // Sign the user out completely as they used the wrong account
        await signOut();
        throw AuthException(
            code: 'wrong-account',
            message:
                'Please use the same Google account you originally signed in with.',
            category: AuthErrorCategory.authentication);
      }

      // Obtain Google auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      talker.debug('Google credential created for re-authentication.');

      // Re-authenticate with Firebase
      final userCredential = await currentUser
          .reauthenticateWithCredential(credential)
          .timeout(_timeout);
      talker.info('Google re-authentication successful.');
      return userCredential;
    } catch (e) {
      talker.error('Google re-authentication failed: $e');
      // If re-auth fails, sign the user out for security
      await signOut().catchError((signOutError) {
        talker.error(
            'Error signing out after failed re-authentication: $signOutError');
      });
      throw _handleAuthException(e);
    }
  }

  // --- Email Verification Status ---

  /// Sends an email verification link to the current user.
  Future<void> sendEmailVerification() async {
    talker.info('Attempting to send email verification...');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Send verification failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }
    if (currentUser.emailVerified) {
      talker.info('Email already verified.');
      return; // Don't send if already verified
    }

    try {
      await currentUser.sendEmailVerification().timeout(_timeout);
      talker.info('Email verification sent successfully.');
    } catch (e) {
      talker.error('Failed to send email verification: $e');
      throw _handleAuthException(e);
    }
  }

  /// Checks if the current user's email is verified. Reloads user data first.
  Future<bool> isEmailVerified() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    try {
      await currentUser.reload();
      // Need to get the user again after reload
      final refreshedUser = _auth.currentUser;
      final verified = refreshedUser?.emailVerified ?? false;
      talker.debug('Email verification status: $verified');
      return verified;
    } catch (e) {
      talker.error('Failed to check email verification status: $e');
      // Assume not verified if reload fails
      return false;
    }
  }

  /// Checks if the current user is anonymous.
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  /// Unlink a provider (e.g., 'google.com', 'password') from the current user.
  Future<User?> unlinkProvider(String providerId) async {
    talker.info('Attempting to unlink provider: $providerId');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Unlink failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }
    // Prevent unlinking the last provider if it's not anonymous
    if (currentUser.providerData.length == 1 && !currentUser.isAnonymous) {
      // Corrected check
      talker.error(
          'Unlink failed: Cannot unlink the last sign-in method for a non-anonymous account.');
      throw AuthException(
          code: 'cannot-unlink-last-provider',
          message: 'You cannot remove your only sign-in method.',
          category: AuthErrorCategory.permission);
    }

    try {
      await currentUser.unlink(providerId).timeout(_timeout);
      talker.info('Successfully unlinked provider: $providerId');

      // Reload the user data to get the updated provider list
      await currentUser.reload();
      final reloadedUser = _auth.currentUser; // Get the refreshed user object

      // Update Firestore user data with the reloaded user
      if (reloadedUser != null) {
        // Create/update user document AFTER successful unlink and reload
        await _userRepository.createUserFromAuth(reloadedUser);
      } else {
        // This case should ideally not happen if unlink succeeded, but handle defensively
        talker.warning('User object was null after reload post-unlink.');
      }
      return reloadedUser; // Return the reloaded user object
    } catch (e) {
      talker.error('Failed to unlink provider $providerId: $e');
      throw _handleAuthException(e);
    }
  }

  /// Update user profile (displayName, photoURL).
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    talker.info('Attempting to update profile...');
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      talker.error('Profile update failed: No user signed in.');
      throw AuthException(
          code: 'not-authenticated',
          message: 'No user is currently signed in.',
          category: AuthErrorCategory.authentication);
    }

    try {
      if (displayName != null) {
        await currentUser.updateDisplayName(displayName);
        talker.debug('Display name updated.');
      }
      if (photoURL != null) {
        await currentUser.updatePhotoURL(photoURL);
        talker.debug('Photo URL updated.');
      }

      // Update Firestore user data using the specific profile update method
      await _userRepository.updateUserProfileData(
        currentUser.uid,
        displayName: displayName,
        photoURL: photoURL,
      );
      talker.info('Profile updated successfully (Auth & Firestore).');
    } catch (e) {
      talker.error('Failed to update profile: $e');
      throw _handleAuthException(e);
    }
  }

  /// Called when email verification is likely complete (e.g., after user returns to app).
  /// Reloads the user and updates Firestore if verified.
  Future<void> handleEmailVerificationComplete() async {
    talker.info('Handling potential email verification completion...');
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.emailVerified) {
      talker.debug(
          'No user or email already verified, skipping Firestore update.');
      return; // No action needed if no user or already verified
    }

    try {
      await currentUser.reload();
      final refreshedUser = _auth.currentUser; // Get user again after reload
      if (refreshedUser != null && refreshedUser.emailVerified) {
        talker.info(
            'Email verification confirmed for user: ${refreshedUser.uid}');
        // Update Firestore to reflect verified status
        await _userRepository.createUserFromAuth(refreshedUser);
        talker.debug('Firestore updated with verified status.');
      } else {
        talker.debug('Email still not verified after reload.');
      }
    } catch (e) {
      talker.error('Error during email verification handling: $e');
      // Don't throw, as this is often called passively
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

      final isOlder = difference.inDays > days;
      talker.debug(
          'Account age check: ${difference.inDays} days old. Older than $days days? $isOlder');
      return isOlder;
    } catch (e) {
      talker.error('Error checking account age: $e');
      return false; // Default to false on error
    }
  }

  // --- Error Handling ---

  /// Handles various exceptions and converts them into a structured AuthException.
  AuthException _handleAuthException(dynamic e) {
    talker.error('Handling Auth Exception: ${e.runtimeType} - $e');

    if (e is AuthException) {
      // If it's already an AuthException, just return it
      return e;
    }

    if (e is FirebaseAuthException) {
      final category = _categorizeFirebaseError(e.code);
      final message =
          getReadableAuthError(e.code, e.message); // Use public method
      talker.debug(
          'FirebaseAuthException: Code=${e.code}, Msg=${e.message}, Category=$category');
      return AuthException(
          code: e.code,
          message: message,
          category: category,
          originalException: e);
    }

    if (e is TimeoutException) {
      talker.debug('TimeoutException');
      return AuthException(
          code: 'timeout',
          message:
              'The operation timed out. Please check your connection and try again.',
          category: AuthErrorCategory.network,
          originalException: e);
    }

    // Handle potential GoogleSignIn errors (though most should bubble up as FirebaseAuthExceptions)
    // Example: PlatformException from GoogleSignIn
    if (e.toString().contains('PlatformException')) {
      // Basic check
      talker.debug('Potential PlatformException (possibly GoogleSignIn): $e');
      // Treat as network or unknown, depending on details if available
      return AuthException(
          code: 'platform-error',
          message: 'An external sign-in error occurred. Please try again.',
          category: AuthErrorCategory.network, // Or unknown
          originalException: e);
    }

    talker.debug('Unknown error type: ${e.runtimeType}');
    return AuthException(
        code: 'unknown',
        message: 'An unexpected error occurred. Please try again.',
        category: AuthErrorCategory.unknown,
        originalException: e);
  }

  /// Categorizes FirebaseAuthException codes into AuthErrorCategory.
  AuthErrorCategory _categorizeFirebaseError(String code) {
    switch (code) {
      // Authentication Issues
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Can be auth or validation
      case 'user-mismatch':
      case 'requires-recent-login':
      case 'invalid-user-token':
      case 'user-token-expired':
      case 'web-context-cancelled':
      case 'wrong-account': // Custom code added in reauth
      case 'not-anonymous': // Added custom code
      case 'not-authenticated': // Added custom code
      case 'not-google-user': // Added custom code
      case 'not-email-user': // Added custom code
        return AuthErrorCategory.authentication;

      // Network Issues
      case 'network-request-failed':
      case 'timeout': // Firebase might use this code too
      case 'web-network-request-failed':
      case 'app-not-authorized': // Can indicate network/config issues
        return AuthErrorCategory.network;

      // Permission Issues
      case 'operation-not-allowed':
      case 'user-disabled':
      case 'web-context-unsupported':
      case 'cannot-unlink-last-provider': // Added custom code
        return AuthErrorCategory.permission;

      // Validation Issues
      case 'invalid-email':
      case 'weak-password':
      case 'missing-password':
      case 'missing-email':
        return AuthErrorCategory.validation;

      // Conflict Issues
      case 'email-already-in-use':
      case 'credential-already-in-use':
      case 'account-exists-with-different-credential':
      case 'provider-already-linked':
        return AuthErrorCategory.conflict;

      // Cancellation
      case 'cancelled': // Custom code
      case 'sign-in-cancelled': // Custom code
        return AuthErrorCategory.cancelled;

      // Other/Unknown
      case 'too-many-requests': // Could be auth/network/permission
      case 'internal-error':
      case 'invalid-api-key':
      case 'app-deleted':
      case 'invalid-app-credential':
      case 'invalid-verification-code':
      case 'invalid-verification-id':
      case 'captcha-check-failed':
      case 'web-storage-unsupported':
      default:
        return AuthErrorCategory.unknown;
    }
  }

  /// Provides user-friendly error messages based on the error code.
  /// Excludes error codes from the final message for better UX.
  String getReadableAuthError(String code, String? originalMessage) {
    // Determine the user-friendly message based on the code
    switch (code) {
      // Authentication
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Group these common sign-in errors
        return 'Incorrect email or password. Please try again.';
      case 'requires-recent-login':
        return 'For security, please sign in again to continue.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-mismatch':
      case 'invalid-user-token':
      case 'user-token-expired':
        return 'Your session has expired. Please sign in again.';
      case 'wrong-account': // Custom code
        return 'Please use the same account you originally signed in with.';
      case 'not-anonymous': // Custom code
      case 'not-authenticated': // Custom code
      case 'not-google-user': // Custom code
      case 'not-email-user': // Custom code
        // These are internal logic errors, show a generic message to the user
        return 'An unexpected authentication error occurred. Please try again.';

      // Validation
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger one.';
      case 'missing-password':
      case 'missing-email':
        return 'Please enter both email and password.';

      // Conflict
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        // Provide specific guidance based on the context where this error is handled (sign-in vs linking)
        // The AuthService methods throw more specific AuthExceptions for these cases now.
        // This generic message serves as a fallback if the specific exception isn't caught.
        return 'An account already exists with this email using a different sign-in method.';
      case 'credential-already-in-use':
        return 'This sign-in method is already associated with another account.';
      case 'provider-already-linked':
        return 'This sign-in method is already linked to your account.';

      // Network & Other
      case 'network-request-failed':
      case 'timeout':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not currently allowed. Please contact support.';
      case 'cancelled':
      case 'sign-in-cancelled':
        return 'Sign-in process was cancelled.';
      case 'cannot-unlink-last-provider': // Added custom code
        return 'You cannot remove your only sign-in method.';

      // Default for unhandled codes
      default:
        // In release mode, show a generic message. In debug, include the original message if available.
        return kReleaseMode
            ? 'An unexpected error occurred. Please try again.'
            : 'An unexpected error occurred. ${originalMessage ?? ""}';
    }
  }
}
