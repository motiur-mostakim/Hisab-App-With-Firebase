import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';
import '../../src/features/notification_screen.dart';
import '../model/notification_model.dart';
import 'fcm_notification_services.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: message.notification?.title ?? 'No Title',
      body: message.notification?.body ?? 'No Body',
      timestamp: DateTime.now(),
    );

    await FcmNotificationServices().saveNotification(notification);
  }
}

class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseInAppMessaging _fiam = FirebaseInAppMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  final FcmNotificationServices _storage =
  FcmNotificationServices();

  Future<void> init() async {
    // 1. Request permission for push notifications
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Configure In-App Messaging
    // Ensure messages are NOT suppressed
    await _fiam.setMessagesSuppressed(false);
    // Enable automatic data collection (required for FIAM to work)
    await _fiam.setAutomaticDataCollectionEnabled(true);

    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    String? token = await _fcm.getToken();
    print("FCM TOKEN: $token");
    await _storage.saveToken(token);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("NEW TOKEN: $newToken");
      await _storage.saveToken(newToken);
    });

    await _fcm.subscribeToTopic("all_users");

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_channel',
      'FCM Notifications',
      importance: Importance.max,
    );

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;

      if (notification != null) {
        final model = NotificationModel(
          id: const Uuid().v4(),
          title: notification.title ?? '',
          body: notification.body ?? '',
          timestamp: DateTime.now(),
        );

        await _storage.saveNotification(model);

        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("Notification clicked");
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
        ),
      );
    });
  }

  /// Manually trigger a FIAM event
  Future<void> triggerInAppEvent(String eventName) async {
    await _fiam.triggerEvent(eventName);
    print("FIAM Event Triggered: $eventName");
  }
}
