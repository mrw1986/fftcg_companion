import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fftcg_companion/features/profile/presentation/pages/profile_display_name.dart'
    as display_name;

/// Widget for displaying the profile header with avatar and display name
class ProfileAccountHeader extends ConsumerWidget {
  const ProfileAccountHeader({
    super.key,
    required this.displayNameController,
    required this.onUpdateProfile,
    required this.isLoading,
  });

  final TextEditingController displayNameController;
  final Future<void> Function() onUpdateProfile;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
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
