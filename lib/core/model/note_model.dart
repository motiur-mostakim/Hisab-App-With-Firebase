import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? alarmTime;
  final List<int>? repeatDays; // ১ (সোমবার) থেকে ৭ (রবিবার)

  NoteModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.alarmTime,
    this.repeatDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'alarmTime': alarmTime,
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
}
