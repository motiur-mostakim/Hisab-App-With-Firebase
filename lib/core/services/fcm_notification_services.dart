import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/notification_model.dart';

class FcmNotificationServices {
  static const String _notificationKey = "notifications";
  static const String _tokenKey = "fcm_token";

  Future<void> saveNotification(NotificationModel model) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing =
        prefs.getStringList(_notificationKey) ?? [];

    existing.add(jsonEncode(model.toMap()));
    await prefs.setStringList(_notificationKey, existing);
  }

  Future<List<NotificationModel>> getSavedNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String> data =
        prefs.getStringList(_notificationKey) ?? [];

    return data
        .map((e) => NotificationModel.fromMap(jsonDecode(e)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationKey);
  }

  Future<int> getNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_notificationKey) ?? [];
    return data.length;
  }

  Future<void> saveToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token ?? "");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}
