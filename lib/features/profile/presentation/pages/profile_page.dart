import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_settings.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/splash_screen_provider.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // UI components
  Widget _buildAuthBanner(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign in to your account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to save your collection, decks, and settings across devices.',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/profile/auth'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/profile/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Create Account'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.watch(splashScreenPreferencesProvider); // Used for reactivity
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        elevation: 1,
      ),
      body: authState.isLoading
          ? const Center(child: LoadingIndicator())
          : ListView(
              children: [
                // Show auth banner only for unauthenticated or anonymous users
                if (authState.status == AuthStatus.unauthenticated ||
                    authState.status == AuthStatus.anonymous)
                  _buildAuthBanner(context, colorScheme, theme),

                // Email verification warning banner
                // Corrected Condition: Check the specific status, not the flag
                if (authState.status == AuthStatus.emailNotVerified)
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
                          'Please check your email and verify your account. A verification email has been sent to ${authState.user!.email}. You will be signed out until you verify your email.',
                          style: TextStyle(color: colorScheme.onErrorContainer),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Resend verification email
                              final scaffoldMessenger =
                                  ScaffoldMessenger.of(context);
                              SnackBarHelper.showSnackBar(
                                context: context,
                                message: 'Sending verification email...',
                                duration: const Duration(seconds: 2),
                              );

                              try {
                                await ref
                                    .read(authServiceProvider)
                                    .sendEmailVerification();
                                if (context.mounted) {
                                  scaffoldMessenger.clearSnackBars();
                                  SnackBarHelper.showSuccessSnackBar(
                                    context: context,
                                    message:
                                        'Verification email resent. Please check your inbox.',
                                  );
                                }
                              } catch (error) {
                                talker.error(
                                    'Error sending verification email', error);

                                if (context.mounted) {
                                  scaffoldMessenger.clearSnackBars();

                                  String errorMessage =
                                      'Failed to resend verification email. Please try again later.';

                                  if (error is FirebaseAuthException) {
                                    if (error.code == 'too-many-requests') {
                                      errorMessage =
                                          'Too many requests. We have temporarily blocked email sending due to unusual activity. Please try again later.';
                                    }
                                  }

                                  SnackBarHelper.showErrorSnackBar(
                                    context: context,
                                    message: errorMessage,
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.email_outlined),
                            label: const Text('Resend Verification Email'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.surface,
                              foregroundColor: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Account Settings option for authenticated users
                // Corrected Condition: Show only if truly authenticated, not in emailNotVerified state
                if (authState.status == AuthStatus.authenticated)
                  ListTile(
                    leading: Icon(Icons.manage_accounts,
                        color: colorScheme.secondary),
                    title: const Text('Account Settings'),
                    subtitle: const Text(
                        'Manage your account information and preferences'),
                    trailing: Icon(Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant),
                    onTap: () => context.go('/profile/account'),
                  ),

                // Divider before app settings
                // Corrected Condition: Show only if truly authenticated
                if (authState.status == AuthStatus.authenticated)
                  const Divider(
                    height: 32,
                    thickness: 1,
                    indent: 16,
                    endIndent: 16,
                  ),

                // App settings section header
                // Corrected Condition: Show only if truly authenticated
                if (authState.status == AuthStatus.authenticated)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    child: Text(
                      'App Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                // Settings section (available to all users)
                const ProfileSettings(),
              ],
            ),
    );
  }
}
