import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/features/cards/presentation/providers/view_preferences_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewPrefs = ref.watch(viewPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        children: [
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
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement account settings
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
}
