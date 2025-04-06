import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart'; // Import UserRepository
import 'package:fftcg_companion/core/utils/logger.dart';
// Import for deep equality check

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for the current user stream from Firebase Auth
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  talker.debug('Setting up Firebase Auth user stream');
  return authService.authStateChanges;
});

/// Provider that ensures the Firestore user document is synced with the auth state.
/// This provider listens to the Firebase user stream and triggers Firestore updates.
/// It also resets the emailVerificationDetectedProvider flag when appropriate.
final firestoreUserSyncProvider = Provider<void>((ref) {
  // Use the raw Firebase user stream provider here
  ref.listen<AsyncValue<User?>>(firebaseUserProvider, (previous, next) async {
    final previousUser = previous?.valueOrNull; // Safely get previous user
    final nextUser = next.valueOrNull; // Safely get next user

    // --- Logic to reset emailVerificationDetectedProvider ---
    bool shouldResetVerificationFlag = false;
    if (previousUser != null && nextUser == null) {
      // User signed out
      shouldResetVerificationFlag = true;
      talker.debug(
          'firestoreUserSyncProvider: User signed out, scheduling verification flag reset.');
    } else if (nextUser != null && nextUser.emailVerified) {
      // User exists and is verified (covers initial load and verification changes)
      shouldResetVerificationFlag = true;
      talker.debug(
          'firestoreUserSyncProvider: User is verified, scheduling verification flag reset.');
    } else if (nextUser != null && nextUser.isAnonymous) {
      // User is anonymous
      shouldResetVerificationFlag = true;
      talker.debug(
          'firestoreUserSyncProvider: User is anonymous, scheduling verification flag reset.');
    } else if (next is AsyncError) {
      // Error occurred
      shouldResetVerificationFlag = true;
      talker.debug(
          'firestoreUserSyncProvider: Auth stream error, scheduling verification flag reset.');
    }

    if (shouldResetVerificationFlag) {
      // Check current state before setting to avoid unnecessary rebuilds
      if (ref.read(emailVerificationDetectedProvider)) {
        talker.debug(
            'firestoreUserSyncProvider: Resetting emailVerificationDetectedProvider to false.');
        // Use read().notifier.state as we are in a callback
        ref.read(emailVerificationDetectedProvider.notifier).state = false;
      }
    }
    // --- End of reset logic ---

    // --- Logic to sync Firestore document ---
    if (nextUser != null) {
      // Determine if a sync is needed based on relevant user data changes
      bool shouldSync = previousUser ==
              null || // Always sync if it's the first non-null user
          previousUser.uid !=
              nextUser.uid || // Should not happen, but safe check
          previousUser.email != nextUser.email ||
          previousUser.displayName != nextUser.displayName ||
          previousUser.photoURL != nextUser.photoURL ||
          previousUser.emailVerified !=
              nextUser.emailVerified; // Sync when verification status changes

      if (shouldSync) {
        talker.debug(
            'FirestoreUserSync: Detected relevant user change: ${nextUser.uid}, Email: ${nextUser.email}, Verified: ${nextUser.emailVerified}');
        try {
          final userRepository =
              ref.read(userRepositoryProvider); // Read the new provider
          await userRepository.createUserFromAuth(nextUser);
          talker.debug(
              'FirestoreUserSync: Successfully synced user ${nextUser.uid} to Firestore.');
          // Verify and correct collection count after ensuring user doc exists
          await userRepository.verifyAndCorrectCollectionCount(nextUser.uid);
        } catch (e, s) {
          talker.error(
              'FirestoreUserSync: Error syncing user ${nextUser.uid} to Firestore',
              e,
              s);
          // Decide if error needs propagation or just logging
        }
      } else {
        talker.debug(
            'FirestoreUserSync: User stream emitted, but no relevant data changed for UID: ${nextUser.uid}. Skipping Firestore sync.');
      }
    } else if (previousUser != null && nextUser == null) {
      talker.debug('FirestoreUserSync: Detected user signed out.');
      // Firestore cleanup is handled by Firebase Extension or specific delete logic
    } else if (next is AsyncError) {
      talker.error('FirestoreUserSync: Error in user stream', next.error,
          next.stackTrace);
    }
    // --- End of Firestore sync logic ---
  });
});

/// Provider for UserRepository (needed by firestoreUserSyncProvider)
final userRepositoryProvider = Provider<UserRepository>((ref) {
  // Assuming UserRepository has a default constructor
  return UserRepository();
});

/// Provider for the current user (derived from the Firebase stream)
final currentUserProvider = Provider<User?>((ref) {
  // Watch the raw Firebase user stream
  return ref.watch(firebaseUserProvider).when(
        data: (user) => user,
        loading: () => null, // Or return previous user if needed during loading
        error: (e, s) {
          talker.error('Error fetching current user', e, s);
          return null; // No user available on error
        },
      );
});

/// Force refresh auth provider to trigger auth state refresh
final forceRefreshAuthProvider = StateProvider<bool>((ref) => false);

/// Provider that watches and resets the forceRefreshAuthProvider
/// This allows us to avoid modifying the provider during initialization
final forceRefreshHandlerProvider = Provider<void>((ref) {
  // Watch the force refresh provider
  final shouldRefresh = ref.watch(forceRefreshAuthProvider);

  // If the flag is true, schedule a reset after this frame completes
  if (shouldRefresh) {
    // Use Future.microtask to reset the flag after the current execution frame
    Future.microtask(() {
      try {
        ref.read(forceRefreshAuthProvider.notifier).state = false;
        talker.debug('Force auth refresh flag reset');
      } catch (e) {
        // Log error if the provider is no longer available
        talker.error('Error resetting force refresh flag: $e');
      }
    });
  }
});

// Removed the problematic authStateListenerProvider

/// Provider for the authentication state (derived from the Firebase stream)
final authStateProvider = Provider<AuthState>((ref) {
  // Ensure the sync provider is active by watching it. This also handles the verification flag reset now.
  ref.watch(firestoreUserSyncProvider);

  // Watch the force refresh flag but DON'T modify it here
  // Simply watch it to rebuild when it changes
  ref.watch(forceRefreshAuthProvider);

  // Watch the forceRefreshHandlerProvider to ensure it's activated
  ref.watch(forceRefreshHandlerProvider);

  // Watch the raw Firebase user stream
  final userAsync = ref.watch(firebaseUserProvider);

  return userAsync.when(
    data: (user) {
      talker.debug('Auth state updated:');
      talker.debug('User: ${user?.email}');
      talker.debug('Is anonymous: ${user?.isAnonymous}');
      talker.debug('Is email verified: ${user?.emailVerified}');
      if (user == null) {
        talker.debug('Auth state: unauthenticated');
        // Resetting is handled by firestoreUserSyncProvider listener
        return const AuthState.unauthenticated();
      }

      // First check if the user is anonymous
      if (user.isAnonymous) {
        // Even if there are providers, if isAnonymous is true, treat as anonymous
        talker.debug('Auth state: anonymous');
        // Resetting is handled by firestoreUserSyncProvider listener
        return AuthState.anonymous(user);
      } else {
        // User is not anonymous, check providers
        // Check for providers
        bool hasPasswordProvider = user.providerData
            .any((userInfo) => userInfo.providerId == 'password');
        bool hasGoogleProvider = user.providerData
            .any((userInfo) => userInfo.providerId == 'google.com');

        // If user has an unverified email/password but also has Google,
        // keep them authenticated but set emailNotVerified flag
        if (hasPasswordProvider && !user.emailVerified) {
          if (hasGoogleProvider) {
            // User has Google auth, so keep them authenticated but mark email as unverified
            talker.debug('Auth state: authenticated (with unverified email)');
            // Don't reset the flag here, let the checker manage it
            return AuthState.authenticated(user);
          } else {
            // Only has unverified email/password, show unverified state
            talker.debug('Auth state: email not verified');
            // Don't reset the flag here, let the checker manage it
            return AuthState.emailNotVerified(user);
          }
        }

        // User either has no email/password or it's verified
        talker.debug('Auth state: authenticated');
        // Resetting is handled by firestoreUserSyncProvider listener
        return AuthState.authenticated(user);
      }
    },
    loading: () {
      talker.debug('Auth state: loading');
      return const AuthState.loading();
    },
    error: (error, stackTrace) {
      talker.error('Auth state error', error, stackTrace);
      // Resetting is handled by firestoreUserSyncProvider listener
      return AuthState.error(error.toString());
    },
  );
});

/// NEW: StateProvider to signal immediate verification detection by the checker.
/// This helps bridge the gap until the main authStateProvider updates via the stream.
final emailVerificationDetectedProvider = StateProvider<bool>((ref) => false);

/// Authentication state class
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  // This flag now primarily indicates if the user object itself reports
  // emailVerified as false, useful for UI hints, but the main state logic
  // is handled in the authStateProvider above.
  final bool emailNotVerified;

  const AuthState({
    required this.status,
    this.user,
    this.emailNotVerified = false,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        emailNotVerified = false,
        user = null,
        errorMessage = null;

  const AuthState.anonymous([this.user])
      : status = AuthStatus.anonymous,
        emailNotVerified = false,
        errorMessage = null;

  // Removed const keyword as initializers are not constant
  AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        // Always check for unverified email/password, even in authenticated state
        emailNotVerified =
            user?.providerData.any((p) => p.providerId == 'password') == true &&
                !(user?.emailVerified ?? true),
        errorMessage = null;

  AuthState.emailNotVerified(this.user)
      : status = AuthStatus.emailNotVerified,
        // Always true for unverified state since we know it has unverified email
        emailNotVerified = true,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        emailNotVerified = false,
        errorMessage = null;

  const AuthState.error(this.errorMessage)
      : status = AuthStatus.error,
        user = null,
        emailNotVerified = false;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  // Use this getter to check the specific state if needed
  bool get isEmailNotVerifiedState => status == AuthStatus.emailNotVerified;
  // Keep the original getter name for compatibility, but its meaning is now
  // tied to the user object's status, not the overall AuthState status.
  bool get isEmailNotVerified => emailNotVerified;
  bool get isAnonymous => status == AuthStatus.anonymous;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

/// Authentication status enum
enum AuthStatus {
  unauthenticated,
  anonymous,
  emailNotVerified, // Represents state where ONLY unverified email/pass exists
  authenticated,
  loading,
  error,
}

/// Provider for handling user account deletion
final deleteUserProvider = FutureProvider.autoDispose<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.deleteUser();
});

/// Provider for re-authenticating a user with email and password
final reauthWithEmailProvider =
    FutureProvider.autoDispose.family<UserCredential, EmailPasswordCredentials>(
  (ref, credentials) async {
    final authService = ref.watch(authServiceProvider);
    return await authService.reauthenticateWithEmailAndPassword(
      credentials.email,
      credentials.password,
    );
  },
);

/// Provider for re-authenticating a user with Google
final reauthWithGoogleProvider = FutureProvider.autoDispose<UserCredential>(
  (ref) async {
    final authService = ref.watch(authServiceProvider);
    return await authService.reauthenticateWithGoogle();
  },
);

/// Provider for unlinking an authentication provider
// Changed return type to void as the primary goal is the side effect
final unlinkProviderProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, providerId) async {
    final authService = ref.watch(authServiceProvider);
    // Call the service method but don't need to return the User? object
    await authService.unlinkProvider(providerId);
    // Invalidate both the source stream and the derived state
    // to ensure the UI updates reliably after the user object is reloaded.
    ref.invalidate(firebaseUserProvider); // Use the base stream provider
    ref.invalidate(authStateProvider);
  },
);

/// Provider for linking Email/Password to a Google account
final linkEmailPasswordToGoogleProvider =
    FutureProvider.autoDispose.family<UserCredential, EmailPasswordCredentials>(
  (ref, credentials) async {
    final authService = ref.watch(authServiceProvider);
    // Corrected method name
    return await authService.linkEmailPasswordToGoogle(
      credentials.email,
      credentials.password,
    );
  },
);

/// Provider for linking Google to Email/Password account
final linkGoogleToEmailPasswordProvider = FutureProvider.autoDispose<void>(
  (ref) async {
    final authService = ref.watch(authServiceProvider);
    await authService.linkGoogleToEmailPassword();
    // Invalidate both the source stream and the derived state
    // to ensure the UI updates reliably after the user object is reloaded.
    ref.invalidate(firebaseUserProvider); // Use the base stream provider
    ref.invalidate(authStateProvider);
  },
);

/// Provider for updating user password
final updatePasswordProvider =
    FutureProvider.autoDispose.family<void, String>((ref, newPassword) async {
  final authService = ref.watch(authServiceProvider);
  await authService.updatePassword(newPassword);
});

/// Helper class for email/password credentials
class EmailPasswordCredentials {
  final String email;
  final String password;

  EmailPasswordCredentials({required this.email, required this.password});
}

/// Helper function to show a themed SnackBar
void showThemedSnackBar({
  required BuildContext context,
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 10),
}) {
  // Check if the context is still mounted before showing the SnackBar
  if (!context.mounted) return;

  // Get the ScaffoldMessenger safely
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Clear any existing SnackBars to prevent overlap
  scaffoldMessenger.clearSnackBars();

  // Show the new SnackBar
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError
              ? Theme.of(context)
                  .colorScheme
                  .onErrorContainer // Use onErrorContainer for errors
              : Theme.of(context)
                  .colorScheme
                  .onPrimaryContainer, // Use onPrimaryContainer for success
        ),
      ),
      backgroundColor: isError
          ? Theme.of(context)
              .colorScheme
              .errorContainer // Use errorContainer for errors
          : Theme.of(context)
              .colorScheme
              .primaryContainer, // Use primaryContainer for success
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: isError
            ? Theme.of(context)
                .colorScheme
                .onErrorContainer // Use onErrorContainer for errors
            : Theme.of(context)
                .colorScheme
                .onPrimaryContainer, // Use onPrimaryContainer for success
        onPressed: () => scaffoldMessenger.hideCurrentSnackBar(),
      ),
    ),
  );
}
