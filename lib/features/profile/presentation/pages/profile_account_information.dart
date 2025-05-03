import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';

class ProfileAccountInformation extends ConsumerWidget {
  const ProfileAccountInformation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState =
        ref.watch(authNotifierProvider); // Use the new AsyncNotifierProvider
    final user = authState.user!;
    Theme.of(context);

    return Card(
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
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(user.email ?? 'No email'),
                  ),
                  if (authState
                      .isEmailNotVerifiedState) // Use the updated state property
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Unverified',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            if (!authState
                .isEmailNotVerifiedState) // Use the updated state property
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Account Type'),
                subtitle: Text(_getProviderName(user)),
              ),
          ],
        ),
      ),
    );
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
