import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// Removed Riverpod import
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/profile_auth_methods.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/link_email_password_dialog.dart';
// Removed auth_provider import
// Removed incorrect UnverifiedChip import

// Reverted to StatelessWidget
class AccountInfoCard extends StatelessWidget {
  final User? user; // Use user prop passed from parent
  final bool isEmailNotVerified;
  final String? pendingEmail; // NEW: Add pending email parameter
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
    this.pendingEmail, // NEW: Make pendingEmail optional
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

  // Updated dialog showing logic to check providerData for email
  void _showLinkEmailPasswordDialog(BuildContext context) {
    String? initialEmailValue = user?.email; // Try primary email first

    // If primary email is null/empty, try finding the Google provider email
    if ((initialEmailValue == null || initialEmailValue.isEmpty) &&
        user != null) {
      try {
        final googleProvider = user!.providerData.firstWhere(
          (userInfo) => userInfo.providerId == 'google.com',
        );
        initialEmailValue = googleProvider.email;
        talker.debug(
            'AccountInfoCard: Primary email null/empty, using Google provider email: $initialEmailValue');
      } catch (_) {
        // No Google provider found or it doesn't have an email
        talker.debug(
            'AccountInfoCard: Primary email null/empty, no Google provider email found.');
      }
    }

    talker.debug(
        'AccountInfoCard: Showing LinkEmailPasswordDialog with initial email: $initialEmailValue');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LinkEmailPasswordDialog(
        initialEmail: initialEmailValue, // Pass the potentially found email
        onSuccess:
            () {}, // Empty callback since we show the message in the dialog
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Removed WidgetRef
    // Use the user passed via constructor
    if (user == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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

            // NEW: Display Pending Email if present
            if (pendingEmail != null) ...[
              ListTile(
                leading: Icon(Icons.hourglass_top_rounded,
                    color: colorScheme.secondary),
                title: Text(pendingEmail!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                subtitle: const Text('Pending Verification'),
                // Use a standard Chip widget
                trailing: Chip(
                  label: Text('Unverified', style: textTheme.labelSmall),
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle:
                      TextStyle(color: colorScheme.onSecondaryContainer),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide.none,
                ),
                dense: true,
              ),
              const SizedBox(height: 8),
            ],

            if (showChangeEmail) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ProfileEmailUpdate(
                  emailController: emailController,
                  onUpdateEmail: onUpdateEmail,
                  isLoading: isLoading,
                  user: user,
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

            // Reset password option removed - Authenticated users should use "Change Password"
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
