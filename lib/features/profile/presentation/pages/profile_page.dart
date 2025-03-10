import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/app/theme/contrast_extension.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/splash_screen_provider.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splashPrefs = ref.watch(splashScreenPreferencesProvider);
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (authState.isAuthenticated || authState.isAnonymous)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign Out',
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          // Authentication section
          _buildAuthSection(context, ref, authState),

          const Divider(),

          // App settings section
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/profile/theme'),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.image_outlined),
            title: const Text('Show Splash Screen'),
            subtitle: const Text('Display splash screen when app starts'),
            value: splashPrefs.enabled,
            onChanged: (_) {
              ref
                  .read(splashScreenPreferencesProvider.notifier)
                  .toggleEnabled();
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement notifications settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('View Logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/profile/logs'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement about page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthSection(
      BuildContext context, WidgetRef ref, AuthState authState) {
    if (authState.isAuthenticated) {
      final user = authState.user!;
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final contrast = theme.extension<ContrastExtension>();

      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              // Add a border for better visibility
              backgroundColor: colorScheme.primaryContainer,
              child: user.photoURL == null ? const Icon(Icons.person) : null,
            ),
            title: Text(
              user.displayName ?? 'User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: contrast?.onSurfaceWithContrast ?? colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              user.email ?? 'No email',
              style: TextStyle(
                color: contrast?.onSurfaceWithContrast ??
                    colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: contrast?.primaryWithContrast ?? colorScheme.primary,
            ),
            title: Text(
              'Account Settings',
              style: TextStyle(
                  color:
                      contrast?.onSurfaceWithContrast ?? colorScheme.onSurface),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: contrast?.onSurfaceWithContrast ??
                  colorScheme.onSurfaceVariant,
            ),
            onTap: () => context.go('/profile/account'),
          ),
        ],
      );
    } else if (authState.isAnonymous) {
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
                'You\'re using the app without an account',
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
                'Create an account to save your collection, decks, and settings across devices.',
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
                  const SizedBox(width: 8),
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
                ],
              ),
            ],
          ),
        ),
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
              const SizedBox(height: 8),
              // No longer needed as we automatically sign in anonymously
            ],
          ),
        ),
      );
    }
  }
}
