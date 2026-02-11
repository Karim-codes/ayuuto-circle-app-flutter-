import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

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
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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

                  // Title
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Avatar + Name + Email
                  profileAsync.when(
                    data: (profile) {
                      final initial = (profile?.fullName.isNotEmpty == true)
                          ? profile!.fullName[0].toUpperCase()
                          : '?';
                      final memberSince = profile?.createdAt != null
                          ? 'Member since ${DateFormat('MMM yyyy').format(profile!.createdAt)}'
                          : '';

                      return Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  Color(0xFF1A4A7A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            profile?.fullName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (memberSince.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              memberSince,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 120),
                    error: (e, st) => const SizedBox(height: 120),
                  ),
                  const SizedBox(height: 32),

                  // GENERAL section
                  _SectionLabel(label: 'GENERAL'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline,
                        iconBg: const Color(0xFF3B82F6),
                        title: 'Edit Profile',
                        subtitle: 'Update your personal information',
                        onTap: _showEditNameSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // SUBSCRIPTION section
                  _SectionLabel(label: 'SUBSCRIPTION'),
                  const SizedBox(height: 8),
                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();
                      return _MenuGroup(
                        items: [
                          _MenuItem(
                            icon: profile.isPremium
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            iconBg: profile.isPremium
                                ? AppColors.accent
                                : const Color(0xFF9CA3AF),
                            title: profile.isPremium ? 'Premium Plan' : 'Free Plan',
                            subtitle: profile.isPremium
                                ? 'Unlimited groups & members'
                                : '1 group, max 7 members',
                            trailing: profile.isFoundingMember &&
                                    profile.foundingMemberNumber != null
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '#${profile.foundingMemberNumber}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),

                  // SUPPORT section
                  _SectionLabel(label: 'SUPPORT'),
                  const SizedBox(height: 8),
                  _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.info_outline,
                        iconBg: const Color(0xFF6366F1),
                        title: 'About',
                        subtitle: 'App information and version',
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'AyuutoCircle',
                            applicationVersion: '1.0.0',
                            children: [
                              const Text(
                                'A non-custodial digital ledger for managing Somali Ayuuto rotating savings groups.',
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Sign out
                  _MenuGroup(
                    items: [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        iconBg: AppColors.error,
                        title: 'Sign Out',
                        titleColor: AppColors.error,
                        onTap: _signOut,
                        showChevron: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Version
                  Center(
                    child: Text(
                      'AyuutoCircle v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

// ── Section Label ────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ── Menu Group (card with list of items) ─────────────────

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 60),
                child: Divider(height: 0.5, color: AppColors.divider),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Menu Item ────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconBg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
              if (showChevron)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
