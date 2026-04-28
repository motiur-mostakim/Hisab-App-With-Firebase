import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  if (details.actionId == 'again_action') {
    tz_data.initializeTimeZones();
    final nextTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20));
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    
    await plugin.zonedSchedule(
      details.id ?? 0,
      "Reminder Again",
      "আবার মনে করিয়ে দিচ্ছি 😄",
      nextTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_alarm_channel_v9',
          'নোট অ্যালার্ম',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          fullScreenIntent: true, 
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('again_action', 'Remind Later', showsUserInterface: false),
            AndroidNotificationAction('cancel_action', 'Dismiss', showsUserInterface: false, cancelNotification: true),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

class NotificationService {
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() => _notificationService;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.actionId == 'again_action') {
          final nextTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20));
          await scheduleNotification(details.id ?? 0, "Reminder Again", "আবার মনে করিয়ে দিচ্ছি 😄", nextTime);
        }
        if (details.actionId == 'cancel_action') await cancelNotification(details.id ?? 0);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime scheduledDate) async {
    // local DateTime থেকে TZDateTime এ রূপান্তর (সঠিক মুহূর্ত নিশ্চিত করতে)
    tz.TZDateTime tzScheduledDate = scheduledDate is tz.TZDateTime ? scheduledDate : tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id, title, body, tzScheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleWeeklyNotifications(int id, String title, String body, TimeOfDay time, List<int> days) async {
    final int baseId = id.abs();
    
    for (int day in days) {
      int uniqueId = baseId + day;
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        uniqueId,
        title,
        body,
        _nextInstanceOfDayAndTime(day, time),
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, TimeOfDay time) {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduledDate, tz.local);
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'note_alarm_channel_v9',
        'নোট অ্যালার্ম',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('again_action', 'Remind Later', showsUserInterface: false),
          AndroidNotificationAction('cancel_action', 'Dismiss', showsUserInterface: false, cancelNotification: true),
        ],
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
