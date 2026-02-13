import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import 'widgets/history_item.dart';
import 'widgets/history_stat_card.dart';
import 'widgets/history_tile.dart';
import 'widgets/history_empty_state.dart';

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
                  final items = <HistoryItem>[];

                  // Add non-voided payments as contributions
                  for (final p in payments) {
                    if (p['voided_at'] != null) continue;
                    final group = p['groups'] as Map<String, dynamic>?;
                    final currency =
                        group?['currency'] as String? ?? 'GBP';
                    items.add(HistoryItem(
                      type: HistoryType.contribution,
                      groupName:
                          group?['name'] as String? ?? 'Unknown',
                      amount: (p['amount'] as num).toDouble(),
                      currency: currency,
                      cycleNumber: p['cycle_number'] as int? ?? 0,
                      date:
                          DateTime.parse(p['created_at'] as String),
                    ));
                  }

                  // Add payouts received
                  for (final po in payouts) {
                    final group =
                        po['groups'] as Map<String, dynamic>?;
                    final currency =
                        group?['currency'] as String? ?? 'GBP';
                    items.add(HistoryItem(
                      type: HistoryType.payout,
                      groupName:
                          group?['name'] as String? ?? 'Unknown',
                      amount: (po['amount'] as num).toDouble(),
                      currency: currency,
                      cycleNumber:
                          po['cycle_number'] as int? ?? 0,
                      date: DateTime.parse(
                          po['created_at'] as String),
                    ));
                  }

                  // Sort by date descending
                  items.sort((a, b) => b.date.compareTo(a.date));

                  if (items.isEmpty) {
                    return const SliverFillRemaining(
                        child: HistoryEmptyState());
                  }

                  // Calculate totals
                  final totalContributed = items
                      .where(
                          (i) => i.type == HistoryType.contribution)
                      .fold<double>(0, (sum, i) => sum + i.amount);
                  final totalReceived = items
                      .where((i) => i.type == HistoryType.payout)
                      .fold<double>(0, (sum, i) => sum + i.amount);
                  final mainSymbol = items.isNotEmpty
                      ? items.first.currencySymbol
                      : '£';

                  // Group items by month
                  final grouped = <String, List<HistoryItem>>{};
                  for (final item in items) {
                    final key =
                        DateFormat('MMMM yyyy').format(item.date);
                    grouped.putIfAbsent(key, () => []).add(item);
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Summary cards
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: HistoryStatCard(
                                label: 'Contributed',
                                amount:
                                    '$mainSymbol${_formatAmount(totalContributed)}',
                                icon: Icons.arrow_upward_rounded,
                                color: const Color(0xFFFF6B6B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: HistoryStatCard(
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
                              padding: const EdgeInsets.fromLTRB(
                                  20, 8, 20, 10),
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
                                  padding:
                                      const EdgeInsets.fromLTRB(
                                          20, 0, 20, 8),
                                  child: HistoryTile(item: item),
                                )),
                          ]),
                      const SizedBox(height: 100),
                    ]),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium),
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
