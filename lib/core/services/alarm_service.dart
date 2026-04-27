import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../model/alarm_model.dart';
import 'notification_service.dart';

class AlarmService {
  static const String _storageKey = 'offline_alarms';
  final NotificationService _notificationService = NotificationService();

  Future<List<AlarmModel>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? alarmsJson = prefs.getString(_storageKey);
    if (alarmsJson == null) return [];

    final List<dynamic> decoded = json.decode(alarmsJson);
    return decoded.map((e) => AlarmModel.fromMap(e)).toList();
  }

  Future<void> saveAlarm(AlarmModel alarm) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((e) => e.id == alarm.id);

    if (index != -1) {
      alarms[index] = alarm;
    } else {
      alarms.add(alarm);
    }

    await _saveToPrefs(alarms);
    if (alarm.isActive) {
      await _scheduleAlarm(alarm);
    } else {
      await _cancelAlarm(alarm);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = await getAlarms();
    final alarm = alarms.firstWhere((e) => e.id == id);
    await _cancelAlarm(alarm);

    alarms.removeWhere((e) => e.id == id);
    await _saveToPrefs(alarms);
  }

  Future<void> toggleAlarm(String id) async {
    final alarms = await getAlarms();
    final index = alarms.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updatedAlarm = AlarmModel(
        id: alarms[index].id,
        label: alarms[index].label,
        dateTime: alarms[index].dateTime,
        repeatDays: alarms[index].repeatDays,
        isActive: !alarms[index].isActive,
      );
      alarms[index] = updatedAlarm;
      await _saveToPrefs(alarms);

      if (updatedAlarm.isActive) {
        await _scheduleAlarm(updatedAlarm);
      } else {
        await _cancelAlarm(updatedAlarm);
      }
    }
  }

  Future<void> _saveToPrefs(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(alarms.map((e) => e.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    final timeOfDay = TimeOfDay.fromDateTime(alarm.dateTime);
    if (alarm.repeatDays.isEmpty) {
      await _notificationService.scheduleNotification(
        alarm.id.hashCode,
        "অ্যালার্ম: ${alarm.label}",
        "আপনার সেট করা সময় হয়েছে",
        alarm.dateTime,
      );
    } else {
      await _notificationService.scheduleWeeklyNotifications(
        alarm.id.hashCode,
        "অ্যালার্ম: ${alarm.label}",
        "আপনার সেট করা সময় হয়েছে",
        timeOfDay,
        alarm.repeatDays,
      );
    }
  }

  Future<void> _cancelAlarm(AlarmModel alarm) async {
    await _notificationService.cancelNotification(alarm.id.hashCode);
    for (int i = 1; i <= 7; i++) {
      await _notificationService.cancelNotification(alarm.id.hashCode + i);
    }
  }
}
