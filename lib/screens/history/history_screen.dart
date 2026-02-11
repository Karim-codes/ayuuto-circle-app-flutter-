import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async => ref.invalidate(userHistoryProvider),
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'History',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your contributions and payouts',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              historyAsync.when(
                data: (data) {
                  final payments = (data['payments'] as List?) ?? [];
                  final payouts = (data['payouts'] as List?) ?? [];

                  // Build combined timeline
                  final items = <_HistoryItem>[];

                  // Add non-voided payments as contributions
                  for (final p in payments) {
                    if (p['voided_at'] != null) continue;
                    final group = p['groups'] as Map<String, dynamic>?;
                    final currency = group?['currency'] as String? ?? 'GBP';
                    items.add(_HistoryItem(
                      type: _HistoryType.contribution,
                      groupName: group?['name'] as String? ?? 'Unknown',
                      amount: (p['amount'] as num).toDouble(),
                      currency: currency,
                      cycleNumber: p['cycle_number'] as int? ?? 0,
                      date: DateTime.parse(p['created_at'] as String),
                    ));
                  }

                  // Add payouts received
                  for (final po in payouts) {
                    final group = po['groups'] as Map<String, dynamic>?;
                    final currency = group?['currency'] as String? ?? 'GBP';
                    items.add(_HistoryItem(
                      type: _HistoryType.payout,
                      groupName: group?['name'] as String? ?? 'Unknown',
                      amount: (po['amount'] as num).toDouble(),
                      currency: currency,
                      cycleNumber: po['cycle_number'] as int? ?? 0,
                      date: DateTime.parse(po['created_at'] as String),
                    ));
                  }

                  // Sort by date descending
                  items.sort((a, b) => b.date.compareTo(a.date));

                  if (items.isEmpty) {
                    return SliverFillRemaining(child: _EmptyHistory());
                  }

                  // Calculate totals
                  final totalContributed = items
                      .where((i) => i.type == _HistoryType.contribution)
                      .fold<double>(0, (sum, i) => sum + i.amount);
                  final totalReceived = items
                      .where((i) => i.type == _HistoryType.payout)
                      .fold<double>(0, (sum, i) => sum + i.amount);
                  final mainSymbol =
                      items.isNotEmpty ? items.first.currencySymbol : '£';

                  // Group items by month
                  final grouped = <String, List<_HistoryItem>>{};
                  for (final item in items) {
                    final key = DateFormat('MMMM yyyy').format(item.date);
                    grouped.putIfAbsent(key, () => []).add(item);
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary cards
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Contributed',
                                amount:
                                    '$mainSymbol${_formatAmount(totalContributed)}',
                                icon: Icons.arrow_upward_rounded,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Received',
                                amount:
                                    '$mainSymbol${_formatAmount(totalReceived)}',
                                icon: Icons.arrow_downward_rounded,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Timeline grouped by month
                      ...grouped.entries.expand((entry) => [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 10),
                              child: Text(
                                entry.key.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            ...entry.value.map((item) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 8),
                                  child: _HistoryTile(item: item),
                                )),
                          ]),
                      const SizedBox(height: 100),
                    ]),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text('Failed to load history',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(userHistoryProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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

// ── Data Types ──────────────────────────────────────────

enum _HistoryType { contribution, payout }

class _HistoryItem {
  final _HistoryType type;
  final String groupName;
  final double amount;
  final String currency;
  final int cycleNumber;
  final DateTime date;

  _HistoryItem({
    required this.type,
    required this.groupName,
    required this.amount,
    required this.currency,
    required this.cycleNumber,
    required this.date,
  });

  String get currencySymbol {
    switch (currency) {
      case 'GBP':
        return '£';
      case 'USD':
        return '\$';
      case 'SOS':
        return 'Sh';
      default:
        return currency;
    }
  }
}

// ── Stat Card ───────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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

// ── History Tile ────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final _HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isContribution = item.type == _HistoryType.contribution;
    final color = isContribution ? const Color(0xFFFF6B6B) : AppColors.accent;
    final dateStr = DateFormat('d MMM, h:mm a').format(item.date.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
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

// ── Empty State ─────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No history yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your contributions and payouts\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
