import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? alarmTime;
  final List<int>? repeatDays;

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    this.content,
    required this.createdAt,
    required this.updatedAt,
    this.alarmTime,
    this.repeatDays,
  });

  // =========================
  // 🔥 FIREBASE (Firestore)
  // =========================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'alarmTime':
      alarmTime != null ? Timestamp.fromDate(alarmTime!) : null,
      'repeatDays': repeatDays,
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      alarmTime: map['alarmTime'] != null
          ? (map['alarmTime'] as Timestamp).toDate()
          : null,
      repeatDays: map['repeatDays'] != null
          ? List<int>.from(map['repeatDays'])
          : null,
    );
  }

  // =========================
  // 🔥 LOCAL (SharedPreferences)
  // =========================

  Map<String, dynamic> toJson() => {
    "id": id,
    "userId": userId,
    "title": title,
    "content": content,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt.toIso8601String(),
    "alarmTime": alarmTime?.toIso8601String(),
    "repeatDays": repeatDays,
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json["id"] ?? '',
      userId: json["userId"] ?? '',
      title: json["title"] ?? '',
      content: json["content"] ?? '',
      createdAt: DateTime.parse(json["createdAt"]),
      updatedAt: DateTime.parse(json["updatedAt"]),
      alarmTime: json["alarmTime"] != null
          ? DateTime.parse(json["alarmTime"])
          : null,
      repeatDays: json["repeatDays"] != null
          ? List<int>.from(json["repeatDays"])
          : null,
    );
  }
}