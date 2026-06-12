import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerTimeModel {
  final String id;
  final String name;
  final String time; // e.g., "05:30 AM"
  final bool isNotificationEnabled;

  PrayerTimeModel({
    required this.id,
    required this.name,
    required this.time,
    this.isNotificationEnabled = true,
  });

  factory PrayerTimeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PrayerTimeModel(
      id: doc.id,
      name: data['name'] ?? '',
      time: data['time'] ?? '',
      isNotificationEnabled: data['isNotificationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'isNotificationEnabled': isNotificationEnabled,
    };
  }
}
