import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = transaction.userId;
    
    // ধারের জন্য আলাদা কালেকশন নাম নির্ধারণ
    String collectionName;
    if (transaction.isLoan) {
      collectionName = 'loans';
    } else {
      collectionName = transaction.isExpense ? 'expenses' : 'income';
    }

    final batch = _firestore.batch();
    final typedDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(transaction.id);

    final allDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('all_transactions')
        .doc(transaction.id);

    batch.set(typedDoc, transaction.toMap());
    batch.set(allDoc, transaction.toMap());

    await batch.commit();
  }

  Future<void> deleteTransaction(TransactionModel transaction) async {
    final userId = transaction.userId;
    
    String collectionName;
    if (transaction.isLoan) {
      collectionName = 'loans';
    } else {
      collectionName = transaction.isExpense ? 'expenses' : 'income';
    }

    final batch = _firestore.batch();
    final typedDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(transaction.id);

    final allDoc = _firestore
        .collection('users')
        .doc(userId)
        .collection('all_transactions')
        .doc(transaction.id);

    batch.delete(typedDoc);
    batch.delete(allDoc);

    await batch.commit();
  }

  Stream<List<TransactionModel>> getTransactions() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('all_transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // এই মেথডটি এখন শুধু সাধারণ আয়-ব্যয় রিটার্ন করবে (ধার বাদে)
  Stream<Map<String, double>> getDailyStats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value({'income': 0.0, 'expense': 0.0});

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('all_transactions')
        .snapshots()
        .map((snapshot) {
          double income = 0.0;
          double expense = 0.0;

          for (var doc in snapshot.docs) {
            final txn = TransactionModel.fromMap(doc.data());
            
            // যদি ধার না হয়, তবেই মেইন ব্যালেন্সে যোগ হবে
            if (!txn.isLoan) {
              if (txn.isExpense) {
                expense += txn.amount;
              } else {
                income += txn.amount;
              }
            }
          }

          return {'income': income, 'expense': expense};
        });
  }
}
