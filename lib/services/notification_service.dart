import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _kRemindersEnabledKey = 'reminders_enabled';
const _kReminderDayKey = 'reminder_day'; // 0=Mon..6=Sun
const _kReminderHourKey = 'reminder_hour';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    // iOS
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    return true;
  }

  // ── Preferences ──────────────────────────────────────────

  Future<bool> get remindersEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kRemindersEnabledKey) ?? false;
  }

  Future<int> get reminderDay async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReminderDayKey) ?? DateTime.monday; // default Monday
  }

  Future<int> get reminderHour async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kReminderHourKey) ?? 9; // default 9 AM
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRemindersEnabledKey, enabled);
    if (enabled) {
      await scheduleWeeklyReminder();
    } else {
      await cancelAll();
    }
  }

  Future<void> setReminderDay(int day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderDayKey, day);
    final enabled = await remindersEnabled;
    if (enabled) await scheduleWeeklyReminder();
  }

  Future<void> setReminderHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderHourKey, hour);
    final enabled = await remindersEnabled;
    if (enabled) await scheduleWeeklyReminder();
  }

  // ── Scheduling ───────────────────────────────────────────

  Future<void> scheduleWeeklyReminder() async {
    await init();
    await _plugin.cancelAll();

    final day = await reminderDay;
    final hour = await reminderHour;

    const androidDetails = AndroidNotificationDetails(
      'ayuuto_reminders',
      'Payment Reminders',
      channelDescription: 'Weekly reminders to make your Ayuuto contribution',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final scheduledDate = _nextInstanceOfDayAndHour(day, hour);

    await _plugin.zonedSchedule(
      0,
      'Ayuuto Reminder 💰',
      'Time to make your contribution! Open AyuutoCircle to check your circles.',
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  // ── Show instant notification (for testing) ──────────────

  Future<void> showTestNotification() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'ayuuto_reminders',
      'Payment Reminders',
      channelDescription: 'Weekly reminders to make your Ayuuto contribution',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(
      99,
      'Ayuuto Reminder 💰',
      'Time to make your contribution! Open AyuutoCircle to check your circles.',
      details,
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  tz.TZDateTime _nextInstanceOfDayAndHour(int day, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    // Find the next occurrence of the target day
    while (scheduled.weekday != day) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // If it's already past this week's slot, go to next week
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
