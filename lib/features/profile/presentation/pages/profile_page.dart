import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // No longer needed directly here
import 'package:fftcg_companion/core/providers/auth_provider.dart';
// import 'package:fftcg_companion/core/utils/logger.dart'; // No longer needed directly here
import 'package:fftcg_companion/features/profile/presentation/pages/profile_settings.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/splash_screen_provider.dart';
// import 'package:fftcg_companion/shared/utils/snackbar_helper.dart'; // No longer needed directly here
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
    // Wrap the banner in a Card for consistency
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            // Fixed: Use withValues instead of withOpacity
            color: colorScheme.primary.withValues(alpha: 128), // Softer border
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    ref.watch(splashScreenPreferencesProvider); // Used for reactivity
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine if the user is authenticated or email-unverified (i.e., not anonymous or unauthenticated)
    final bool showAccountSection =
        authState.status == AuthStatus.authenticated ||
            authState.status == AuthStatus.emailNotVerified;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        elevation: 1,
      ),
      // Apply gradient background similar to AccountSettingsPage
      backgroundColor: colorScheme.surface,
      body: authState.isLoading
          ? const Center(child: LoadingIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surface,
                  ],
                ),
              ),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 8), // Adjusted padding
                children: [
                  // Show auth banner only for unauthenticated or anonymous users
                  if (authState.status == AuthStatus.unauthenticated ||
                      authState.status == AuthStatus.anonymous)
                    _buildAuthBanner(context, colorScheme, theme),

                  // Account Settings Card (for authenticated or email-unverified users)
                  if (showAccountSection)
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Icon(Icons.manage_accounts,
                            color: colorScheme.secondary),
                        title: const Text('Account Settings'),
                        subtitle: const Text(
                            'Manage your account information and preferences'),
                        trailing: Icon(Icons.chevron_right,
                            color: colorScheme.onSurfaceVariant),
                        onTap: () => context.go('/profile/account'),
                      ),
                    ),

                  // App Settings Card (available to all users)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show header only if authenticated or email-unverified
                        if (showAccountSection)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 16, left: 16, right: 16, bottom: 8),
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
                        // Add some bottom padding inside the card
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
