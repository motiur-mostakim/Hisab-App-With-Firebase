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
  final bool isLoan; // নতুন ফিল্ড

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.isExpense,
    required this.date,
    required this.createdAt,
    this.isLoan = false, // ডিফল্টভাবে false
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
      'isLoan': isLoan,
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
      isLoan: map['isLoan'] ?? false,
    );
  }
}
