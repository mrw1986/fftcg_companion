import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_provider.dart';

/// Provider to monitor and periodically check for email update verification
final emailUpdateVerificationCheckerProvider =
    NotifierProvider<EmailUpdateVerificationChecker, bool>(
  () => EmailUpdateVerificationChecker(),
);

class EmailUpdateVerificationChecker extends Notifier<bool> {
  Timer? _timer;
  static const Duration _checkInterval = Duration(seconds: 5);
  static const int _maxChecks = 60; // 5 minutes total (5s * 60)
  int _checkCount = 0;
  String? _pendingEmail;
  String? _currentEmail;

  @override
  bool build() {
    // Initialize state as not verified
    ref.onDispose(() {
      _stopChecking();
    });
    return false;
  }

  /// Start checking for email update verification
  void startChecking() {
    _stopChecking(); // Stop any existing timer

    final pendingEmail = ref.read(emailUpdateNotifierProvider).pendingEmail;
    if (pendingEmail == null || pendingEmail.isEmpty) {
      talker.debug(
          'EmailUpdateVerificationChecker: No pending email to check for.');
      return;
    }

    _pendingEmail = pendingEmail;
    _currentEmail = FirebaseAuth.instance.currentUser?.email;
    _checkCount = 0;

    talker.info(
        'EmailUpdateVerificationChecker: Starting to check for email update from $_currentEmail to $_pendingEmail');

    // Start periodic checking
    _timer = Timer.periodic(_checkInterval, _checkVerification);
  }

  /// Stop checking for email verification
  void _stopChecking() {
    _timer?.cancel();
    _timer = null;
    _checkCount = 0;
    talker.debug('EmailUpdateVerificationChecker: Stopped checking');
  }

  /// Check if email has been verified
  void _checkVerification(Timer timer) async {
    _checkCount++;

    if (_checkCount > _maxChecks) {
      talker.info(
          'EmailUpdateVerificationChecker: Reached maximum checks, stopping');
      _stopChecking();
      return;
    }

    if (_pendingEmail == null) {
      talker.warning(
          'EmailUpdateVerificationChecker: No pending email to check for, stopping.');
      _stopChecking();
      return;
    }

    talker.debug(
        'EmailUpdateVerificationChecker: Checking email update verification ($_checkCount/$_maxChecks)');

    try {
      // First refresh the token in case email verification has happened
      try {
        // Try without force first
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          talker.warning(
              'EmailUpdateVerificationChecker: No user found, stopping checks.');
          _stopChecking();
          return;
        }

        // Try to refresh token without force
        await user.getIdToken(false);
        talker.debug(
            'EmailUpdateVerificationChecker: Token refreshed without force');
      } catch (e) {
        // If first attempt fails, the token might be invalidated due to email verification
        talker.info(
            'EmailUpdateVerificationChecker: Regular token refresh failed, trying with force.');

        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            talker.warning(
                'EmailUpdateVerificationChecker: No user found after token refresh error, stopping checks.');
            _stopChecking();
            return;
          }

          // Try force refresh
          await user.getIdToken(true);
          talker.debug(
              'EmailUpdateVerificationChecker: Token refreshed with force');
        } catch (innerError) {
          // If force refresh fails, user session might be invalid
          talker.warning(
              'EmailUpdateVerificationChecker: Force token refresh failed: $innerError');

          if (innerError is FirebaseAuthException &&
              (innerError.code == 'user-token-expired' ||
                  innerError.code == 'user-not-found' ||
                  innerError.code == 'invalid-user-token')) {
            // This is actually a sign that email verification has completed!
            talker.info(
                'EmailUpdateVerificationChecker: Token invalidated, likely due to email verification completion');

            state = true; // Set state to indicate verification completed
            _stopChecking();
            return;
          }
        }
      }

      // Reload the user to get latest state
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        talker.warning(
            'EmailUpdateVerificationChecker: No user found after token refresh, stopping checks.');
        _stopChecking();
        return;
      }

      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        talker.warning(
            'EmailUpdateVerificationChecker: User null after reload, stopping checks.');
        _stopChecking();
        return;
      }

      // Check if email has changed to pending email
      final currentEmail = refreshedUser.email;
      if (currentEmail == _pendingEmail) {
        talker.info(
            'EmailUpdateVerificationChecker: Email update verification completed! Email changed from $_currentEmail to $currentEmail');

        // Update provider state to indicate verification completed
        state = true;

        // Stop checking since verification is complete
        _stopChecking();
      } else {
        talker.debug(
            'EmailUpdateVerificationChecker: Email unchanged (current: $currentEmail, pending: $_pendingEmail)');
      }
    } catch (e) {
      talker.error(
          'EmailUpdateVerificationChecker: Error checking verification', e);

      // Don't stop checking on error unless it's a critical auth error
      if (e is FirebaseAuthException &&
          (e.code == 'user-disabled' || e.code == 'app-not-authorized')) {
        talker.warning(
            'EmailUpdateVerificationChecker: Critical auth error, stopping checks: ${e.code}');
        _stopChecking();
      }
    }
  }
}
