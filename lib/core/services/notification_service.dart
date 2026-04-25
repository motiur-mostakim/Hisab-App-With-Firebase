import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// গুরুত্বপূর্ণ: এটি একটি top-level function হতে হবে
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) async {
  if (details.actionId == 'again_action') {
    // ব্যাকগ্রাউন্ডে টাইমজোন ইনিশিয়ালাইজেশন নিশ্চিত করা
    tz_data.initializeTimeZones();
    
    // ২০ সেকেন্ড পর আবার অ্যালার্ম বাজার জন্য সময় সেট করা
    final nextTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20));

    // ব্যাকগ্রাউন্ডে সরাসরি প্লাগইন ব্যবহার করে সিডিউল করা
    final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
    
    await plugin.zonedSchedule(
      details.id ?? 0,
      "Reminder Again",
      "আবার মনে করিয়ে দিচ্ছি 😄",
      nextTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_alarm_channel_v8', // নতুন চ্যানেল আইডি
          'নোট অ্যালার্ম',
          channelDescription: 'নোট রিমাইন্ডার অ্যালার্মের জন্য চ্যানেল',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          enableVibration: true,
          fullScreenIntent: true, 
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'again_action',
              'Remind Later',
              showsUserInterface: false, // এটি অবশ্যই false হতে হবে ব্যাকগ্রাউন্ডের জন্য
            ),
            AndroidNotificationAction(
              'cancel_action',
              'Dismiss',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        final actionId = details.actionId;

        // অ্যাপ ওপেন থাকা অবস্থায় অ্যাকশন হ্যান্ডেল করা
        if (actionId == 'again_action') {
          final nextTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20));
          await scheduleNotification(
            details.id ?? 0,
            "Reminder Again",
            "আবার মনে করিয়ে দিচ্ছি 😄",
            nextTime,
          );
        }

        if (actionId == 'cancel_action') {
          await cancelNotification(details.id ?? 0);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleNotification(
      int id, String title, String body, DateTime scheduledDate) async {
    
    tz.TZDateTime tzScheduledDate;
    if (scheduledDate is tz.TZDateTime) {
      tzScheduledDate = scheduledDate;
    } else {
      tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
    }

    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'note_alarm_channel_v8', 
          'নোট অ্যালার্ম',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('alarm_sound'),
          enableVibration: true,
          fullScreenIntent: true, 
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'again_action',
              'Remind Later',
              showsUserInterface: false, // ব্যাকগ্রাউন্ডে কাজ করার জন্য false
            ),
            AndroidNotificationAction(
              'cancel_action',
              'Dismiss',
              showsUserInterface: false,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
