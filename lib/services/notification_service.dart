import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../journal_pages/create_journal.dart';
import 'navigationservice.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notification settings
  Future<void> initNotifications() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Combine platform settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse notificationResponse) {
    // Handle notification tap if needed
    if (NavigationService.navigatorKey.currentState != null) {
      NavigationService.navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => CreateJournal(), // Your create journal page
        ),
      );
    } else {
      debugPrint('Unable to navigate: Navigator context not available');
    }
  }

  // Schedule notifications based on user settings
  Future<void> scheduleNotifications() async {
    // Cancel existing notifications first
    await flutterLocalNotificationsPlugin.cancelAll();

    // Get notification settings
    final prefs = await SharedPreferences.getInstance();
    final bool notificationsEnabled =
        prefs.getBool('notifications_enabled') ?? true;
    final int frequency = prefs.getInt('notification_frequency') ?? 1;
    final List<String> selectedTimes =
        prefs.getStringList('notification_times') ?? ['18:00'];

    // If notifications are disabled, return
    if (!notificationsEnabled) return;

    // Schedule notifications for each selected time
    for (int i = 0; i < selectedTimes.length; i++) {
      // Limit to specified frequency
      if (i >= frequency) break;

      // Parse the time
      final timeParts = selectedTimes[i].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      await _scheduleDaily(
        id: i,
        hour: hour,
        minute: minute,
        title: 'Journal Reminder',
        body: 'Take a moment to reflect and write in your journal today.',
      );
    }
  }

  // Schedule a daily notification at a specific time
  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_journal_channel',
            'Daily Journal Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Notification scheduled at $hour:$minute');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Calculate next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
