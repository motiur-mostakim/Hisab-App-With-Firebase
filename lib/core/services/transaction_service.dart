import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Future<String?> uploadReceipt(
  //   File file,
  //   String userId,
  //   String transactionId,
  // ) async {
  //   final ref = _storage.ref().child(
  //     'users/$userId/receipts/$transactionId.jpg',
  //   );
  //   final uploadTask = await ref.putFile(file);
  //   return await uploadTask.ref.getDownloadURL();
  // }

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = transaction.userId;
    final collectionName = transaction.isExpense ? 'expenses' : 'income';

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
            if (txn.isExpense) {
              expense += txn.amount;
            } else {
              income += txn.amount;
            }
          }

          return {'income': income, 'expense': expense};
        });
  }
}
