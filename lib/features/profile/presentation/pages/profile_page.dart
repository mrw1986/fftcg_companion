import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/splash_screen_provider.dart';
import 'package:fftcg_companion/shared/widgets/loading_indicator.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPrefs = ref.watch(viewPreferencesProvider);
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
            secondary: const Icon(Icons.label_outlined),
            title: const Text('Show Card Labels'),
            subtitle: const Text('Display card names and numbers on grid view'),
            value: viewPrefs.showLabels,
            onChanged: (_) {
              ref.read(viewPreferencesProvider.notifier).toggleLabels();
            },
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
      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.displayName ?? 'User'),
            subtitle: Text(user.email ?? 'No email'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/profile/account'),
          ),
        ],
      );
    } else if (authState.isAnonymous) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You\'re using the app without an account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to save your collection, decks, and settings across devices.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/profile/register'),
                      child: const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/profile/login'),
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
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign in to your account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to save your collection, decks, and settings across devices.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/profile/login'),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/profile/register'),
                      child: const Text('Create Account'),
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
