import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/group.dart';
import '../../../providers/providers.dart';
import 'confirm_dialog.dart';
import 'payout_order_sheet.dart';
import 'progress_ring_painter.dart';

class GroupDetailHeader extends ConsumerWidget {
  final String groupId;
  final Group group;
  final bool isOrganizer;
  final int paidCount;
  final int totalMembers;
  final double progress;
  final VoidCallback onRefresh;

  const GroupDetailHeader({
    super.key,
    required this.groupId,
    required this.group,
    required this.isOrganizer,
    required this.paidCount,
    required this.totalMembers,
    required this.progress,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final collectedAmount = group.contributionAmount * paidCount;
    final percentText =
        totalMembers > 0 ? '${(progress * 100).toInt()}%' : '0%';
    final collectedText =
        '${group.currencySymbol}${_fmt(collectedAmount)}';
    final contribText =
        '${group.currencySymbol}${_fmt(group.contributionAmount)}';
    final pendingCount = totalMembers - paidCount;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2B26), Color(0xFF163D34)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.go('/home'),
                  ),
                  const Spacer(),
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (isOrganizer)
                    _GlassIconButton(
                      icon: Icons.person_add_alt_1_outlined,
                      onTap: () =>
                          context.push('/group/$groupId/invite'),
                    ),
                  if (isOrganizer)
                    const SizedBox(width: 8),
                  if (isOrganizer)
                    _OrganizerMenu(
                      groupId: groupId,
                      onRefresh: onRefresh,
                    ),
                  if (!isOrganizer) const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Large progress ring + divider + pot amount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Progress ring
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: ProgressRingPainter(
                        progress: progress,
                        trackColor: Colors.white.withValues(alpha: 0.12),
                        progressColor: AppColors.accent,
                        strokeWidth: 8,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              percentText,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'COLLECTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Vertical divider
                  Container(
                    width: 1,
                    height: 90,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),

                  const SizedBox(width: 24),

                  // Pot + details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collectedText,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'CYCLE POT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contribText,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  group.frequencyLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cycle ${group.currentCycle}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'of $totalMembers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats row — liquid glass bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassContainer(
              useOwnLayer: true,
              settings: LiquidGlassSettings(
                thickness: 0.6,
                blur: 8.0,
                glassColor: Colors.white.withValues(alpha: 0.1),
              ),
              shape: const LiquidRoundedSuperellipse(borderRadius: 14),
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  _HeaderStat(
                    value: '$paidCount',
                    label: t.get('paid'),
                    dotColor: AppColors.accent,
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _HeaderStat(
                    value: '$pendingCount',
                    label: t.get('pending'),
                    dotColor: const Color(0xFFFFB020),
                  ),
                  Container(
                    width: 1,
                    height: 32,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  _HeaderStat(
                    value: '$totalMembers',
                    label: t.get('members'),
                    dotColor: const Color(0xFF60A5FA),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

// ── Glass Icon Button ───────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        useOwnLayer: true,
        settings: const LiquidGlassSettings(
          thickness: 0.6,
          blur: 8.0,
          glassColor: Color(0x20FFFFFF),
        ),
        shape: const LiquidRoundedSuperellipse(borderRadius: 14),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ── Organizer Popup Menu ────────────────────────────────

class _OrganizerMenu extends ConsumerWidget {
  final String groupId;
  final VoidCallback onRefresh;

  const _OrganizerMenu({required this.groupId, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassContainer(
      useOwnLayer: true,
      settings: const LiquidGlassSettings(
        thickness: 0.6,
        blur: 8.0,
        glassColor: Color(0x20FFFFFF),
      ),
      shape: const LiquidRoundedSuperellipse(borderRadius: 14),
      padding: EdgeInsets.zero,
      child: IconButton(
        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
        onPressed: () => _showActionSheet(context, ref),
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 34),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                AppLocalizations.of(context).get('payout_order'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            // Payout Order option
            _SheetOption(
              icon: Icons.swap_vert_rounded,
              label: AppLocalizations.of(context).get('manage_order'),
              subtitle: AppLocalizations.of(context).get('payout_order_subtitle'),
              iconColor: const Color(0xFF6366F1),
              onTap: () async {
                Navigator.pop(ctx);
                final members = ref.read(membersProvider(groupId)).valueOrNull ?? [];
                final saved = await PayoutOrderSheet.show(
                  context,
                  groupId: groupId,
                  members: members,
                );
                if (saved == true) {
                  onRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).get('order_saved')),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            // New Round option
            _SheetOption(
              icon: Icons.refresh_rounded,
              label: AppLocalizations.of(context).get('new_round'),
              subtitle: AppLocalizations.of(context).get('new_round_confirm'),
              iconColor: AppColors.accent,
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showConfirmDialog(
                  context,
                  AppLocalizations.of(context).get('new_round'),
                  AppLocalizations.of(context).get('new_round_confirm'),
                );
                if (confirm == true) {
                  await ref.read(groupServiceProvider).advanceCycle(groupId);
                  onRefresh();
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            // Delete Circle option
            _SheetOption(
              icon: Icons.delete_outline_rounded,
              label: AppLocalizations.of(context).get('delete_circle'),
              subtitle: AppLocalizations.of(context).get('delete_circle_confirm'),
              iconColor: AppColors.error,
              labelColor: AppColors.error,
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await showConfirmDialog(
                  context,
                  AppLocalizations.of(context).get('delete_circle'),
                  AppLocalizations.of(context).get('delete_circle_confirm'),
                );
                if (confirm == true && context.mounted) {
                  try {
                    await ref
                        .read(groupServiceProvider)
                        .deleteGroup(groupId);
                    ref.invalidate(myGroupsProvider);
                    if (context.mounted) {
                      context.go('/home');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${AppLocalizations.of(context).get('failed_to_delete')}: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            // Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    AppLocalizations.of(context).get('cancel'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: labelColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Header Stat ─────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final Color dotColor;

  const _HeaderStat({
    required this.value,
    required this.label,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
