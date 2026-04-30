import 'package:flutter/material.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen> {
  bool? showOwedToMe;
  final TransactionService _transactionService = TransactionService();

  Future<void> _deleteTransaction(TransactionModel txn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("লেনদেন মুছে ফেলুন?"),
        content: const Text(
          "আপনি কি নিশ্চিত যে আপনি এই লেনদেনটি মুছে ফেলতে চান? এটি হিসাব থেকে বাদ যাবে।",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("না"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("হ্যাঁ, মুছুন"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _transactionService.deleteTransaction(txn);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("লেনদেন মুছে ফেলা হয়েছে")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ধারের বিস্তারিত হিসাব",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDebts =
              snapshot.data?.where((txn) => txn.isLoan).toList() ?? [];

          if (allDebts.isEmpty) {
            return _buildEmptyState();
          }

          // ১. নাম অনুযায়ী লেনদেন গ্রুপ করা
          final Map<String, List<TransactionModel>> personGrouped = {};
          final Map<String, double> personBalances = {};
          final Map<String, String> displayNameMap = {};

          for (var txn in allDebts) {
            final rawName = txn.note.trim().isEmpty
                ? "নামহীন"
                : txn.note.trim();
            final normalizedName = rawName.toLowerCase();

            if (!personGrouped.containsKey(normalizedName)) {
              personGrouped[normalizedName] = [];
              personBalances[normalizedName] = 0;
              displayNameMap[normalizedName] = rawName;
            }
            personGrouped[normalizedName]!.add(txn);
            personBalances[normalizedName] =
                personBalances[normalizedName]! +
                (txn.isExpense ? txn.amount : -txn.amount);
          }

          // ২. পাওনা ও দেনা আলাদা লিস্টে ভাগ করা
          final List<_PersonDebtInfo> iWillGet = []; // পাওনা (আমি পাব)
          final List<_PersonDebtInfo> iWillGive = []; // দেনা (আমি দেব)

          personBalances.forEach((normalizedName, balance) {
            if (balance.abs() >= 1.0) {
              final info = _PersonDebtInfo(
                name: displayNameMap[normalizedName]!,
                amount: balance.abs(),
                transactions: personGrouped[normalizedName]!
                  ..sort((a, b) => b.date.compareTo(a.date)),
              );
              if (balance > 0) {
                iWillGet.add(info);
              } else {
                iWillGive.add(info);
              }
            }
          });

          double netOwedToMe = iWillGet.fold(
            0,
            (sum, item) => sum + item.amount,
          );
          double netIOwe = iWillGive.fold(0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              // সামারি কার্ড
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      "মোট পাওনা",
                      netOwedToMe,
                      Colors.green,
                      isDark,
                      showOwedToMe == true,
                      () => setState(
                        () => showOwedToMe = showOwedToMe == true ? null : true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      "মোট দেনা",
                      netIOwe,
                      Colors.red,
                      isDark,
                      showOwedToMe == false,
                      () => setState(
                        () =>
                            showOwedToMe = showOwedToMe == false ? null : false,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    if (showOwedToMe == null || showOwedToMe == true) ...[
                      if (iWillGet.isNotEmpty) ...[
                        _buildSectionHeader(
                          "পাওনা তালিকা (আমি পাব)",
                          Colors.green,
                        ),
                        ...iWillGet.map(
                          (info) =>
                              _buildPersonCard(info, Colors.green, isDark),
                        ),
                      ] else if (showOwedToMe == true)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "কোনো পাওনা নেই",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                    if (showOwedToMe == null || showOwedToMe == false) ...[
                      if (iWillGive.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSectionHeader(
                          "দেনা তালিকা (আমি দেব)",
                          Colors.red,
                        ),
                        ...iWillGive.map(
                          (info) => _buildPersonCard(info, Colors.red, isDark),
                        ),
                      ] else if (showOwedToMe == false)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "কোনো দেনা নেই",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    bool isDark,
    bool isActive,
    VoidCallback onTap,
  ) {
    final bool isZero = amount < 1;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.1)
                : (isDark ? const Color(0xFF1E1E32) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? color.withOpacity(0.5)
                  : (isDark ? Colors.white10 : Colors.transparent),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? color : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "৳${amount.toStringAsFixed(0)}",
                style: TextStyle(
                  color: isZero
                      ? Colors.grey
                      : (isActive
                            ? color
                            : (isDark ? Colors.white : Colors.black87)),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActive) Icon(Icons.check_circle, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(_PersonDebtInfo info, Color color, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      color: isDark ? const Color(0xFF1E1E32) : Colors.white,
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            info.name[0].toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          info.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${info.transactions.length} টি লেনদেন"),
        trailing: Text(
          "৳${info.amount.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        children: info.transactions
            .map(
              (t) => ListTile(
                dense: true,
                leading: Icon(
                  t.isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: t.isExpense ? Colors.green : Colors.red,
                  size: 16,
                ),
                title: Text(
                  t.isExpense ? "দিয়েছি / পরিশোধ" : "নিয়েছি / ফেরত",
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text("${t.date.day}/${t.date.month}/${t.date.year}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "৳${t.amount.toStringAsFixed(0)}",
                      style: TextStyle(
                        color: t.isExpense ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => _deleteTransaction(t),
                      tooltip: "মুছে ফেলুন",
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "কোনো ধারের হিসাব নেই",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _PersonDebtInfo {
  final String name;
  final double amount;
  final List<TransactionModel> transactions;

  _PersonDebtInfo({
    required this.name,
    required this.amount,
    required this.transactions,
  });
}
