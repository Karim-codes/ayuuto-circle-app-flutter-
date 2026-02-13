import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/profile.dart';

class ProfileHeader extends StatelessWidget {
  final Profile? profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial = (profile?.fullName.isNotEmpty == true)
        ? profile!.fullName[0].toUpperCase()
        : '?';
    final memberSince = profile?.createdAt != null
        ? 'Joined ${DateFormat('MMMM yyyy').format(profile!.createdAt)}'
        : '';

    return Column(
      children: [
        const SizedBox(height: 8),
        // Large avatar with gradient ring
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accent,
                AppColors.accent.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B2B26), Color(0xFF1E5046)],
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          profile?.fullName ?? 'Unknown',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Email
        Text(
          profile?.email ?? '',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        // Member since
        if (memberSince.isNotEmpty)
          Text(
            memberSince,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}
