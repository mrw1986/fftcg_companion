import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fftcg_companion/core/providers/auth_provider.dart';
import 'package:fftcg_companion/shared/widgets/google_sign_in_button.dart';
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
  });

  final User? user;
  final Function(String) onUnlinkProvider;
  final Future<void> Function() onLinkWithGoogle;
  final Function(String, String) onLinkWithEmailPassword;
  final VoidCallback onShowLinkEmailPasswordDialog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    final authState = ref.watch(authStateProvider);
    final isEmailVerified = !authState.isEmailNotVerified;
    final providers = user!.providerData.map((e) => e.providerId).toList();
    final hasPassword = providers.contains('password');
    final hasGoogle = providers.contains('google.com');

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authentication Methods section with proper alignment
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasPassword || hasGoogle) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.password_outlined),
                      const SizedBox(width: 12),
                      const Text(
                        'Email/Password',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (providers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.link_off),
                          tooltip: 'Unlink Email/Password',
                          onPressed: () => onUnlinkProvider('password'),
                        ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 36),
                    child: Text('Password authentication is enabled'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SvgPicture.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/images/google_branding/signin-assets/android_dark_rd_na.svg'
                            : 'assets/images/google_branding/signin-assets/android_neutral_rd_na.svg',
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Google',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (providers.length > 1)
                        IconButton(
                          icon: const Icon(Icons.link_off),
                          tooltip: 'Unlink Google',
                          onPressed: () => onUnlinkProvider('google.com'),
                        ),
                    ],
                  ),
                  if (googleEmail != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text('Signed in as $googleEmail'),
                    ),
                ],
              ],
            ),

            // Add authentication methods section - only show if there are methods to add
            if (!hasPassword && isEmailVerified || !hasGoogle) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Add Email/Password
              if (!hasPassword && isEmailVerified)
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Add Email/Password'),
                  subtitle: const Text('Set a password for your account'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: onShowLinkEmailPasswordDialog,
                ),

              // Add Google
              if (!hasGoogle)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GoogleSignInButton(
                    onPressed: onLinkWithGoogle,
                    onError: (e) {
                      SnackBarHelper.showErrorSnackBar(
                        context: context,
                        message: 'Error linking Google: ${e.toString()}',
                      );
                    },
                    text: 'Link with Google',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
