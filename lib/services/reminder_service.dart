import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clock/clock.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class ReminderService {
  static const _keyEnabled = 'reminder_enabled';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';
  static const _keyLastSnooze = 'reminder_last_snooze';

  final FlutterLocalNotificationsPlugin _plugin;

  ReminderService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(settings: InitializationSettings(android: androidSettings));
  }

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  Future<(int, int)> get scheduledTime async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getInt(_keyHour) ?? 16, prefs.getInt(_keyMinute) ?? 0);
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    if (!enabled) {
      await _plugin.cancelAll();
      await prefs.remove(_keyLastSnooze);
    }
  }

  Future<void> setTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
    if (await isEnabled) {
      await _scheduleDaily(hour, minute);
    }
  }

  Future<void> _scheduleDaily(int hour, int minute) async {
    await _plugin.zonedSchedule(
      id: 0,
      title: 'Habit Constellation',
      body: 'The sky is clear tonight.',
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Habit Reminders',
          channelDescription: 'Evening habit reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: [
            AndroidNotificationAction('snooze', 'Later'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> snooze() async {
    final now = clock.now();
    if (now.hour >= 23) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSnooze = prefs.getString(_keyLastSnooze);
    final last = lastSnooze != null ? DateTime.tryParse(lastSnooze) : null;

    final scheduledTime = now.add(const Duration(hours: 1));
    if (last != null && scheduledTime.difference(last).inMinutes < 50) return;

    await prefs.setString(_keyLastSnooze, scheduledTime.toIso8601String());

    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);
    await _plugin.zonedSchedule(
      id: 1,
      title: 'Habit Constellation',
      body: 'The sky is clear tonight.',
      scheduledDate: tzScheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          'Habit Reminders',
          channelDescription: 'Evening habit reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          actions: [
            AndroidNotificationAction('snooze', 'Later'),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> onNotificationTapped(String? payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastSnooze);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = clock.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduled, tz.local);
  }
}
