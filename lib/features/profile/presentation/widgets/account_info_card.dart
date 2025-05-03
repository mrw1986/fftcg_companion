import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/core/utils/logger.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_email_update.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/profile_auth_methods.dart';
import 'package:fftcg_companion/features/profile/presentation/widgets/link_email_password_dialog.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_provider.dart';
import 'package:fftcg_companion/features/profile/presentation/providers/email_update_completion_provider.dart';

// Convert back to ConsumerWidget
class AccountInfoCard extends ConsumerWidget {
  // Remove user parameter
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
    // Remove user parameter requirement
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
  void _showLinkEmailPasswordDialog(BuildContext context, User? user) {
    String? initialEmailValue = user?.email; // Try primary email first

    // If primary email is null/empty, try finding the Google provider email
    if ((initialEmailValue == null || initialEmailValue.isEmpty) &&
        user != null) {
      try {
        final googleProvider = user.providerData.firstWhere(
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth state and email update state
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    // Force rebuild when providers change
    ref.listen(emailUpdateCompletionProvider, (previous, next) {
      // The rebuild will happen automatically due to state changes
      talker.debug('AccountInfoCard: Email update completion state changed');
    });

    if (user == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final providers = user.providerData.map((e) => e.providerId).toList();
    final hasPassword = providers.contains('password');
    talker.debug(
        'AccountInfoCard build: User providers: $providers, hasPassword: $hasPassword, pendingEmail: $pendingEmail');

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: Divider(height: 24)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    talker.debug('Manual refresh requested');
                    try {
                      // Get current user before reload
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        // Store current email for comparison
                        final currentEmail = currentUser.email;

                        // Force user reload
                        await currentUser.reload();

                        // Get fresh user instance after reload
                        final reloadedUser = FirebaseAuth.instance.currentUser;
                        if (reloadedUser != null) {
                          talker.debug(
                              'User reloaded successfully. Current email: ${reloadedUser.email}');

                          // Check if email changed
                          if (reloadedUser.email != currentEmail) {
                            talker.info(
                                'Email change detected after reload. Old: $currentEmail, New: ${reloadedUser.email}');
                          }

                          // Invalidate providers
                          ref.invalidate(authNotifierProvider);
                          ref.invalidate(emailUpdateNotifierProvider);
                          ref.invalidate(emailUpdateCompletionProvider);
                          talker.debug(
                              'Providers invalidated after successful reload');
                        } else {
                          talker.warning(
                              'User is null after reload - session may have expired');
                        }
                      } else {
                        talker.warning('Cannot refresh - no current user');
                      }
                    } catch (e) {
                      talker.error('Error during manual refresh', e);
                      if (e.toString().contains('user-token-expired')) {
                        talker.warning('User token expired during refresh');
                      }
                    }
                  },
                  tooltip: 'Refresh Auth State',
                ),
              ],
            ),

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
              user: user, // Pass the user from provider state
              onUnlinkProvider: onUnlinkProvider,
              onLinkWithGoogle: onLinkWithGoogle,
              onLinkWithEmailPassword: onLinkWithEmailPassword,
              // Pass the class method as the callback, passing the user
              onShowLinkEmailPasswordDialog: () =>
                  _showLinkEmailPasswordDialog(context, user), // Pass user
              showChangeEmail: showChangeEmail,
              onToggleChangeEmail: onToggleChangeEmail,
              isEmailNotVerified: isEmailNotVerified,
            ),

            // Reset password option removed - Authenticated users should use "Change Password"
            // Change password option for password users
            if (!user.isAnonymous && hasPassword) ...[
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
