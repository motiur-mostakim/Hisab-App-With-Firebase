import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../model/note_model.dart';

// Unique channel per sound is required for Android to play different sounds
NotificationDetails _getNotificationDetails(String soundName) {
  return NotificationDetails(
    android: AndroidNotificationDetails(
      'channel_$soundName', // Unique channel ID based on sound name
      soundName == 'sound_alarm' ? 'অ্যালার্ম' : 'নোট রিমাইন্ডার',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'again_action',
          'Remind Later',
          showsUserInterface: false,
        ),
        const AndroidNotificationAction(
          'cancel_action',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    ),
  );
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  if (details.actionId == 'again_action') {
    tz_data.initializeTimeZones();
    final nextTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 20));
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();

    final data = jsonDecode(details.payload ?? '{}');

    final String soundName = data['soundName']?.toString() ?? 'notification';

    await plugin.zonedSchedule(
      details.id ?? 0,
      "Reminder Again",
      "আবার মনে করিয়ে দিচ্ছি 😄",
      nextTime,
      _getNotificationDetails(soundName),
      payload: jsonEncode({'soundName': soundName}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() => _notificationService;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification({String? soundName}) async {
    tz_data.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        if (details.actionId == 'again_action') {
          final data = jsonDecode(details.payload ?? '{}');

          final soundName = data['soundName']?.toString() ?? 'notification';
          final nextTime = tz.TZDateTime.now(
            tz.local,
          ).add(const Duration(seconds: 20));
          await scheduleNotification(
            details.id ?? 0,
            "Reminder Again",
            "আবার মনে করিয়ে দিচ্ছি 😄",
            nextTime,
            soundName: soundName,
          );
        }
        if (details.actionId == 'cancel_action') {
          await cancelNotification(details.id ?? 0);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  Future<void> restoreAlarms(List<NoteModel> notes) async {
    for (var note in notes) {
      if (note.alarmTime != null) {
        await cancelNotification(note.id.hashCode);
        for (int i = 1; i <= 7; i++) {
          await cancelNotification(note.id.hashCode + i);
        }
        if (note.repeatDays == null || note.repeatDays!.isEmpty) {
          if (note.alarmTime!.isAfter(DateTime.now())) {
            await scheduleNotification(
              note.id.hashCode,
              "নোট: ${note.title}",
              note.content ?? "",
              note.alarmTime!,
              soundName: note.soundName ?? 'notification',
            );
          }
        } else {
          await scheduleWeeklyNotifications(
            note.id.hashCode,
            "নোট: ${note.title}",
            note.content ?? "",
            TimeOfDay.fromDateTime(note.alarmTime!),
            note.repeatDays!,
            soundName: note.soundName ?? 'notification',
          );
        }
      }
    }
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    String? soundName,
  }) async {
    tz.TZDateTime tzScheduledDate = scheduledDate is tz.TZDateTime
        ? scheduledDate
        : tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      _getNotificationDetails(soundName ?? 'notification'),
      payload: jsonEncode({'soundName': soundName ?? 'notification'}),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleWeeklyNotifications(
    int id,
    String title,
    String body,
    TimeOfDay time,
    List<int> days, {
    String? soundName,
  }) async {
    final int baseId = id.abs();

    for (int day in days) {
      int uniqueId = baseId + day;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        uniqueId,
        title,
        body,
        _nextInstanceOfDayAndTime(day, time),
        _getNotificationDetails(soundName ?? 'notification'),
        payload: jsonEncode({'soundName': soundName ?? 'notification'}),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int day, TimeOfDay time) {
    final DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return tz.TZDateTime.from(scheduledDate, tz.local);
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
