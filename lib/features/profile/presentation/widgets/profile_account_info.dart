import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';

/// Widget for displaying account information including email and verification status
class ProfileAccountInfo extends ConsumerWidget {
  const ProfileAccountInfo({
    super.key,
    required this.user,
    required this.emailController,
    required this.onUpdateEmail,
    required this.onSendVerificationEmail,
    required this.isLoading,
    required this.showChangeEmail,
    required this.onToggleChangeEmail,
  });

  final User? user;
  final TextEditingController emailController;
  final VoidCallback onUpdateEmail;
  final VoidCallback onSendVerificationEmail;
  final bool isLoading;
  final bool showChangeEmail;
  final VoidCallback onToggleChangeEmail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    final authState = ref.watch(authStateProvider);
    final isEmailVerified = !authState.isEmailNotVerified;
    final providers = user!.providerData.map((e) => e.providerId).toList();
    final hasPassword = providers.contains('password');

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

            // Email with verification status
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email'),
              subtitle: Text(
                user!.email ?? 'No email',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: user!.email != null &&
                      !user!.isAnonymous &&
                      isEmailVerified &&
                      hasPassword
                  ? TextButton(
                      onPressed: onToggleChangeEmail,
                      child: Text(showChangeEmail ? 'Cancel' : 'Change',
                          style: const TextStyle(color: Colors.green)),
                    )
                  : null,
            ),

            if (showChangeEmail) ...[
              const SizedBox(height: 16),
              ProfileEmailUpdate(
                emailController: emailController,
                onUpdateEmail: onUpdateEmail,
                isLoading: isLoading,
                user: user,
              ),
            ],

            // Verification status for email/password users
            if (!isEmailVerified && hasPassword)
              _buildVerificationActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verification status is being checked automatically. '
              'Please check your email and click the verification link.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.left,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined, size: 16),
            label: const Text('Verify'),
            onPressed: onSendVerificationEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(80, 32),
            ),
          ),
        ],
      ),
    );
  }
}
