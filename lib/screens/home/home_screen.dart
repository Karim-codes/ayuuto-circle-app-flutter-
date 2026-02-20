import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import 'widgets/summary_card.dart';
import 'widgets/group_card.dart';
import 'widgets/home_empty_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final profileAsync = ref.watch(profileProvider);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(myGroupsProvider);
            ref.invalidate(profileProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileAsync.when(
                        data: (profile) => Text(
                          '${_greeting(t)}, ${profile?.fullName.split(' ').first ?? 'there'}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        loading: () => Text(
                          '${_greeting(t)} ${_greetingEmoji()}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        error: (e, st) => Text(
                          '${_greeting(t)} ${_greetingEmoji()}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.get('your_circles'),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary card
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(height: 16),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: SummaryCard(groups: groups),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ),

              // Action buttons
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.add_circle_outline,
                              label: t.get('new_circle'),
                              onTap: () => context.push('/create-group'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.link,
                              label: t.get('join_circle'),
                              onTap: () => context.push('/join'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Tip banner
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final totalPaid = groups.fold<int>(
                    0,
                    (sum, g) => sum + (g.memberCount - g.pendingCount),
                  );
                  final totalMembers = groups.fold<int>(
                    0,
                    (sum, g) => sum + g.memberCount,
                  );
                  if (totalPaid >= totalMembers && totalMembers > 0) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _TipBanner(),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Section label
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            t.get('active_circles'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${groups.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Groups list
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverFillRemaining(child: HomeEmptyState());
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GroupCard(group: groups[index]),
                        );
                      }, childCount: groups.length),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.get('failed_to_load_groups'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(myGroupsProvider),
                          child: Text(t.get('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick insights section — fills empty space
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  final totalPot = groups.fold<double>(
                    0,
                    (sum, g) => sum + g.contributionAmount * g.memberCount,
                  );
                  final symbol = groups.isNotEmpty
                      ? groups.first.currencySymbol
                      : '£';
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            t.get('quick_insights'),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _InsightTile(
                                  icon: Icons.groups_rounded,
                                  label: t.get('circles'),
                                  value: '${groups.length}',
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InsightTile(
                                  icon: Icons.account_balance_wallet_rounded,
                                  label: t.get('total_pot'),
                                  value: '$symbol${_fmtCompact(totalPot)}',
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InsightTile(
                                  icon: Icons.people_rounded,
                                  label: t.get('members'),
                                  value:
                                      '${groups.fold<int>(0, (s, g) => s + g.memberCount)}',
                                  color: AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // Latest Activity section — last 3 transactions
              groupsAsync.when(
                data: (groups) {
                  if (groups.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }
                  return _LatestActivitySection();
                },
                loading: () =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (e, st) =>
                    const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  static String _greeting(AppLocalizations t) {
    final hour = DateTime.now().hour;
    if (hour < 12) return t.get('good_morning');
    if (hour < 17) return t.get('good_afternoon');
    return t.get('good_evening');
  }

  static String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '🌙';
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    if (hour < 20) return '🌆';
    return '🌙';
  }

  static String _fmtCompact(double amount) {
    if (amount >= 1000) {
      final v = amount / 1000;
      return '${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1)}k';
    }
    return amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }
}

// ── Action Button ────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        useOwnLayer: true,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Insight Tile ─────────────────────────────────────────

class _InsightTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InsightTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Latest Activity Section ──────────────────────────────

class _LatestActivitySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final historyAsync = ref.watch(userHistoryProvider);

    return historyAsync.when(
      data: (data) {
        final payments = (data['payments'] as List?) ?? [];
        final payouts = (data['payouts'] as List?) ?? [];

        final items = <_ActivityData>[];

        final seen = <String>{};
        for (final p in payments) {
          final key = '${p['member_id']}_${p['group_id']}_${p['cycle_number']}';
          if (seen.contains(key)) continue;
          seen.add(key);
          final group = p['groups'] as Map<String, dynamic>?;
          items.add(
            _ActivityData(
              isPayout: false,
              groupName: group?['name'] as String? ?? 'Unknown',
              amount: (p['amount'] as num).toDouble(),
              currency: group?['currency'] as String? ?? 'GBP',
              date: DateTime.parse(p['created_at'] as String),
            ),
          );
        }

        for (final po in payouts) {
          final group = po['groups'] as Map<String, dynamic>?;
          items.add(
            _ActivityData(
              isPayout: true,
              groupName: group?['name'] as String? ?? 'Unknown',
              amount: (po['amount'] as num).toDouble(),
              currency: group?['currency'] as String? ?? 'GBP',
              date: DateTime.parse(po['created_at'] as String),
            ),
          );
        }

        items.sort((a, b) => b.date.compareTo(a.date));

        if (items.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final display = items.take(3).toList();

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.get('latest_activity'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                ...display.map((item) => _ActivityRow(item: item)),
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to History tab (index 1)
                        final shell = StatefulNavigationShell.of(context);
                        shell.goBranch(1);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            t.get('show_more'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
      ),
      error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _ActivityData {
  final bool isPayout;
  final String groupName;
  final double amount;
  final String currency;
  final DateTime date;

  _ActivityData({
    required this.isPayout,
    required this.groupName,
    required this.amount,
    required this.currency,
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

class _ActivityRow extends StatelessWidget {
  final _ActivityData item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = item.isPayout ? AppColors.accent : const Color(0xFFFF6B6B);
    final label = item.isPayout ? t.get('payout_received') : t.get('contribution');
    final timeStr = _timeAgo(item.date);
    final amountStr =
        '${item.isPayout ? '+' : '-'}${item.currencySymbol}${item.amount == item.amount.roundToDouble() ? item.amount.toStringAsFixed(0) : item.amount.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.isPayout
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${item.groupName} · $timeStr',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM').format(date);
  }
}

class _TipBanner extends StatefulWidget {
  const _TipBanner();

  @override
  State<_TipBanner> createState() => _TipBannerState();
}

class _TipBannerState extends State<_TipBanner>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true; // defaulting to true until prefs load
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _checkDismissed();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('tip_dismissed') == true) {
      if (mounted) setState(() => _isVisible = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _isVisible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tip_dismissed', true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Opacity(
                opacity: 0.6 + _pulseCtrl.value * 0.4,
                child: child,
              );
            },
            child: Icon(
              Icons.lightbulb_outline_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context).get('tip_share_code'),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _dismiss,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
