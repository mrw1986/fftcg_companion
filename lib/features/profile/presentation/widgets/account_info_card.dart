import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/profile_auth_methods.dart';

class AccountInfoCard extends StatelessWidget {
  final User? user;
  final bool isEmailNotVerified;
  final TextEditingController emailController;
  final bool showChangeEmail;
  final Function() onToggleChangeEmail;
  final Function() onUpdateEmail;
  final Function(String) onUnlinkProvider;
  final Future<void> Function() onLinkWithGoogle;
  final Function(String, String) onLinkWithEmailPassword;
  final bool isLoading;

  const AccountInfoCard({
    super.key,
    required this.user,
    required this.isEmailNotVerified,
    required this.emailController,
    required this.showChangeEmail,
    required this.onToggleChangeEmail,
    required this.onUpdateEmail,
    required this.onUnlinkProvider,
    required this.onLinkWithGoogle,
    required this.onLinkWithEmailPassword,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final providers = user!.providerData.map((e) => e.providerId).toList();
    final hasPassword = providers.contains('password');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with icon
            Row(
              children: [
                Icon(
                  Icons.account_circle_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Email with verification status
            ListTile(
              leading: Icon(
                Icons.email_outlined,
                color: colorScheme.secondary,
              ),
              title: const Text('Email'),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      user!.email ?? 'No email',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isEmailNotVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Unverified',
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: user!.email != null &&
                      !user!.isAnonymous &&
                      !isEmailNotVerified &&
                      hasPassword
                  ? TextButton.icon(
                      onPressed: onToggleChangeEmail,
                      icon: Icon(
                        showChangeEmail ? Icons.close : Icons.edit,
                        size: 16,
                      ),
                      label: Text(
                        showChangeEmail ? 'Cancel' : 'Change',
                        style: TextStyle(
                          color: colorScheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    )
                  : null,
            ),

            if (showChangeEmail) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ProfileEmailUpdate(
                  emailController: emailController,
                  onUpdateEmail: onUpdateEmail,
                  isLoading: isLoading,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Authentication Methods section
            Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Authentication Methods',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Use ProfileAuthMethods for authentication methods
            ProfileAuthMethods(
              user: user,
              onUnlinkProvider: onUnlinkProvider,
              onLinkWithGoogle: onLinkWithGoogle,
              onLinkWithEmailPassword: onLinkWithEmailPassword,
              onShowLinkEmailPasswordDialog: onToggleChangeEmail,
            ),

            // Reset password option for password users
            if (!user!.isAnonymous && hasPassword) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Reset Password'),
                subtitle: const Text('Send a password reset email'),
                leading: Icon(
                  Icons.lock_reset_outlined,
                  color: colorScheme.tertiary,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () =>
                    Navigator.of(context).pushNamed('/profile/reset-password'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
