import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/services/auth_service.dart';

/// Provider for checking if email verification is required for sensitive operations
final emailVerificationRequiredProvider = Provider<bool>((ref) {
  // This could be configurable in the future
  return true;
});

/// Provider for the grace period for new accounts (in days)
final accountGracePeriodProvider = Provider<int>((ref) {
  // This could be configurable in the future
  return 7;
});

/// Provider for the maximum number of collection items for anonymous users
final anonymousCollectionLimitProvider = Provider<int>((ref) {
  // This could be configurable in the future
  return 50;
});

/// Provider for checking if a user's email is verified
final isEmailVerifiedProvider = FutureProvider<bool>((ref) async {
  final authService = AuthService();
  return await authService.isEmailVerified();
});

/// Provider for checking if a user's account is older than the grace period
final isAccountOlderThanGracePeriodProvider = FutureProvider<bool>((ref) async {
  final authService = AuthService();
  final gracePeriod = ref.watch(accountGracePeriodProvider);
  return await authService.isAccountOlderThan(gracePeriod);
});

/// Provider for checking if a user is anonymous
final isAnonymousProvider = Provider<bool>((ref) {
  final authService = AuthService();
  return authService.isAnonymous();
});
