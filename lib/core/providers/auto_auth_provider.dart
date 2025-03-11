import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';

/// State provider to track if we should skip auto-auth
/// This is used to prevent creating a new anonymous user after explicit sign-out
final skipAutoAuthProvider = StateProvider<bool>((ref) => false);

/// Provider that automatically signs in anonymously if the user is not already signed in
final autoAuthProvider = Provider.autoDispose<void>((ref) {
  // Track if we're coming from a sign-out operation
  bool isInitialLoad = true;
  Timer? debounceTimer;

  // Listen to auth state changes
  ref.listen(authStateProvider, (previous, next) async {
    // Cancel any pending timer
    debounceTimer?.cancel();

    // Get the skip auto-auth state
    final skipAutoAuth = ref.read(skipAutoAuthProvider);

    // If the user is not authenticated (and not anonymous), sign in anonymously
    if (next.isUnauthenticated && !skipAutoAuth) {
      // If this is the initial load, sign in immediately
      // Otherwise, add a delay to prevent rapid creation of anonymous users
      if (isInitialLoad) {
        isInitialLoad = false;
        _signInAnonymously(ref);
      } else {
        // Add a delay before creating a new anonymous user
        // This helps prevent unnecessary anonymous users from being created
        debounceTimer = Timer(const Duration(seconds: 2), () {
          _signInAnonymously(ref);
        });
      }
    }

    // If the user is authenticated, reset the skip auto-auth flag
    if (next.isAuthenticated || next.isAnonymous) {
      ref.read(skipAutoAuthProvider.notifier).state = false;
    }
  });

  // Clean up timer when provider is disposed
  ref.onDispose(() {
    debounceTimer?.cancel();
  });

  return;
});

/// Helper function to sign in anonymously
Future<void> _signInAnonymously(Ref ref) async {
  try {
    final authService = ref.read(authServiceProvider);
    talker.debug('Auto-signing in anonymously');
    await authService.signInAnonymously();
  } catch (e) {
    talker.error('Error auto-signing in anonymously', e);
  }
}
