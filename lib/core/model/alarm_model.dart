import 'dart:convert';

class AlarmModel {
  final String id;
  final String label;
  final DateTime dateTime;
  final List<int> repeatDays; // 1 (Mon) to 7 (Sun)
  final bool isActive;

  AlarmModel({
    required this.id,
    required this.label,
    required this.dateTime,
    required this.repeatDays,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'dateTime': dateTime.toIso8601String(),
      'repeatDays': repeatDays,
      'isActive': isActive,
    };
  }

  factory AlarmModel.fromMap(Map<String, dynamic> map) {
    return AlarmModel(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlarmModel.fromJson(String source) =>
      AlarmModel.fromMap(json.decode(source));
}
