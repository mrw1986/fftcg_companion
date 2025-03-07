import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// Provider that automatically signs in anonymously if the user is not already signed in
final autoAuthProvider = Provider.autoDispose<void>((ref) {
  // Listen to auth state changes
  ref.listen(authStateProvider, (previous, next) async {
    // If the user is not authenticated (and not anonymous), sign in anonymously
    if (next.isUnauthenticated) {
      try {
        final authService = ref.read(authServiceProvider);
        talker.debug('Auto-signing in anonymously');
        await authService.signInAnonymously();
      } catch (e) {
        talker.error('Error auto-signing in anonymously', e);
      }
    }
  });

  return;
});
