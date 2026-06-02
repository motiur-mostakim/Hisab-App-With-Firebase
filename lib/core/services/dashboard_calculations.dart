import '../model/transaction_model.dart';
class DashboardCalculations {
   static double calculateCashBalance(List<TransactionModel> transactions) {
    double balance = 0.0;

    for (var txn in transactions) {
      if (['income', 'loan_taken', 'loan_collected'].contains(txn.type)) {
        balance += txn.amount;
      } else if (['expense', 'loan_given', 'loan_repaid'].contains(txn.type)) {
        balance -= txn.amount;
      }
    }

    return balance;
  }
 static double calculateOutstandingDebt(List<TransactionModel> transactions) {
    double debt = 0.0;

    for (var txn in transactions) {
      if (txn.type == 'loan_taken') {
        debt += txn.amount;
      } else if (txn.type == 'loan_repaid') {
        debt -= txn.amount;
      }
    }

    return debt;
  }

  static double calculateReceivable(List<TransactionModel> transactions) {
    double receivable = 0.0;

    for (var txn in transactions) {
      if (txn.type == 'loan_given') {
        receivable += txn.amount;
      } else if (txn.type == 'loan_collected') {
        receivable -= txn.amount;
      }
    }

    return receivable;
  }

 static double calculateNetWorth(List<TransactionModel> transactions) {
    double cashBalance = calculateCashBalance(transactions);
    double receivable = calculateReceivable(transactions);
    double debt = calculateOutstandingDebt(transactions);

    return cashBalance + receivable - debt;
  }
 static Map<String, double> getPersonLoanBalance(
      List<TransactionModel> transactions) {
    Map<String, double> personBalance = {};

    for (var txn in transactions) {
      if (['loan_given', 'loan_taken', 'loan_collected', 'loan_repaid']
              .contains(txn.type) &&
          txn.personId != null) {
        personBalance.putIfAbsent(txn.personId!, () => 0.0);

        if (txn.type == 'loan_given') {
          personBalance[txn.personId!] = personBalance[txn.personId!]! + txn.amount;
        } else if (txn.type == 'loan_collected') {
          personBalance[txn.personId!] = personBalance[txn.personId!]! - txn.amount;
        } else if (txn.type == 'loan_taken') {
          personBalance[txn.personId!] = personBalance[txn.personId!]! - txn.amount;
        } else if (txn.type == 'loan_repaid') {
          personBalance[txn.personId!] = personBalance[txn.personId!]! + txn.amount;
        }
      }
    }

    return personBalance;
  }

  static Map<String, double> getExpenseByCategory(
      List<TransactionModel> transactions) {
    Map<String, double> expenseByCategory = {};

    for (var txn in transactions) {
      if (txn.type == 'expense') {
        String category = txn.category ?? 'অন্যান্য';
        expenseByCategory.putIfAbsent(category, () => 0.0);
        expenseByCategory[category] = expenseByCategory[category]! + txn.amount;
      }
    }

    return expenseByCategory;
  }

  static Map<String, double> getIncomeByCategory(
      List<TransactionModel> transactions) {
    Map<String, double> incomeByCategory = {};

    for (var txn in transactions) {
      if (txn.type == 'income') {
        String category = txn.category ?? 'অন্যান্য';
        incomeByCategory.putIfAbsent(category, () => 0.0);
        incomeByCategory[category] = incomeByCategory[category]! + txn.amount;
      }
    }

    return incomeByCategory;
  }

  static double getTotalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((txn) => txn.type == 'income')
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  static double getTotalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((txn) => txn.type == 'expense')
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  static Map<String, double> getMonthlySummary(
      List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final monthTransactions = transactions
        .where((txn) =>
            txn.transactionDate.isAfter(monthStart) &&
            txn.transactionDate.isBefore(monthEnd))
        .toList();

    return {
      'income': getTotalIncome(monthTransactions),
      'expense': getTotalExpense(monthTransactions),
      'cashBalance': calculateCashBalance(monthTransactions),
    };
  }
}

