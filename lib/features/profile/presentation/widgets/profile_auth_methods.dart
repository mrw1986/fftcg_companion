import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/shared/utils/snackbar_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget for displaying and managing authentication methods
class ProfileAuthMethods extends ConsumerWidget {
  const ProfileAuthMethods({
    super.key,
    required this.user,
    required this.onUnlinkProvider,
    required this.onLinkWithGoogle,
    required this.onLinkWithEmailPassword,
    required this.onShowLinkEmailPasswordDialog,
    this.showChangeEmail = false,
    required this.onToggleChangeEmail,
    required this.isEmailNotVerified,
  });

  final User? user;
  final Function(String) onUnlinkProvider;
  final Future<void> Function() onLinkWithGoogle;
  final Function(String, String) onLinkWithEmailPassword;
  final VoidCallback onShowLinkEmailPasswordDialog;
  final bool showChangeEmail;
  final VoidCallback onToggleChangeEmail;
  final bool isEmailNotVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    final authState = ref.watch(authStateProvider);
    final isEmailVerified = !authState.isEmailNotVerified;
    final providers = user!.providerData.map((e) => e.providerId).toList();
    final hasPassword = providers.contains('password');
    final hasGoogle = providers.contains('google.com');
    final colorScheme = Theme.of(context).colorScheme;

    // Get Google account info if available
    UserInfo? googleProvider;
    try {
      googleProvider = user!.providerData.firstWhere(
        (element) => element.providerId == 'google.com',
      );
    } catch (_) {
      // No Google provider found
      googleProvider = null;
    }

    final String? googleEmail = googleProvider?.email;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Authentication Methods section with proper alignment
          if (hasPassword || hasGoogle) ...[
            // Email/Password method
            if (hasPassword)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.password_outlined,
                          color: colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email/Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (isEmailNotVerified)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
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
                      ),
                      if (user!.email != null &&
                          !user!.isAnonymous &&
                          !isEmailNotVerified &&
                          hasPassword)
                        TextButton.icon(
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
                        ),
                      if (providers.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.link_off,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Unlink Email/Password',
                          onPressed: () => onUnlinkProvider('password'),
                        ),
                    ],
                  ),
                ),
              ),

            // Google method
            if (hasGoogle)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/images/google_branding/signin-assets/android_dark_rd_na.svg'
                            : 'assets/images/google_branding/signin-assets/android_neutral_rd_na.svg',
                        height: 36,
                        width: 36,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            if (googleEmail != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Signed in as $googleEmail',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (providers.length > 1)
                        IconButton(
                          icon: Icon(
                            Icons.link_off,
                            color: colorScheme.primary,
                          ),
                          tooltip: 'Unlink Google',
                          onPressed: () => onUnlinkProvider('google.com'),
                        ),
                    ],
                  ),
                ),
              ),
          ],

          // Add authentication methods section - only show if there are methods to add
          if (!hasPassword && isEmailVerified || !hasGoogle) ...[
            const SizedBox(height: 8),

            // Add Email/Password
            if (!hasPassword && isEmailVerified)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.password_outlined,
                      color: colorScheme.onSecondaryContainer,
                      size: 20,
                    ),
                  ),
                  title: const Text('Add Email/Password'),
                  subtitle: const Text('Set a password for your account'),
                  trailing: Icon(
                    Icons.add_circle_outline,
                    color: colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: onShowLinkEmailPasswordDialog,
                ),
              ),

            // Add Google
            if (!hasGoogle)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  leading: SvgPicture.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/google_branding/signin-assets/android_dark_rd_na.svg'
                        : 'assets/images/google_branding/signin-assets/android_neutral_rd_na.svg',
                    height: 36,
                    width: 36,
                  ),
                  title: const Text('Add Google'),
                  subtitle: const Text('Link your Google account'),
                  trailing: Icon(
                    Icons.add_circle_outline,
                    color: colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    // Store the current context
                    final currentContext = context;

                    onLinkWithGoogle().catchError((e) {
                      // Check if the widget is still mounted before using the context
                      if (currentContext.mounted) {
                        SnackBarHelper.showErrorSnackBar(
                          context: currentContext,
                          message: 'Error linking Google: ${e.toString()}',
                        );
                      }
                    });
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }
}
