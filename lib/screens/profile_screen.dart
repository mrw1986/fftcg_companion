import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Import/Export'),
            onTap: () {
              Navigator.pushNamed(context, '/import_export');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Collection Statistics'),
            onTap: () {
              Navigator.pushNamed(context, '/statistics');
            },
          ),
        ],
      ),
    );
  }
}
