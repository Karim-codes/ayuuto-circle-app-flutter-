import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/notification_service.dart';

class RemindersSheet extends StatefulWidget {
  const RemindersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RemindersSheet(),
    );
  }

  @override
  State<RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<RemindersSheet> {
  final _notif = NotificationService();
  bool _enabled = false;
  int _day = DateTime.monday;
  int _hour = 9;
  bool _loading = true;

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _dayNamesSo = [
    'Isniin',
    'Talaado',
    'Arbaco',
    'Khamiis',
    'Jimce',
    'Sabti',
    'Axad',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _notif.init();
    final enabled = await _notif.remindersEnabled;
    final day = await _notif.reminderDay;
    final hour = await _notif.reminderHour;
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _day = day;
        _hour = hour;
        _loading = false;
      });
    }
  }

  Future<void> _toggleEnabled(bool value) async {
    setState(() => _enabled = value);
    if (value) {
      final granted = await _notif.requestPermission();
      if (!granted) {
        setState(() => _enabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification permission denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }
    await _notif.setRemindersEnabled(value);
  }

  Future<void> _changeDay(int day) async {
    setState(() => _day = day);
    await _notif.setReminderDay(day);
  }

  Future<void> _changeHour(int hour) async {
    setState(() => _hour = hour);
    await _notif.setReminderHour(hour);
  }

  Future<void> _testNotification() async {
    await _notif.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isSomali = t.languageCode == 'so';
    final days = isSomali ? _dayNamesSo : _dayNames;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: AppColors.accent, size: 24),
                const SizedBox(width: 10),
                Text(
                  isSomali ? 'Xusuusin' : 'Reminders',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isSomali
                  ? 'Hel xusuusin toddobaadlaha ah si aad lacagtaada u bixiso'
                  : 'Get weekly reminders to make your contribution',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          else ...[
            // Enable toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isSomali ? 'Shid xusuusinta' : 'Enable reminders',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _enabled,
                      activeTrackColor: AppColors.accent,
                      onChanged: _toggleEnabled,
                    ),
                  ],
                ),
              ),
            ),

            if (_enabled) ...[
              const SizedBox(height: 16),

              // Day picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSomali ? 'Maalinta' : 'Day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final dayValue = index + 1; // 1=Mon..7=Sun
                          final selected = dayValue == _day;
                          return GestureDetector(
                            onTap: () => _changeDay(dayValue),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent
                                    : AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                days[index].substring(0, 3),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Hour picker
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSomali ? 'Waqtiga' : 'Time',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: _hour, minute: 0),
                        );
                        if (picked != null) {
                          _changeHour(picked.hour);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 20, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Text(
                              _formatHour(_hour),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded,
                                size: 20, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Test button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.notifications_none_rounded,
                        size: 18),
                    label: Text(
                      isSomali ? 'Tijaabi xusuusinta' : 'Test notification',
                    ),
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    return '$h:00 $period';
  }
}
