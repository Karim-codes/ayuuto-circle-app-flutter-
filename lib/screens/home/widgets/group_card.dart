import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../models/group.dart';

class GroupCard extends StatelessWidget {
  final GroupWithStats group;
  const GroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final paidCount = group.memberCount - group.pendingCount;
    final progress = group.memberCount > 0
        ? paidCount / group.memberCount
        : 0.0;
    final pot = group.contributionAmount * group.memberCount;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => context.push('/group/${group.id}'),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent.withValues(alpha: 0.15),
                          AppColors.accent.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
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
                            Expanded(
                              child: Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.pendingRequestsCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${group.pendingRequestsCount} request${group.pendingRequestsCount > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${group.memberCount} members · ${group.frequencyLabel} · Cycle ${group.currentCycle}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pot amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${group.currencySymbol}${_formatPot(pot)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'pot',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: progress),
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              paidCount == group.memberCount &&
                                      group.memberCount > 0
                                  ? AppColors.success
                                  : AppColors.accent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (paidCount == group.memberCount && group.memberCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '$paidCount/${group.memberCount} paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatPot(double amount) {
    if (amount >= 1000) {
      final formatted = (amount / 1000).toStringAsFixed(
        amount % 1000 == 0 ? 0 : 1,
      );
      return '${formatted}k';
    }
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }
}
