import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../models/group.dart';
import 'widgets/confetti_overlay.dart';
import 'widgets/group_detail_header.dart';
import 'widgets/members_tab.dart';
import 'widgets/payouts_tab.dart';

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

  void _refresh({int? cycleNumber}) {
    ref.invalidate(groupDetailProvider(widget.groupId));
    ref.invalidate(membersProvider(widget.groupId));
    ref.invalidate(payoutsProvider(widget.groupId));
    ref.invalidate(myGroupsProvider);
    // Invalidate active payments for the given cycle and neighbors
    if (cycleNumber != null) {
      ref.invalidate(activePaymentsProvider(
          (groupId: widget.groupId, cycleNumber: cycleNumber)));
      ref.invalidate(activePaymentsProvider(
          (groupId: widget.groupId, cycleNumber: cycleNumber + 1)));
    }
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
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 16),
              Text('Failed to load group',
                  style: Theme.of(context).textTheme.titleMedium),
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

    final members = membersAsync.valueOrNull ?? [];
    final payments = paymentsAsync.valueOrNull ?? [];
    final paidCount = payments.length;
    final totalMembers = members.length;
    final progress = totalMembers > 0 ? paidCount / totalMembers : 0.0;

    return Column(
      children: [
        // ── Header ──
        GroupDetailHeader(
          groupId: widget.groupId,
          group: group,
          isOrganizer: isOrganizer,
          paidCount: paidCount,
          totalMembers: totalMembers,
          progress: progress,
          onRefresh: _refresh,
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
              MembersTab(
                groupId: widget.groupId,
                group: group,
                isOrganizer: isOrganizer,
                onRefresh: _refresh,
                onAllPaid: () {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    if (mounted) _tabController.animateTo(1);
                  });
                },
              ),
              PayoutsTab(
                groupId: widget.groupId,
                group: group,
                isOrganizer: isOrganizer,
                onRefresh: _refresh,
                onPayoutConfirmed: () {
                  if (mounted) {
                    ConfettiOverlay.show(context);
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (mounted) _tabController.animateTo(0);
                    });
                  }
                },
                onCycleComplete: () {
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
}
