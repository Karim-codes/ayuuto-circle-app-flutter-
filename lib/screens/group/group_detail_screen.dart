import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../models/member.dart';
import '../../models/payout.dart';
import '../../models/group.dart';
import '../../widgets/confetti_overlay.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(groupDetailProvider(widget.groupId));
    ref.invalidate(membersProvider(widget.groupId));
    ref.invalidate(payoutsProvider(widget.groupId));
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: groupAsync.when(
        data: (group) => _buildContent(context, group),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('Failed to load group', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Group group) {
    final isOrganizer =
        ref.watch(currentUserProvider)?.id == group.organizerId;
    final membersAsync = ref.watch(membersProvider(widget.groupId));
    final paymentsAsync = ref.watch(activePaymentsProvider(
        (groupId: widget.groupId, cycleNumber: group.currentCycle)));

    // Compute stats for header
    final members = membersAsync.valueOrNull ?? [];
    final payments = paymentsAsync.valueOrNull ?? [];
    final paidCount = payments.length;
    final totalMembers = members.length;
    final progress = totalMembers > 0 ? paidCount / totalMembers : 0.0;
    final totalPot = group.contributionAmount * totalMembers;

    final percentText = totalMembers > 0
        ? '${(progress * 100).toInt()}%'
        : '0%';
    final potText =
        '${group.currencySymbol}${totalPot.toStringAsFixed(totalPot == totalPot.roundToDouble() ? 0 : 2)}';
    final contribText =
        '${group.currencySymbol}${group.contributionAmount.toStringAsFixed(group.contributionAmount == group.contributionAmount.roundToDouble() ? 0 : 2)}';
    final pendingCount = totalMembers - paidCount;

    return Column(
      children: [
        // ── Premium gradient header ──
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A2540), Color(0xFF0D3B66)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                        onPressed: () => context.go('/home'),
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
                        IconButton(
                          icon: const Icon(Icons.person_add_alt_1_outlined,
                              color: Colors.white, size: 22),
                          onPressed: () =>
                              context.push('/group/${widget.groupId}/invite'),
                        ),
                      if (isOrganizer)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded,
                              color: Colors.white),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          onSelected: (value) async {
                            if (value == 'reset') {
                              final confirm = await _showConfirmDialog(
                                context,
                                'New Round',
                                'Start a new cycle? This resets all payout statuses.',
                              );
                              if (confirm == true) {
                                await ref
                                    .read(groupServiceProvider)
                                    .advanceCycle(widget.groupId);
                                _refresh();
                              }
                            } else if (value == 'delete') {
                              final confirm = await _showConfirmDialog(
                                context,
                                'Delete Circle',
                                'Are you sure you want to permanently delete this circle? This action cannot be undone.',
                              );
                              if (confirm == true && context.mounted) {
                                try {
                                  await ref
                                      .read(groupServiceProvider)
                                      .deleteGroup(widget.groupId);
                                  ref.invalidate(myGroupsProvider);
                                  if (context.mounted) {
                                    context.go('/home');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete: $e'),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      size: 18, color: AppColors.textSecondary),
                                  SizedBox(width: 10),
                                  Text('New Round'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 18, color: AppColors.error),
                                  SizedBox(width: 10),
                                  Text('Delete Circle',
                                      style: TextStyle(color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      if (!isOrganizer) const SizedBox(width: 48),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Large progress ring + pot amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress ring
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: progress,
                          trackColor: Colors.white.withValues(alpha: 0.1),
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
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'COLLECTED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),

                    // Pot + details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          potText,
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
                                    color: Colors.white.withValues(alpha: 0.45),
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
                                    color: Colors.white.withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Stats row — frosted bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _HeaderStat(
                        value: '$paidCount',
                        label: 'Paid',
                        dotColor: AppColors.accent,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _HeaderStat(
                        value: '$pendingCount',
                        label: 'Pending',
                        dotColor: const Color(0xFFFFB020),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _HeaderStat(
                        value: '$totalMembers',
                        label: 'Members',
                        dotColor: const Color(0xFF60A5FA),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Segmented tab bar ──
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(3),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            labelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Members'),
              Tab(text: 'Payouts'),
            ],
          ),
        ),

        // ── Tab content ──
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MembersTab(
                groupId: widget.groupId,
                group: group,
                isOrganizer: isOrganizer,
                onRefresh: _refresh,
                onAllPaid: () {
                  // Auto-switch to Payouts tab
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (mounted) {
                      _tabController.animateTo(1);
                    }
                  });
                },
              ),
              _PayoutsTab(
                groupId: widget.groupId,
                group: group,
                isOrganizer: isOrganizer,
                onRefresh: _refresh,
                onPayoutConfirmed: () {
                  // Small confetti burst, then switch back to Members
                  if (mounted) {
                    ConfettiOverlay.show(context);
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (mounted) {
                        _tabController.animateTo(0);
                      }
                    });
                  }
                },
                onCycleComplete: () {
                  // Big confetti burst for cycle completion
                  if (mounted) {
                    ConfettiOverlay.show(context, isBig: true);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

// ── Header Stat ──────────────────────────────────────────

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
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

// ── Progress Ring ─────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}

// ── Members Tab ───────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final String groupId;
  final Group group;
  final bool isOrganizer;
  final VoidCallback onRefresh;
  final VoidCallback? onAllPaid;

  const _MembersTab({
    required this.groupId,
    required this.group,
    required this.isOrganizer,
    required this.onRefresh,
    this.onAllPaid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(groupId));
    final paymentsAsync = ref.watch(activePaymentsProvider(
        (groupId: groupId, cycleNumber: group.currentCycle)));

    return membersAsync.when(
      data: (members) {
        final payments = paymentsAsync.valueOrNull ?? [];
        final paidMemberIds = payments.map((p) => p.memberId).toSet();

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(membersProvider(groupId));
            ref.invalidate(activePaymentsProvider(
                (groupId: groupId, cycleNumber: group.currentCycle)));
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: members.length + (isOrganizer ? 1 : 0),
            itemBuilder: (context, index) {
              // Hint text at top for organizers
              if (index == 0 && isOrganizer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Tap the switch to mark payments',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final memberIndex = isOrganizer ? index - 1 : index;
              final member = members[memberIndex];
              final hasPaid = paidMemberIds.contains(member.id);

              return _MemberTile(
                member: member,
                group: group,
                hasPaid: hasPaid,
                isOrganizer: isOrganizer,
                onToggle: isOrganizer
                    ? () => _togglePayment(
                          ref,
                          context,
                          member,
                          hasPaid,
                          members.length,
                          paidMemberIds.length,
                        )
                    : null,
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _togglePayment(
    WidgetRef ref,
    BuildContext context,
    Member member,
    bool currentlyPaid,
    int totalMembers,
    int currentPaidCount,
  ) async {
    try {
      final service = ref.read(groupServiceProvider);
      if (currentlyPaid) {
        await service.markUnpaid(
          groupId: groupId,
          memberId: member.id,
          cycleNumber: group.currentCycle,
        );
      } else {
        await service.markPaid(
          groupId: groupId,
          memberId: member.id,
          cycleNumber: group.currentCycle,
          amount: group.contributionAmount,
        );
      }
      ref.invalidate(activePaymentsProvider(
          (groupId: groupId, cycleNumber: group.currentCycle)));
      ref.invalidate(myGroupsProvider);

      // Check if this toggle made everyone paid
      if (!currentlyPaid && currentPaidCount + 1 >= totalMembers) {
        onAllPaid?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Member Tile ───────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final Member member;
  final Group group;
  final bool hasPaid;
  final bool isOrganizer;
  final VoidCallback? onToggle;

  const _MemberTile({
    required this.member,
    required this.group,
    required this.hasPaid,
    required this.isOrganizer,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPaid
                ? AppColors.success.withValues(alpha: 0.35)
                : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            // Position number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: member.hasReceivedPayout
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : hasPaid
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${member.payoutPosition}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: member.hasReceivedPayout
                        ? AppColors.accent
                        : hasPaid
                            ? AppColors.success
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (member.isOrganiser) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'Organizer',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.hasReceivedPayout
                        ? 'Received payout'
                        : hasPaid
                            ? 'Paid this cycle'
                            : '${group.currencySymbol}${group.contributionAmount.toStringAsFixed(group.contributionAmount == group.contributionAmount.roundToDouble() ? 0 : 2)} per cycle',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: member.hasReceivedPayout || hasPaid
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: member.hasReceivedPayout
                          ? AppColors.accent
                          : hasPaid
                              ? AppColors.success
                              : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            // Toggle switch
            if (isOrganizer)
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: 52,
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: hasPaid ? AppColors.success : AppColors.divider,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment:
                        hasPaid ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: hasPaid
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: AppColors.success)
                          : null,
                    ),
                  ),
                ),
              )
            else
              // Read-only status for non-organizers
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasPaid
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: hasPaid ? AppColors.success : AppColors.textTertiary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Payouts Tab ───────────────────────────────────────────

class _PayoutsTab extends ConsumerWidget {
  final String groupId;
  final Group group;
  final bool isOrganizer;
  final VoidCallback onRefresh;
  final VoidCallback? onPayoutConfirmed;
  final VoidCallback? onCycleComplete;

  const _PayoutsTab({
    required this.groupId,
    required this.group,
    required this.isOrganizer,
    required this.onRefresh,
    this.onPayoutConfirmed,
    this.onCycleComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(groupId));
    final payoutsAsync = ref.watch(payoutsProvider(groupId));
    final paymentsAsync = ref.watch(activePaymentsProvider(
        (groupId: groupId, cycleNumber: group.currentCycle)));

    return membersAsync.when(
      data: (members) {
        final payouts = payoutsAsync.valueOrNull ?? [];
        final payments = paymentsAsync.valueOrNull ?? [];
        final service = ref.read(groupServiceProvider);
        final nextRecipient = service.getNextRecipient(members);
        final isRoundComplete = service.isRoundComplete(members);
        final allPaid = payments.length >= members.length;
        final totalPot = group.contributionAmount * members.length;

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(membersProvider(groupId));
            ref.invalidate(payoutsProvider(groupId));
            ref.invalidate(activePaymentsProvider(
                (groupId: groupId, cycleNumber: group.currentCycle)));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // Next payout card
              if (!isRoundComplete && nextRecipient != null)
                _NextPayoutCard(
                  recipient: nextRecipient,
                  group: group,
                  totalPot: totalPot,
                  allPaid: allPaid,
                  isOrganizer: isOrganizer,
                  onConfirm: () =>
                      _confirmPayout(ref, context, nextRecipient, totalPot),
                ),

              if (isRoundComplete)
                _RoundCompleteCard(
                  isOrganizer: isOrganizer,
                  onNewRound: () async {
                    await ref
                        .read(groupServiceProvider)
                        .advanceCycle(groupId);
                    onRefresh();
                  },
                ),

              if (payouts.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'PAYOUT HISTORY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                ...payouts.reversed.map((payout) {
                  final recipient = members
                      .where((m) => m.id == payout.recipientMemberId)
                      .firstOrNull;
                  return _PayoutHistoryTile(
                    payout: payout,
                    recipientName: recipient?.name ?? 'Unknown',
                    currencySymbol: group.currencySymbol,
                  );
                }),
              ],

              if (payouts.isEmpty && !isRoundComplete)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 28,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No payouts yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payouts will appear here once confirmed',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _confirmPayout(
    WidgetRef ref,
    BuildContext context,
    Member recipient,
    double amount,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Payout'),
        content: Text(
          'Confirm ${group.currencySymbol}${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)} payout to ${recipient.name}?\n\nThis will void all current payments and mark ${recipient.name} as received.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(groupServiceProvider).confirmPayout(
            groupId: groupId,
            cycleNumber: group.currentCycle,
            recipientMemberId: recipient.id,
            amount: amount,
          );
      onRefresh();

      // Check if this was the last payout (cycle complete)
      final service = ref.read(groupServiceProvider);
      // After refresh, re-check round completion
      // We need a small delay for providers to update
      await Future.delayed(const Duration(milliseconds: 300));
      final updatedMembers =
          ref.read(membersProvider(groupId)).valueOrNull ?? [];
      final isNowComplete = service.isRoundComplete(updatedMembers);

      if (isNowComplete) {
        onCycleComplete?.call();
      } else {
        onPayoutConfirmed?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Next Payout Card ─────────────────────────────────────

class _NextPayoutCard extends StatelessWidget {
  final Member recipient;
  final Group group;
  final double totalPot;
  final bool allPaid;
  final bool isOrganizer;
  final VoidCallback onConfirm;

  const _NextPayoutCard({
    required this.recipient,
    required this.group,
    required this.totalPot,
    required this.allPaid,
    required this.isOrganizer,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF143D6B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT PAYOUT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${group.currencySymbol}${totalPot.toStringAsFixed(totalPot == totalPot.roundToDouble() ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (!allPaid)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Collecting...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: allPaid ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.12),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  allPaid ? 'Confirm Payout' : 'Waiting for all payments',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Round Complete Card ──────────────────────────────────

class _RoundCompleteCard extends StatelessWidget {
  final bool isOrganizer;
  final VoidCallback onNewRound;

  const _RoundCompleteCard({
    required this.isOrganizer,
    required this.onNewRound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.celebration_rounded,
                size: 28, color: AppColors.success),
          ),
          const SizedBox(height: 14),
          const Text(
            'Round Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All members have received their payout.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onNewRound,
                child: const Text('Start New Round'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Payout History Tile ──────────────────────────────────

class _PayoutHistoryTile extends StatelessWidget {
  final Payout payout;
  final String recipientName;
  final String currencySymbol;

  const _PayoutHistoryTile({
    required this.payout,
    required this.recipientName,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Cycle ${payout.cycleNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currencySymbol${payout.amount.toStringAsFixed(payout.amount == payout.amount.roundToDouble() ? 0 : 2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
