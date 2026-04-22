import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String note;
  final bool isExpense;
  final DateTime date;
  final DateTime createdAt;
  // final String? receiptUrl;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.isExpense,
    required this.date,
    required this.createdAt,
    // this.receiptUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'isExpense': isExpense,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      // 'receiptUrl': receiptUrl,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      note: map['note'] ?? '',
      isExpense: map['isExpense'] ?? true,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      // receiptUrl: map['receiptUrl'] as String?,
    );
  }
}