import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart' hide Priority;
import '../models/reminder.dart';
import '../models/habit.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open DAY FLOW');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );
  }

  static Future<bool> requestPermissions() async {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final grantedNotif = await androidImpl.requestNotificationsPermission();
      final grantedExact = await androidImpl.requestExactAlarmsPermission();
      return (grantedNotif ?? false) && (grantedExact ?? false);
    }
    return true;
  }

  static Future<void> scheduleTaskReminder(Task task, Reminder reminder) async {
    try {
      final fireDateTime = DateTime.parse(reminder.fireAt);
      if (fireDateTime.isBefore(DateTime.now())) return;

      final int notificationId = (task.id + reminder.id).hashCode.abs() % 100000;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'day_flow_alarms_v2',
        'DAY FLOW Alarms & Reminders',
        channelDescription: 'High priority full-screen alarms & lockscreen notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      final scheduledTz = tz.TZDateTime.from(fireDateTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '⏰ ALARM: ${task.title}',
        task.description.isNotEmpty ? task.description : 'Task due at ${task.dueTime}',
        scheduledTz,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (habit.reminderTime == null || !habit.reminderEnabled) return;
    try {
      final parts = habit.reminderTime!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final int notificationId = ('habit_${habit.id}').hashCode.abs() % 100000;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'day_flow_habits_v1',
        'DAY FLOW Daily Habit Alarms',
        channelDescription: 'High priority daily habit ringing alarms & reminders',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

      final now = DateTime.now();
      var scheduledTz = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduledTz.isBefore(now)) {
        scheduledTz = scheduledTz.add(const Duration(days: 1));
      }

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '⚡ HABIT ALARM: ${habit.name}',
        'Time to complete your habit! Goal: ${habit.targetQuantity}',
        scheduledTz,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  static Future<void> cancelReminder(String taskId, String reminderId) async {
    final int notificationId = (taskId + reminderId).hashCode.abs() % 100000;
    await _notificationsPlugin.cancel(notificationId);
  }

  static Future<void> cancelHabitReminder(String habitId) async {
    final int notificationId = ('habit_$habitId').hashCode.abs() % 100000;
    await _notificationsPlugin.cancel(notificationId);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
