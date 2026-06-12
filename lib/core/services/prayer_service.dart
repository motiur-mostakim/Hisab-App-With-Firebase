import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/prayer_time_model.dart';
import 'notification_service.dart';

class PrayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  Stream<List<PrayerTimeModel>> getPrayerTimes() {
    return _firestore.collection('prayer_times').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PrayerTimeModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> updatePrayerTime(String id, String newTime) async {
    await _firestore.collection('prayer_times').doc(id).update({'time': newTime});
  }

  Future<void> toggleNotification(String id, bool isEnabled) async {
    await _firestore.collection('prayer_times').doc(id).update({'isNotificationEnabled': isEnabled});
  }

  void schedulePrayerNotifications(List<PrayerTimeModel> prayers) {
    for (var prayer in prayers) {
      if (prayer.isNotificationEnabled) {
        _scheduleNotification(prayer);
      } else {
        _notificationService.cancelNotification(prayer.id.hashCode);
      }
    }
  }

  void _scheduleNotification(PrayerTimeModel prayer) {
    try {
      final now = DateTime.now();
      final format = DateFormat("hh:mm a");
      final prayerTime = format.parse(prayer.time);
      
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        prayerTime.hour,
        prayerTime.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      _notificationService.scheduleNotification(
        prayer.id.hashCode,
        "নামাজের সময় হয়েছে",
        "${prayer.name} এর সময় হয়েছে। নামাজ পড়তে ভুলবেন না।",
        scheduledDate,
        soundName: 'azan_rington', // Assuming sound_alarm exists or mapped to a ringtone
      );
    } catch (e) {
      debugPrint("Error scheduling prayer notification: $e");
    }
  }
}
