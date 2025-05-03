import 'dart:async'; // Required for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart'; // Required for Listenable/VoidCallback
import 'package:go_router/go_router.dart'; // Required for GoRouterState in redirect
import 'package:fftcg_companion/core/services/auth_service.dart';
import 'package:fftcg_companion/features/profile/data/repositories/user_repository.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_provider.dart';
// Removed import for email_update_checker.dart
// Import the provider for original email check
import 'package:fftcg_companion/features/profile/presentation/pages/account_settings_page.dart';
// Removed incorrect imports for LoginPage and HomePage
// Import goRouterProvider for routeExists check (Removed - _routeExists logic removed)
// import 'package:fftcg_companion/core/routing/app_router.dart';

/// Authentication status enum (Keep as is)
enum AuthStatus {
  unauthenticated,
  anonymous,
  emailNotVerified, // Represents state where ONLY unverified email/pass exists
  authenticated,
  loading, // Changed from initial/authenticating for simplicity
  error,
}

/// Authentication state class (Keep as is)
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool emailNotVerified; // Keep for UI hints if needed

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

  AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        emailNotVerified = false, // Handled by status enum
        errorMessage = null;

  AuthState.emailNotVerified(this.user)
      : status = AuthStatus.emailNotVerified,
        emailNotVerified = true, // Explicitly true for this state
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

  // Add getters for convenience if needed
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isEmailNotVerifiedState => status == AuthStatus.emailNotVerified;
  bool get isAnonymous => status == AuthStatus.anonymous;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

// --- NEW AuthNotifier ---
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> implements Listenable {
  VoidCallback? _routerListener;
  StreamSubscription<User?>? _authSubscription;
  // Removed _userSubscription

  @override
  AuthState build() {
    // Initial state
    state = const AuthState.loading();

    // Listen to Firebase Auth state changes
    _listenToAuthChanges();

    // Perform initial check
    _checkInitialAuthStatus();

    // Setup cleanup for subscriptions
    ref.onDispose(() {
      talker.debug("Disposing AuthNotifier: Cancelling subscriptions.");
      _authSubscription?.cancel();
      // _userSubscription?.cancel(); // Removed
      _routerListener = null; // Clear listener on dispose
    });

    // Return initial state
    return state;
  }

  void _listenToAuthChanges() {
    final authService = ref.read(authServiceProvider);
    _authSubscription?.cancel(); // Cancel previous subscription if any
    _authSubscription = authService.authStateChanges.listen(
      (user) async {
        talker.debug(
            'AuthNotifier: Firebase auth state changed. User: ${user?.uid}');
        await _updateStateFromUser(user); // Update state based on user
        // Removed call to _listenToUserChanges
      },
      onError: (error, stackTrace) {
        talker.error('AuthNotifier: Error in auth stream', error, stackTrace);
        state = AuthState.error(error.toString());
        _routerListener?.call(); // Notify router on error
      },
    );
  }

  // Removed _listenToUserChanges method as main stream often covers necessary updates

  Future<void> _checkInitialAuthStatus() async {
    talker.debug('AuthNotifier: Checking initial auth status...');
    // Use the stream's current value if available, otherwise get current user directly
    final initialUser = ref.read(firebaseUserProvider).valueOrNull ??
        FirebaseAuth.instance.currentUser;
    // Ensure reload happens if getting current user directly
    if (initialUser != null &&
        ref.read(firebaseUserProvider).valueOrNull == null) {
      try {
        await initialUser.reload();
        talker.debug("Initial user reloaded.");
      } catch (e) {
        talker.warning("Failed to reload initial user: $e");
        // Decide how to handle reload failure - maybe sign out?
      }
    }
    await _updateStateFromUser(
        FirebaseAuth.instance.currentUser); // Use potentially reloaded user
  }

  Future<void> _updateStateFromUser(User? user) async {
    final previousStatus = state.status; // Store previous status for logging
    AuthState newState;

    // Check for email update completion first
    if (user != null) {
      final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
      if (pendingEmail != null && user.email == pendingEmail) {
        // Email has been verified and updated, clear the pending state
        ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
        ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
        talker.info(
            'Detected email verification completion in AuthNotifier, cleared pending email state.');
      }
    }

    if (user == null) {
      newState = const AuthState.unauthenticated();
    } else if (user.isAnonymous) {
      newState = AuthState.anonymous(user);
    } else {
      // It might still be beneficial to reload here occasionally,
      // especially if emailVerified status is critical and might lag in the stream.
      // Reload the user to ensure we have the latest data, especially emailVerified status
      // and potentially the updated email after verifyBeforeUpdateEmail flow.
      try {
        talker.debug(
            'AuthNotifier: Reloading user ${user.uid} before updating state...');
        await user.reload();
        talker.debug('AuthNotifier: User ${user.uid} reloaded successfully.');
        // Update the user variable reference to the potentially reloaded instance
        user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          // If reload somehow resulted in null user (edge case, e.g., disabled), handle as unauthenticated
          talker.warning(
              'AuthNotifier: User became null after reload. Setting state to unauthenticated.');
          newState = const AuthState.unauthenticated();
          // Skip further checks for this user, the outer logic will handle state update
          state = newState;
          _syncFirestoreAndFlags(null); // Trigger sign-out cleanup
          _routerListener?.call();
          return; // Exit the function early
        }
      } catch (e, s) {
        talker.error(
            'AuthNotifier: Failed to reload user ${user!.uid}',
            e, // Re-add null assertion
            s); // Add null check
        // Decide how to handle reload failure. Maybe keep existing state or go to error?
        // For now, let's proceed with the potentially stale user data but log the error.
        // Alternatively, could set state = AuthState.error("Failed to refresh user data");
      }

      bool hasPasswordProvider = user.providerData // Keep null check removed
          .any((userInfo) => userInfo.providerId == 'password');

      if (hasPasswordProvider && !user.emailVerified) {
        // Null check removed as it's guaranteed non-null here
        newState = AuthState.emailNotVerified(user);
      } else {
        newState = AuthState.authenticated(user);
      }
    }

    // Only update state and notify if the status actually changed
    if (newState.status != state.status) {
      talker.debug(
          'AuthNotifier: Updating state from $previousStatus to ${newState.status} for user: ${user?.uid}');
      state = newState;
      _syncFirestoreAndFlags(user); // Perform sync actions after state update
      _routerListener?.call(); // Notify router AFTER state is updated
    } else {
      talker.debug(
          'AuthNotifier: State status ${state.status} unchanged for user: ${user?.uid}. Not notifying router.');
      // Still sync Firestore if user object itself might have changed details
      if (state.user?.uid == user?.uid) {
        // Ensure it's the same user
        _syncFirestoreAndFlags(user);
      }
    }
  }

  // Helper to consolidate Firestore sync and flag resets
  void _syncFirestoreAndFlags(User? user) {
    // --- Firestore Sync ---
    if (user != null) {
      // Trigger Firestore sync asynchronously (don't await here)
      _triggerFirestoreSync(user);
    } else {
      // Handle sign-out cleanup if needed (e.g., clear pending email)
      _handleSignOutCleanup();
    }

    // --- Reset Flags ---
    _resetVerificationFlagIfNeeded(user);
  }

  Future<void> _triggerFirestoreSync(User user) async {
    try {
      // Verify token validity before syncing
      talker.debug(
          'AuthNotifier (Sync): Verifying token validity for ${user.uid}');
      await user.getIdToken(true); // Force refresh
      talker.debug('AuthNotifier (Sync): Token is valid for ${user.uid}');

      final userRepository = ref.read(userRepositoryProvider);
      // Check if user document needs creation/update (simplified check)
      // A more robust check might involve comparing timestamps or specific fields
      talker.debug(
          'AuthNotifier (Sync): Triggering createUserFromAuth for ${user.uid}');
      await userRepository.createUserFromAuth(user);
      talker.debug(
          'AuthNotifier (Sync): Successfully synced user ${user.uid} to Firestore.');
      await userRepository.verifyAndCorrectCollectionCount(user.uid);

      // Clear pending email if applicable
      final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
      if (pendingEmail != null && user.email == pendingEmail) {
        talker.debug(
            'AuthNotifier (Sync): Detected user email matches pending email. Clearing pending state.');
        ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
        // **NEW:** Also clear the original email stored for the lifecycle check
        ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
        talker.debug(
            'AuthNotifier (Sync): Cleared originalEmailForUpdateCheckProvider.');
      }
    } on FirebaseAuthException catch (e) {
      talker.warning(
          'AuthNotifier (Sync): Token refresh failed for ${user.uid}', e);
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'invalid-user-token') {
        talker.warning(
            'AuthNotifier (Sync): User ${user.uid} is invalid on backend. Forcing sign out.');
        try {
          await ref.read(authServiceProvider).signOut(isInternalAuthFlow: true);
        } catch (signOutError) {
          talker.error('AuthNotifier (Sync): Error during forced sign out',
              signOutError);
        }
      }
    } catch (e, s) {
      talker.error(
          'AuthNotifier (Sync): Error syncing user ${user.uid} to Firestore',
          e,
          s);
    }
  }

  void _handleSignOutCleanup() {
    talker.debug('AuthNotifier (Sync): Handling sign out cleanup.');
    final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
    if (pendingEmail != null) {
      talker.debug(
          'AuthNotifier (Sync): Clearing pending email state due to sign out.');
      ref.read(emailUpdateNotifierProvider.notifier).clearPendingEmail();
    }
    // **NEW:** Clear the original email stored for the lifecycle check on sign out
    ref.read(originalEmailForUpdateCheckProvider.notifier).state = '';
    talker.debug(
        'AuthNotifier (Sync): Cleared originalEmailForUpdateCheckProvider on sign out.');

    // **REMOVED:** Stop the email update checker polling if it's running
    // if (ref.read(emailUpdateCheckerProvider).isPolling) {
    //   ref.read(emailUpdateCheckerProvider.notifier).stopPolling();
    // }
  }

  void _resetVerificationFlagIfNeeded(User? user) {
    bool shouldReset = user == null || user.emailVerified || user.isAnonymous;
    if (shouldReset && ref.read(emailVerificationDetectedProvider)) {
      talker.debug(
          'AuthNotifier: Resetting emailVerificationDetectedProvider to false.');
      ref.read(emailVerificationDetectedProvider.notifier).state = false;
    }
  }

  // --- Listenable Implementation ---
  @override
  void addListener(VoidCallback listener) {
    _routerListener = listener;
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerListener = null;
  }

  // --- Redirect Logic (Moved from GoRouter) ---
  String? redirect(BuildContext context, GoRouterState goRouterState) {
    // Use the current state of this notifier
    final currentAuthState = state; // Read the current state directly
    final authStatus = currentAuthState.status;
    final currentMatchedLocation = goRouterState.matchedLocation;
    final targetUri = goRouterState.uri.toString();

    talker.debug(
        'AuthNotifier Redirect Check: MatchedLocation="$currentMatchedLocation", TargetUri="$targetUri", AuthStatus=$authStatus');

    // --- Prevent Redirects FROM Account Settings ---
    if (currentMatchedLocation == '/profile/account') {
      if (authStatus == AuthStatus.unauthenticated) {
        talker.debug(
            'AuthNotifier Redirect: Unauthenticated on /profile/account -> /auth');
        return '/auth'; // Use actual route path
      } else {
        talker.debug(
            'AuthNotifier Redirect: Already on /profile/account and status is $authStatus, staying put.');
        return null;
      }
    }
    // --- END: Prevent Redirects FROM Account Settings ---

    final publicRoutes = ['/auth', '/register', '/reset-password'];
    final isPublicRoute =
        publicRoutes.any((route) => targetUri.startsWith(route));

    // 1. Loading State - Allow navigation while loading/initializing
    if (authStatus == AuthStatus.loading) {
      talker.debug('AuthNotifier Redirect: Auth loading, no redirect.');
      return null;
    }

    // 2. Unauthenticated on Protected Route -> /auth
    if (authStatus == AuthStatus.unauthenticated && !isPublicRoute) {
      talker.debug(
          'AuthNotifier Redirect: Unauthenticated on protected route ($targetUri) -> /auth');
      return '/auth'; // Use actual route path
    }

    // 3. Authenticated or EmailNotVerified on Public Auth Route -> / (Home)
    //    (Except for reset password page)
    if ((authStatus == AuthStatus.authenticated ||
            authStatus == AuthStatus.emailNotVerified) &&
        isPublicRoute &&
        targetUri != '/reset-password') {
      talker.debug(
          'AuthNotifier Redirect: Authenticated/EmailNotVerified on public auth route ($targetUri) -> /');
      return '/'; // Use actual home route path
    }

    // 4. Authenticated, EmailNotVerified, or Anonymous on a PROTECTED route -> Stay
    if ((authStatus == AuthStatus.authenticated ||
            authStatus == AuthStatus.emailNotVerified ||
            authStatus == AuthStatus.anonymous) &&
        !isPublicRoute) {
      talker.debug(
          'AuthNotifier Redirect: Status $authStatus on protected route ($targetUri), staying put.');
      return null; // Explicitly stay
    }

    // 5. Default: No redirect needed
    talker.debug(
        'AuthNotifier Redirect: No redirect needed (default/fallback). Target: $targetUri');
    return null;
  }

  // Removed dispose method, cleanup handled in ref.onDispose within build()
}

// --- Other Providers ---

/// Provider for the AuthService (Unchanged)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for the current user stream from Firebase Auth (Unchanged)
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  talker.debug('Setting up Firebase Auth user stream');
  return authService.authStateChanges;
});

/// Provider for UserRepository (Unchanged)
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Provider for the current user (derived from AuthNotifier state)
final currentUserProvider = Provider<User?>((ref) {
  // Watch the new AuthNotifier
  return ref.watch(authNotifierProvider).user;
});

// authStatusProvider can be derived from authNotifierProvider
final authStatusProvider = Provider<AuthStatus>((ref) {
  final authState = ref.watch(authNotifierProvider);
  talker.debug('authStatusProvider returning status: ${authState.status}');
  return authState.status;
}, name: 'authStatusProvider');

/// StateProvider to signal immediate verification detection by the checker (Keep as is)
final emailVerificationDetectedProvider = StateProvider<bool>((ref) => false);

// --- Future Providers for Auth Actions (Invalidate new notifier) ---

/// Provider for handling user account deletion
final deleteUserProvider = FutureProvider.autoDispose<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  await authService.deleteUser();
  ref.invalidate(authNotifierProvider); // Invalidate the main notifier
});

/// Provider for re-authenticating a user with email and password
final reauthWithEmailProvider =
    FutureProvider.autoDispose.family<UserCredential, EmailPasswordCredentials>(
  (ref, credentials) async {
    final authService = ref.watch(authServiceProvider);
    final cred = await authService.reauthenticateWithEmailAndPassword(
      credentials.email,
      credentials.password,
    );
    ref.invalidate(authNotifierProvider); // Invalidate the main notifier
    return cred;
  },
);

/// Provider for re-authenticating a user with Google
final reauthWithGoogleProvider = FutureProvider.autoDispose<UserCredential>(
  (ref) async {
    final authService = ref.watch(authServiceProvider);
    final cred = await authService.reauthenticateWithGoogle();
    ref.invalidate(authNotifierProvider); // Invalidate the main notifier
    return cred;
  },
);

/// Provider for unlinking an authentication provider
final unlinkProviderProvider = FutureProvider.autoDispose.family<void, String>(
  (ref, providerId) async {
    final authService = ref.watch(authServiceProvider);
    await authService.unlinkProvider(providerId);
    ref.invalidate(authNotifierProvider); // Invalidate the main notifier
  },
);

/// Provider for linking Email/Password to a Google account
final linkEmailPasswordToGoogleProvider =
    FutureProvider.autoDispose.family<UserCredential, EmailPasswordCredentials>(
  (ref, credentials) async {
    final authService = ref.watch(authServiceProvider);
    try {
      final userCredential = await authService.linkEmailPasswordToGoogle(
        credentials.email,
        credentials.password,
      );
      ref.invalidate(authNotifierProvider); // Invalidate the main notifier
      talker.debug(
          'Successfully linked Email/Password to Google, invalidated main notifier.');
      return userCredential;
    } catch (e) {
      talker.error('Error linking Email/Password to Google: $e');
      rethrow;
    }
  },
);

/// Provider for linking Google to Email/Password account
final linkGoogleToEmailPasswordProvider = FutureProvider.autoDispose<void>(
  (ref) async {
    final authService = ref.watch(authServiceProvider);
    await authService.linkGoogleToEmailPassword();
    ref.invalidate(authNotifierProvider); // Invalidate the main notifier
  },
);

/// Provider for updating user password
final updatePasswordProvider =
    FutureProvider.autoDispose.family<void, String>((ref, newPassword) async {
  final authService = ref.watch(authServiceProvider);
  await authService.updatePassword(newPassword);
  ref.invalidate(authNotifierProvider); // Invalidate the main notifier
});

/// Helper class for email/password credentials (Unchanged)
class EmailPasswordCredentials {
  final String email;
  final String password;

  EmailPasswordCredentials({required this.email, required this.password});
}

/// Helper function to show a themed SnackBar (Unchanged)
void showThemedSnackBar({
  required BuildContext context,
  required String message,
  bool isError = false,
  Duration duration = const Duration(seconds: 10),
}) {
  if (!context.mounted) return;
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  scaffoldMessenger.clearSnackBars();
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError
              ? Theme.of(context).colorScheme.onErrorContainer
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: isError
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
        onPressed: () => scaffoldMessenger.hideCurrentSnackBar(),
      ),
    ),
  );
}
