import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Removed Riverpod import
import 'package:go_router/go_router.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/profile_auth_methods.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/link_email_password_dialog.dart';
// Removed auth_provider import

// Reverted to StatelessWidget
class AccountInfoCard extends StatelessWidget {
  final User? user; // Use user prop passed from parent
  final bool isEmailNotVerified;
  final TextEditingController emailController;
  final bool showChangeEmail;
  final Function() onToggleChangeEmail;
  final Function() onUpdateEmail;
  final Function(String) onUnlinkProvider;
  final Future<void> Function() onLinkWithGoogle;
  final Function(String, String) onLinkWithEmailPassword;
  final VoidCallback onChangePassword;
  final bool isLoading;

  const AccountInfoCard({
    super.key,
    required this.user, // Expect user from parent
    required this.isEmailNotVerified,
    required this.emailController,
    required this.showChangeEmail,
    required this.onToggleChangeEmail,
    required this.onUpdateEmail,
    required this.onUnlinkProvider,
    required this.onLinkWithGoogle,
    required this.onLinkWithEmailPassword,
    required this.onChangePassword,
    required this.isLoading,
  });

  // Reverted dialog showing logic to use the passed user prop
  void _showLinkEmailPasswordDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initialEmailValue = user?.email; // Use email from user prop

    talker.debug(
        'AccountInfoCard: Showing LinkEmailPasswordDialog. User email from prop: $initialEmailValue');

    showDialog(
      context: context,
      builder: (context) => LinkEmailPasswordDialog(
        initialEmail: initialEmailValue, // Pass the email from user prop
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Email/password authentication added successfully',
                style: TextStyle(color: colorScheme.onPrimary),
              ),
              backgroundColor: colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed WidgetRef
    // Use the user passed via constructor
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

            if (showChangeEmail) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ProfileEmailUpdate(
                  emailController: emailController,
                  onUpdateEmail: onUpdateEmail,
                  isLoading: isLoading,
                ),
              ),
              const SizedBox(height: 16),
            ],

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
              user: user, // Pass the user from props
              onUnlinkProvider: onUnlinkProvider,
              onLinkWithGoogle: onLinkWithGoogle,
              onLinkWithEmailPassword: onLinkWithEmailPassword,
              // Pass the class method as the callback
              onShowLinkEmailPasswordDialog: () =>
                  _showLinkEmailPasswordDialog(context), // No ref needed
              showChangeEmail: showChangeEmail,
              onToggleChangeEmail: onToggleChangeEmail,
              isEmailNotVerified: isEmailNotVerified,
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
                onTap: () {
                  talker.debug(
                      'Reset Password tapped, navigating to /profile/reset-password');
                  context.push('/profile/reset-password');
                },
              ),
            ],

            // Change password option for password users
            if (!user!.isAnonymous && hasPassword) ...[
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Change Password'),
                subtitle: const Text('Update your account password'),
                leading: Icon(
                  Icons.key_outlined,
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
                onTap: onChangePassword,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
