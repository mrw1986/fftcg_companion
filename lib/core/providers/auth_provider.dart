import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for the current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the authentication state
final authStateProvider = Provider.autoDispose<AuthState>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return const AuthState.unauthenticated();
      }

      // First check if the user is anonymous
      if (user.isAnonymous) {
        // Even if there are providers, if isAnonymous is true, treat as anonymous
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
            return AuthState.authenticated(user);
          } else {
            // Only has unverified email/password, show unverified state
            return AuthState.emailNotVerified(user);
          }
        }

        // User either has no email/password or it's verified
        return AuthState.authenticated(user);
      }
    },
    loading: () => const AuthState.loading(),
    error: (error, stackTrace) => AuthState.error(error.toString()),
  );
});

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
    ref.invalidate(currentUserProvider);
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
    ref.invalidate(currentUserProvider);
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
