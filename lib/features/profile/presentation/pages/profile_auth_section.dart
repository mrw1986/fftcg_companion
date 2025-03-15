import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/shared/widgets/styled_button.dart';

/// Shows a snackbar with a message
void showThemedSnackBar({
  required BuildContext context,
  required String message,
  required bool isError,
  Duration duration = const Duration(seconds: 4),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: isError
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
        ),
      ),
      backgroundColor:
          isError ? colorScheme.errorContainer : colorScheme.primaryContainer,
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: isError
            ? colorScheme.onErrorContainer
            : colorScheme.onPrimaryContainer,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

class ProfileAuthSection extends ConsumerWidget {
  const ProfileAuthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (authState.isAuthenticated || authState.isEmailNotVerified) {
      final user = authState.user!;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Column(
        children: [
          // Show email verification warning if needed
          if (authState.isEmailNotVerified)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text(
                        'Email Not Verified',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your email and verify your account. A verification email has been sent to ${user.email}. You will be signed out until you verify your email.',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: StyledButton(
                      onPressed: () async {
                        // Resend verification email

                        // Show loading indicator
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Sending verification email...'),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        try {
                          await ref
                              .read(authServiceProvider)
                              .sendEmailVerification();
                          if (context.mounted) {
                            // Clear any existing SnackBars
                            scaffoldMessenger.clearSnackBars();
                            showThemedSnackBar(
                              context: context,
                              message:
                                  'Verification email resent. Please check your inbox.',
                              isError: false,
                            );
                          }
                        } catch (error) {
                          talker.error(
                              'Error sending verification email', error);

                          if (context.mounted) {
                            // Clear any existing SnackBars
                            scaffoldMessenger.clearSnackBars();

                            String errorMessage =
                                'Failed to resend verification email. Please try again later.';

                            // Handle specific Firebase errors
                            if (error is FirebaseAuthException) {
                              if (error.code == 'too-many-requests') {
                                errorMessage =
                                    'Too many requests. We have temporarily blocked email sending due to unusual activity. Please try again later.';
                              }
                            }

                            showThemedSnackBar(
                              context: context,
                              message: errorMessage,
                              isError: true,
                            );
                          }
                        }
                      },
                      text: 'Resend Verification Email',
                      // Use a fixed color that works well with the red background
                      backgroundColor: Colors.white,
                      textColor: Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),

          // Account Information Card
          // Account Information Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(user.email ?? 'No email'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Account Type'),
                    subtitle: Text(_getProviderName(user)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (authState.isAnonymous) {
      // Get theme colors with guaranteed contrast
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final contrast = theme.extension<ContrastExtension>();

      return Column(
        children: [
          // Account Information Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: const Text('No email'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: const Text('Account Type'),
                    subtitle: const Text('Anonymous'),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 8),
                            Text(
                              'Anonymous Account',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your data is only stored on this device. To save your data across devices, upgrade to a permanent account.',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => context.go('/profile/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      contrast?.primaryWithContrast ??
                                          colorScheme.primary,
                                  foregroundColor:
                                      contrast?.onPrimaryWithContrast ??
                                          colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    context.go('/profile/register'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      contrast?.primaryWithContrast ??
                                          colorScheme.primary,
                                  foregroundColor:
                                      contrast?.onPrimaryWithContrast ??
                                          colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Create Account'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Unauthenticated
      // Get theme colors with guaranteed contrast
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final contrast = theme.extension<ContrastExtension>();

      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  // Ensure text is visible by using onSurface color
                  color:
                      contrast?.onSurfaceWithContrast ?? colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to save your collection, decks, and settings across devices.',
                style: TextStyle(
                  fontSize: 16,
                  // Ensure text is visible by using onSurface color
                  color:
                      contrast?.onSurfaceWithContrast ?? colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/profile/login'),
                      style: ElevatedButton.styleFrom(
                        // Use primary color with high contrast
                        backgroundColor: contrast?.primaryWithContrast ??
                            colorScheme.primary,
                        foregroundColor: contrast?.onPrimaryWithContrast ??
                            colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.go('/profile/register'),
                      style: TextButton.styleFrom(
                        // Use primary color with high contrast
                        foregroundColor: contrast?.primaryWithContrast ??
                            colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          // Ensure text is visible
                          color: contrast?.primaryWithContrast ??
                              colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  String _getProviderName(User user) {
    if (user.isAnonymous) {
      return 'Anonymous';
    }

    final providers = user.providerData.map((e) => e.providerId).toList();

    if (providers.contains('google.com')) {
      return 'Google';
    } else if (providers.contains('password')) {
      return 'Email/Password';
    } else {
      return 'Unknown';
    }
  }
}
