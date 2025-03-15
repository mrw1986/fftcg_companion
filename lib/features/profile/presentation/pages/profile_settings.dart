import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileSettings extends ConsumerWidget {
  const ProfileSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/profile/theme'),
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
    );
  }
}
