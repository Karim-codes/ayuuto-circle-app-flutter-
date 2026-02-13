import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import 'widgets/profile_header.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ensureProfile();
  }

  Future<void> _ensureProfile() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).getProfile();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/sign-in');
  }

  void _showEditNameSheet() {
    final profileAsync = ref.read(profileProvider);
    final currentName = profileAsync.valueOrNull?.fullName ?? '';
    final controller = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 100,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit Name',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Your full name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(authServiceProvider)
                        .updateProfile(fullName: name);
                    ref.invalidate(profileProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Name updated'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 16),

                  // Avatar + name + email
                  profileAsync.when(
                    data: (profile) => ProfileHeader(profile: profile),
                    loading: () => const SizedBox(height: 160),
                    error: (e, st) => const SizedBox(height: 160),
                  ),
                  const SizedBox(height: 28),

                  // Plan banner
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();
                      final isPremium = profile.isPremium;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isPremium
                                ? [const Color(0xFF0B2B26), const Color(0xFF1E5046)]
                                : [const Color(0xFFF0F7F5), const Color(0xFFE8F5F0)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isPremium
                                    ? AppColors.accent.withValues(alpha: 0.2)
                                    : AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPremium ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: AppColors.accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isPremium ? 'Premium Plan' : 'Free Plan',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isPremium ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isPremium
                                        ? 'Unlimited circles & members'
                                        : '1 circle · max 7 members',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isPremium
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (profile.isFoundingMember &&
                                profile.foundingMemberNumber != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Founder #${profile.foundingMemberNumber}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isPremium ? AppColors.accent : AppColors.accent,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // Menu items — each as its own tappable row
                  _ProfileMenuItem(
                    icon: Icons.edit_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Edit Name',
                    onTap: _showEditNameSheet,
                  ),
                  _ProfileMenuItem(
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'About AyuutoCircle',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Sign out
                  _ProfileMenuItem(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    title: 'Sign Out',
                    titleColor: AppColors.error,
                    showChevron: false,
                    onTap: _signOut,
                  ),
                  const SizedBox(height: 32),

                  // Version
                  Center(
                    child: Text(
                      'AyuutoCircle v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}

// ── Profile Menu Item ────────────────────────────────────

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback? onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.showChevron = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                if (showChevron)
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
