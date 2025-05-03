import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/initialization_provider.dart';
// Removed: import 'package:fftcg_companion/features/profile/presentation/widgets/account_limits_dialog.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
// Import router

class LoadingWrapper extends ConsumerWidget {
  final Widget child;

  const LoadingWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    talker.debug('LoadingWrapper build called');
    final initializationState = ref.watch(initializationProvider);
    talker.debug('LoadingWrapper initialization state: $initializationState');

    // Watch initialization state changes
    ref.listen<AsyncValue<void>>(initializationProvider, (previous, next) {
      talker.debug('Initialization state changed:');
      talker.debug('Previous: $previous');
      talker.debug('Next: $next');

      // Log initialization completion
      next.whenData((_) {
        talker.debug('Initialization completed, checking auth state');
        final authState = ref.read(authNotifierProvider);
        talker.debug('Auth state after initialization:');
        talker.debug('Status: ${authState.status}');
        talker.debug('Is anonymous: ${authState.isAnonymous}');
        talker.debug(
            'Is email not verified: ${authState.isEmailNotVerifiedState}');
        talker.debug('User: ${authState.user?.email}');
      });
    });

    // Watch auth state to show dialog when it changes
    ref.listen<AuthState>(authNotifierProvider, (previous, next) async {
      // Only proceed if initialization is complete
      final initState = ref.read(initializationProvider);
      if (!initState.hasValue) {
        talker.debug('Skipping auth state change, initialization not complete');
        return;
      }
      talker.debug('LoadingWrapper auth state changed:');
      talker.debug('Previous: ${previous?.status}');
      talker.debug('Next: ${next.status}');
      talker.debug('Is anonymous: ${next.isAnonymous}');
      talker.debug(
          'Is email not verified state: ${next.isEmailNotVerifiedState}');
      talker.debug('User: ${next.user?.email}');

      // Removed logic to show AccountLimitsDialog on auth state change
      // if ((next.isAnonymous || next.isEmailNotVerifiedState) &&
      //     previous?.status != AuthStatus.authenticated) {
      //   talker.debug('Auth state indicates dialog should be shown');
      //   final storage = HiveStorage();
      //   final isBoxAvailable = await storage.isBoxAvailable('settings');
      //   if (!isBoxAvailable) {
      //     talker.error('Settings box not available during auth state change');
      //     return;
      //   }
      //   final navigatorContext =
      //       ref.read(rootNavigatorKeyProvider).currentContext;
      //   if (navigatorContext != null && navigatorContext.mounted) {
      //     talker.debug(
      //         'Attempting to show dialog due to auth state change using navigator context');
      //     // Removed: AccountLimitsDialog.showIfNeeded(navigatorContext);
      //   } else {
      //     talker.error(
      //         'Navigator context not available or mounted during auth state change');
      //   }
      // }
    });

    return Stack(
      children: [
        // Show child only when initialization is complete
        initializationState.maybeWhen(
          data: (_) {
            talker.debug(
                'LoadingWrapper initialization complete, checking initial state');
            // Removed logic to show AccountLimitsDialog on initial load
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              talker.debug('Initial load post-frame callback');
              final authState = ref.read(authNotifierProvider);
              talker.debug('Initial auth state:');
              talker.debug('Status: ${authState.status}');
              talker.debug('Is anonymous: ${authState.isAnonymous}');
              talker.debug(
                  'Is email not verified state: ${authState.isEmailNotVerifiedState}');
              talker.debug('User: ${authState.user?.email}');

              // Removed logic to show AccountLimitsDialog on initial load
              // if (authState.isAnonymous || authState.isEmailNotVerifiedState) {
              //   talker.debug('Initial state indicates dialog should be shown');
              //   final storage = HiveStorage();
              //   final isBoxAvailable = await storage.isBoxAvailable('settings');
              //   if (!isBoxAvailable) {
              //     talker
              //         .error('Settings box not available during initial load');
              //     return;
              //   }

              //   // Removed logic to reset timestamp for anonymous users
              //   // if (authState.isAnonymous) {
              //   //   await storage.put('last_limits_dialog_shown', 0,
              //   //       boxName: 'settings');
              //   //   talker.debug(
              //   //       'Reset account limits dialog timestamp for existing anonymous user');
              //   // }

              //   final navigatorContext =
              //       ref.read(rootNavigatorKeyProvider).currentContext;
              //   if (navigatorContext != null && navigatorContext.mounted) {
              //     talker.debug(
              //         'Attempting to show dialog on initial load using navigator context');
              //     // Removed: AccountLimitsDialog.showIfNeeded(navigatorContext);
              //   } else {
              //     talker.error(
              //         'Navigator context not available or mounted during initial load');
              //   }
              // }
            });
            return child;
          },
          orElse: () {
            talker.debug('LoadingWrapper initialization not complete');
            return const SizedBox.shrink();
          },
        ),
        // Show loading screen during initialization or error
        initializationState.when(
          data: (_) => const SizedBox.shrink(),
          error: (error, _) => const LoadingIndicator(),
          loading: () => const LoadingIndicator(),
        ),
      ],
    );
  }
}
