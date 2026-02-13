import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../config/theme.dart';
import '../../../models/group.dart';

class SummaryCard extends StatelessWidget {
  final List<GroupWithStats> groups;
  const SummaryCard({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    final totalPot = groups.fold<double>(
        0, (sum, g) => sum + g.contributionAmount * g.memberCount);
    final totalMembers = groups.fold<int>(0, (sum, g) => sum + g.memberCount);
    final totalPaid =
        groups.fold<int>(0, (sum, g) => sum + (g.memberCount - g.pendingCount));
    final totalPending = totalMembers - totalPaid;
    final symbol = groups.isNotEmpty ? groups.first.currencySymbol : '£';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B2B26), Color(0xFF163D34)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: GlassContainer(
        useOwnLayer: true,
        settings: const LiquidGlassSettings(
          thickness: 0.5,
          blur: 6.0,
          glassColor: Color(0x18FFFFFF),
        ),
        shape: const LiquidRoundedSuperellipse(borderRadius: 22),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL POT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$symbol${_formatAmount(totalPot)}',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'across ${groups.length} ${groups.length == 1 ? 'group' : 'groups'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _SummaryStat(
                icon: Icons.check_circle_outline_rounded,
                label: 'Paid',
                value: '$totalPaid/$totalMembers',
                color: AppColors.accent,
              ),
              const SizedBox(width: 20),
              _SummaryStat(
                icon: Icons.schedule_rounded,
                label: 'Pending',
                value: '$totalPending',
                color: totalPending > 0
                    ? const Color(0xFFFFB74D)
                    : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 20),
              _SummaryStat(
                icon: Icons.loop_rounded,
                label: 'Cycle',
                value: groups.length == 1
                    ? '${groups.first.currentCycle}'
                    : groups.map((g) => g.currentCycle).join(', '),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  static String _formatAmount(double amount) {
    if (amount >= 1000) {
      final formatted =
          (amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1);
      return '${formatted}k';
    }
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }
}

class _SummaryStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$value ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}
