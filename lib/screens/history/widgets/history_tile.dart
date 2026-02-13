import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../config/theme.dart';
import 'history_item.dart';

class HistoryTile extends StatelessWidget {
  final HistoryItem item;
  const HistoryTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isContribution = item.type == HistoryType.contribution;
    final color = isContribution ? const Color(0xFFFF6B6B) : AppColors.accent;
    final dateStr = DateFormat('d MMM, h:mm a').format(item.date.toLocal());

    return GlassCard(
      useOwnLayer: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                Text(
                  isContribution ? 'Contribution' : 'Payout Received',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
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
                '${isContribution ? '-' : '+'}${item.currencySymbol}${item.amount.toStringAsFixed(item.amount == item.amount.roundToDouble() ? 0 : 2)}',
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
