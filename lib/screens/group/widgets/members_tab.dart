import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../config/theme.dart';
import '../../../models/group.dart';
import '../../../models/member.dart';
import '../../../providers/providers.dart';

class MembersTab extends ConsumerWidget {
  final String groupId;
  final Group group;
  final bool isOrganizer;
  final VoidCallback onRefresh;
  final VoidCallback? onAllPaid;

  const MembersTab({
    super.key,
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
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }
}

// ── Member Tile ─────────────────────────────────────────

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

            // Glass checkmark toggle
            GestureDetector(
              onTap: isOrganizer ? onToggle : null,
              child: hasPaid
                  ? GlassContainer(
                      useOwnLayer: true,
                      settings: LiquidGlassSettings(
                        thickness: 0.6,
                        blur: 4.0,
                        glassColor: AppColors.success.withValues(alpha: 0.25),
                      ),
                      shape: const LiquidRoundedSuperellipse(borderRadius: 17),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 20, color: AppColors.success),
                      ),
                    )
                  : Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textTertiary.withValues(alpha: 0.25),
                          width: 1.5,
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
