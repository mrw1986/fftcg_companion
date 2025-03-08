import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

/// Provider for the current user
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the authentication state
final authStateProvider = Provider<AuthState>((ref) {
  final userAsync = ref.watch(currentUserProvider);

  return userAsync.when(
    data: (user) {
      if (user == null) {
        return const AuthState.unauthenticated();
      } else if (user.isAnonymous) {
        return AuthState.anonymous(user);
      } else {
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

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = null;

  const AuthState.anonymous([this.user])
      : status = AuthStatus.anonymous,
        errorMessage = null;

  const AuthState.authenticated(this.user)
      : status = AuthStatus.authenticated,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.error(this.errorMessage)
      : status = AuthStatus.error,
        user = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAnonymous => status == AuthStatus.anonymous;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}

/// Authentication status enum
enum AuthStatus {
  unauthenticated,
  anonymous,
  authenticated,
  loading,
  error,
}
