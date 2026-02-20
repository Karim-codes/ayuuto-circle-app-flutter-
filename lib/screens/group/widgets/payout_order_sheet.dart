import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/member.dart';
import '../../../providers/providers.dart';

class PayoutOrderSheet extends ConsumerStatefulWidget {
  final String groupId;
  final List<Member> members;

  const PayoutOrderSheet({
    super.key,
    required this.groupId,
    required this.members,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String groupId,
    required List<Member> members,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PayoutOrderSheet(groupId: groupId, members: members),
    );
  }

  @override
  ConsumerState<PayoutOrderSheet> createState() => _PayoutOrderSheetState();
}

class _PayoutOrderSheetState extends ConsumerState<PayoutOrderSheet> {
  late List<Member> _ordered;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ordered = List.of(widget.members)
      ..sort((a, b) => a.payoutPosition.compareTo(b.payoutPosition));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final order = <({String memberId, int position})>[];
      for (var i = 0; i < _ordered.length; i++) {
        order.add((memberId: _ordered[i].id, position: i + 1));
      }
      await ref.read(groupServiceProvider).updatePayoutOrder(order);
      ref.invalidate(membersProvider(widget.groupId));
      ref.invalidate(myGroupsProvider);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).get('error')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(bottom: bottomPad + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title + subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.get('payout_order_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.get('payout_order_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reorderable list
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ordered.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _ordered.removeAt(oldIndex);
                  _ordered.insert(newIndex, item);
                });
              },
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final scale = 1.0 + 0.02 * animation.value;
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        elevation: 6 * animation.value,
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.transparent,
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final member = _ordered[index];
                final isNext = !member.hasReceivedPayout &&
                    _ordered
                        .take(index)
                        .every((m) => m.hasReceivedPayout);

                return _OrderTile(
                  key: ValueKey(member.id),
                  position: index + 1,
                  member: member,
                  isNext: isNext,
                );
              },
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(t.get('save_order')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Order Tile ──────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  final int position;
  final Member member;
  final bool isNext;

  const _OrderTile({
    super.key,
    required this.position,
    required this.member,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasReceived = member.hasReceivedPayout;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isNext
            ? AppColors.accent.withValues(alpha: 0.06)
            : hasReceived
                ? AppColors.success.withValues(alpha: 0.04)
                : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext
              ? AppColors.accent.withValues(alpha: 0.3)
              : hasReceived
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : hasReceived
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: hasReceived
                  ? Icon(Icons.check_rounded,
                      size: 16, color: AppColors.success)
                  : Text(
                      '$position',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isNext
                            ? AppColors.accent
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
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.get('next_up'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasReceived)
                  Text(
                    t.get('received_payout'),
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Drag handle
          if (!hasReceived)
            Icon(
              Icons.drag_handle_rounded,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
              size: 22,
            ),
        ],
      ),
    );
  }
}
