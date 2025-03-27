import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_display_name.dart'
    as display_name;

class ProfileHeaderCard extends StatelessWidget {
  final User? user;
  final TextEditingController displayNameController;
  final Function() onUpdateProfile;
  final bool isLoading;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.displayNameController,
    required this.onUpdateProfile,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar with gradient background
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.7),
                    colorScheme.secondary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.surface,
                child: Icon(
                  Icons.person,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Display name with animation
            display_name.ProfileDisplayName(
              displayNameController: displayNameController,
              onUpdateProfile: onUpdateProfile,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
