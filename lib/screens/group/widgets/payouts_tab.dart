import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../models/group.dart';
import '../../../models/member.dart';
import '../../../models/payout.dart';
import '../../../providers/providers.dart';
import 'confirm_dialog.dart';

class PayoutsTab extends ConsumerWidget {
  final String groupId;
  final Group group;
  final bool isOrganizer;
  final VoidCallback onRefresh;
  final VoidCallback? onPayoutConfirmed;
  final VoidCallback? onCycleComplete;

  const PayoutsTab({
    super.key,
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
                _PayoutsEmptyState(),
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
    final amtText = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    final confirm = await showConfirmDialog(
      context,
      'Confirm Payout',
      'Confirm ${group.currencySymbol}$amtText payout to ${recipient.name}?\n\nThis will void all current payments and mark ${recipient.name} as received.',
    );

    if (confirm != true) return;

    try {
      final currentCycle = group.currentCycle;
      await ref.read(groupServiceProvider).confirmPayout(
            groupId: groupId,
            cycleNumber: currentCycle,
            recipientMemberId: recipient.id,
            amount: amount,
          );
      // Invalidate payments for current and next cycle so ticks reset
      ref.invalidate(activePaymentsProvider(
          (groupId: groupId, cycleNumber: currentCycle)));
      ref.invalidate(activePaymentsProvider(
          (groupId: groupId, cycleNumber: currentCycle + 1)));
      onRefresh();

      // Check if this was the last payout (cycle complete)
      final service = ref.read(groupServiceProvider);
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
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Next Payout Card ────────────────────────────────────

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
    final potText = totalPot == totalPot.roundToDouble()
        ? totalPot.toStringAsFixed(0)
        : totalPot.toStringAsFixed(2);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2B26), Color(0xFF163D34)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                      '${group.currencySymbol}$potText',
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
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
              height: 50,
              child: ElevatedButton(
                onPressed: allPaid ? onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      Colors.white.withValues(alpha: 0.12),
                  disabledForegroundColor:
                      Colors.white.withValues(alpha: 0.4),
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
      ),
    );
  }
}

// ── Round Complete Card ─────────────────────────────────

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
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.2)),
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
            style:
                TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (isOrganizer) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
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

// ── Payout History Tile ─────────────────────────────────

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
    final amtText = payout.amount == payout.amount.roundToDouble()
        ? payout.amount.toStringAsFixed(0)
        : payout.amount.toStringAsFixed(2);

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
              '$currencySymbol$amtText',
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

// ── Empty State ─────────────────────────────────────────

class _PayoutsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
