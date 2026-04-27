import 'package:flutter/material.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';

class DebtHistoryScreen extends StatelessWidget {
  const DebtHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TransactionService transactionService = TransactionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ধারের হিসাব",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDebts =
              snapshot.data?.where((txn) => txn.isLoan).toList() ?? [];

          if (allDebts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "কোনো ধারের লেনদেন নেই",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // নিট হিসাব বের করার লজিক
          double netOwedToMe = 0; // আমি মানুষের কাছে পাব
          double netIOwe = 0; // আমি মানুষের কাছে ঋণী

          double totalExpenseLoan =
              0; // মোট কত টাকা ধার দিয়েছি/পরিশোধ করেছি (Cash Out)
          double totalIncomeLoan =
              0; // মোট কত টাকা ধার নিয়েছি/ফেরত পেয়েছি (Cash In)

          for (var txn in allDebts) {
            if (txn.isExpense) {
              totalExpenseLoan += txn.amount;
            } else {
              totalIncomeLoan += txn.amount;
            }
          }

          // হিসাব: (ধার দেওয়া - ফেরত পাওয়া) = নিট পাওনা
          // হিসাব: (ধার নেওয়া - পরিশোধ করা) = নিট দেনা
          // এখানে একটি সহজ লজিক ব্যবহার করা হয়েছে:
          double netBalance = totalExpenseLoan - totalIncomeLoan;

          if (netBalance > 0) {
            netOwedToMe = netBalance;
            netIOwe = 0;
          } else {
            netOwedToMe = 0;
            netIOwe = netBalance.abs();
          }

          return Column(
            children: [
              _buildSummaryHeader(netOwedToMe, netIOwe, isDark),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "লেনদেনের ইতিহাস",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: allDebts.length,
                  itemBuilder: (context, index) {
                    final txn = allDebts[index];
                    return _DebtItem(txn: txn, isDark: isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(double netOwedToMe, double netIOwe, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: _summaryTile("নিট পাওনা", netOwedToMe, Colors.green)),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(child: _summaryTile("নিট দেনা", netIOwe, Colors.red)),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "৳${amount.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _DebtItem extends StatelessWidget {
  final TransactionModel txn;
  final bool isDark;

  const _DebtItem({required this.txn, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Expense + Loan = ধার দেওয়া
    // Income + Loan = ধার ফেরত পাওয়া বা নেওয়া
    String label = "";
    if (txn.isExpense) {
      label = "ধার প্রদান/পরিশোধ";
    } else {
      label = "ধার গ্রহণ/ফেরত প্রাপ্তি";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (txn.isExpense ? Colors.red : Colors.green)
                .withOpacity(0.1),
            child: Icon(
              txn.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
              color: txn.isExpense ? Colors.red : Colors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.note.isEmpty ? label : txn.note,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${txn.date.day}/${txn.date.month}/${txn.date.year}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "৳${txn.amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: txn.isExpense ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
