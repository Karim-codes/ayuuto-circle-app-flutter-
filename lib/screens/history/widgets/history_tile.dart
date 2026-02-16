import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import 'history_item.dart';

class HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const HistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isContribution = item.type == HistoryType.contribution;
    final isPayout = item.type == HistoryType.payout;
    final isMine = item.isCurrentUser;
    final isMyPayout = isPayout && isMine;
    final isMyContribution = isContribution && isMine;
    final color = isContribution ? const Color(0xFFFF6B6B) : AppColors.accent;
    final dateStr = DateFormat('d MMM, h:mm a').format(item.date.toLocal());
    final amtStr = item.amount.toStringAsFixed(
        item.amount == item.amount.roundToDouble() ? 0 : 2);

    // Title text
    String title;
    if (isMyContribution) {
      title = 'Contribution';
    } else if (isContribution) {
      title = '${item.recipientName ?? 'Unknown'} contributed';
    } else if (isMyPayout) {
      title = 'Payout Received';
    } else {
      title = 'Payout to ${item.recipientName ?? 'Unknown'}';
    }

    // Highlight color for current user items
    final isHighlighted = isMyPayout || isMyContribution;
    final highlightColor = isMyPayout ? AppColors.accent : const Color(0xFFFF6B6B);

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? highlightColor.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? highlightColor.withValues(alpha: 0.2)
              : AppColors.divider,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isHighlighted ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isContribution
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isHighlighted
                              ? highlightColor
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: highlightColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: highlightColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.groupName} · Cycle ${item.cycleNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Amount + date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isContribution ? '-' : '+'}${item.currencySymbol}$amtStr',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
