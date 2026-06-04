import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../model/transaction_model.dart';
import 'dashboard_calculations.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> addTransaction(TransactionModel transaction) async {
    final userId = transaction.userId;
    
    String collectionName;
    if (transaction.type.startsWith('loan')) {
      collectionName = 'loans';
    } else {
      collectionName = transaction.type == 'expense' ? 'expenses' : 'income';
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
    if (transaction.type.startsWith('loan')) {
      collectionName = 'loans';
    } else {
      collectionName = transaction.type == 'expense' ? 'expenses' : 'income';
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
        .orderBy('transactionDate', descending: true)
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

            if (txn.type == 'expense') {
              expense += txn.amount;
            } else if (txn.type == 'income') {
              income += txn.amount;
            }
          }

          return {'income': income, 'expense': expense};
        });
  }

  Stream<Map<String, dynamic>> getDashboardData() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({
        'cashBalance': 0.0,
        'debt': 0.0,
        'receivable': 0.0,
        'netWorth': 0.0,
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'personLoans': <String, double>{},
        'expenseByCategory': <String, double>{},
        'incomeByCategory': <String, double>{},
      });
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('all_transactions')
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
              .map((doc) => TransactionModel.fromMap(doc.data()))
              .toList();

          return {
            'cashBalance':
                DashboardCalculations.calculateCashBalance(transactions),
            'debt': DashboardCalculations.calculateOutstandingDebt(transactions),
            'receivable':
                DashboardCalculations.calculateReceivable(transactions),
            'netWorth': DashboardCalculations.calculateNetWorth(transactions),
            'totalIncome': DashboardCalculations.getTotalIncome(transactions),
            'totalExpense':
                DashboardCalculations.getTotalExpense(transactions),
            'personLoans':
                DashboardCalculations.getPersonLoanBalance(transactions),
            'expenseByCategory':
                DashboardCalculations.getExpenseByCategory(transactions),
            'incomeByCategory':
                DashboardCalculations.getIncomeByCategory(transactions),
            'monthlySummary':
                DashboardCalculations.getMonthlySummary(transactions),
          };
        });
  }

  Future<void> updateBudget(double budget) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).set({
      'monthlyBudget': budget,
    }, SetOptions(merge: true));
  }

  Stream<double> getBudget() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0.0);

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return (doc.data()!['monthlyBudget'] ?? 0.0).toDouble();
          }
          return 0.0;
        });
  }
}
