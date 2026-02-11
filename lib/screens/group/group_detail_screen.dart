import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../models/member.dart';
import '../../models/payout.dart';
import '../../models/group.dart';

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
    final membersAsync = ref.watch(membersProvider(widget.groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: groupAsync.when(
        data: (group) => _buildContent(context, group, membersAsync),
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

  Widget _buildContent(
      BuildContext context, Group group, AsyncValue<List<Member>> membersAsync) {
    final isOrganizer =
        ref.watch(currentUserProvider)?.id == group.organizerId;

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          pinned: true,
          expandedHeight: 240,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            if (isOrganizer)
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => context.push('/group/${widget.groupId}/invite'),
              ),
            if (isOrganizer)
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'reset') {
                    final confirm = await _showConfirmDialog(
                      context,
                      'Reset Round',
                      'This will reset all payout statuses and start a new cycle. Continue?',
                    );
                    if (confirm == true) {
                      await ref
                          .read(groupServiceProvider)
                          .advanceCycle(widget.groupId);
                      _refresh();
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text('New Round'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _HeaderChip(
                            icon: Icons.payments_outlined,
                            label:
                                '${group.currencySymbol}${group.contributionAmount.toStringAsFixed(group.contributionAmount == group.contributionAmount.roundToDouble() ? 0 : 2)}',
                          ),
                          const SizedBox(width: 8),
                          _HeaderChip(
                            icon: Icons.schedule,
                            label: group.frequencyLabel,
                          ),
                          const SizedBox(width: 8),
                          _HeaderChip(
                            icon: Icons.refresh,
                            label: 'Cycle ${group.currentCycle}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: const [
              Tab(text: 'Members'),
              Tab(text: 'Payouts'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          _MembersTab(
            groupId: widget.groupId,
            group: group,
            isOrganizer: isOrganizer,
            onRefresh: _refresh,
          ),
          _PayoutsTab(
            groupId: widget.groupId,
            group: group,
            isOrganizer: isOrganizer,
            onRefresh: _refresh,
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Members Tab ───────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final String groupId;
  final Group group;
  final bool isOrganizer;
  final VoidCallback onRefresh;

  const _MembersTab({
    required this.groupId,
    required this.group,
    required this.isOrganizer,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersProvider(groupId));
    final paymentsAsync = ref.watch(activePaymentsProvider(
        (groupId: groupId, cycleNumber: group.currentCycle)));

    return membersAsync.when(
      data: (members) {
        final payments = paymentsAsync.valueOrNull ?? [];
        final paidMemberIds =
            payments.map((p) => p.memberId).toSet();

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(membersProvider(groupId));
            ref.invalidate(activePaymentsProvider(
                (groupId: groupId, cycleNumber: group.currentCycle)));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final hasPaid = paidMemberIds.contains(member.id);

              return _MemberPaymentTile(
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _MemberPaymentTile extends StatelessWidget {
  final Member member;
  final Group group;
  final bool hasPaid;
  final bool isOrganizer;
  final VoidCallback? onToggle;

  const _MemberPaymentTile({
    required this.member,
    required this.group,
    required this.hasPaid,
    required this.isOrganizer,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasPaid
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                // Position badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: member.hasReceivedPayout
                        ? AppColors.accent.withValues(alpha: 0.12)
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
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (member.isOrganiser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
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
                            : '${group.currencySymbol}${group.contributionAmount.toStringAsFixed(group.contributionAmount == group.contributionAmount.roundToDouble() ? 0 : 2)} per cycle',
                        style: TextStyle(
                          fontSize: 12,
                          color: member.hasReceivedPayout
                              ? AppColors.accent
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Payment status
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasPaid
                        ? AppColors.success
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasPaid ? Icons.check : Icons.remove,
                    color: hasPaid ? Colors.white : AppColors.textTertiary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
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

  const _PayoutsTab({
    required this.groupId,
    required this.group,
    required this.isOrganizer,
    required this.onRefresh,
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
            padding: const EdgeInsets.all(16),
            children: [
              // Next payout card
              if (!isRoundComplete && nextRecipient != null)
                _NextPayoutCard(
                  recipient: nextRecipient,
                  group: group,
                  totalPot: totalPot,
                  allPaid: allPaid,
                  isOrganizer: isOrganizer,
                  onConfirm: () => _confirmPayout(
                    ref,
                    context,
                    nextRecipient,
                    totalPot,
                  ),
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

              const SizedBox(height: 20),

              // Payout history
              if (payouts.isNotEmpty) ...[
                const Text(
                  'Payout History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
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
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: AppColors.textTertiary.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No payouts yet this round',
                        style: Theme.of(context).textTheme.bodyMedium,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Payout'),
        content: Text(
          'Confirm ${group.currencySymbol}${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)} payout to ${recipient.name}?\n\nThis will void all current payments and mark ${recipient.name} as having received their payout.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm Payout'),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payout confirmed for ${recipient.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

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
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Payout',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipient.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${group.currencySymbol}${totalPot.toStringAsFixed(totalPot == totalPot.roundToDouble() ? 0 : 2)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (isOrganizer)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: allPaid ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white38,
                  disabledForegroundColor: Colors.white60,
                ),
                child: Text(
                  allPaid ? 'Confirm Payout' : 'Waiting for all payments...',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_outlined,
              size: 48, color: AppColors.success),
          const SizedBox(height: 12),
          const Text(
            'Round Complete!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All members have received their payout.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onNewRound,
              child: const Text('Start New Round'),
            ),
          ],
        ],
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
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
                    style: const TextStyle(
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
