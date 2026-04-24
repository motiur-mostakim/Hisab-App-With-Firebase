import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _reportType = "মাসিক"; // মাসিক or বার্ষিক

  Map<String, double> _getCategoryTotals(List<TransactionModel> transactions, bool isExpense) {
    final categoryTotals = <String, double>{};
    for (var txn in transactions) {
      if (txn.isExpense == isExpense) {
        categoryTotals[txn.category] = (categoryTotals[txn.category] ?? 0) + txn.amount;
      }
    }
    return categoryTotals;
  }

  List<TransactionModel> _filterByReportType(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    if (_reportType == "মাসিক") {
      return transactions.where((txn) => txn.date.isAfter(monthStart.subtract(const Duration(days: 1)))).toList();
    } else {
      return transactions.where((txn) => txn.date.isAfter(yearStart.subtract(const Duration(days: 1)))).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _transactionService.getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text("কোনো ডেটা নেই", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                    );
                  }

                  final filteredTransactions = _filterByReportType(snapshot.data!);
                  final stats = _calculateStats(filteredTransactions);
                  final categoryTotals = _getCategoryTotals(filteredTransactions, true);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTopSection(isDark),
                        const SizedBox(height: 20),
                        _buildMainChart(filteredTransactions, isDark),
                        const SizedBox(height: 20),
                        _buildSavingsCard(stats),
                        const SizedBox(height: 20),
                        _buildTopCategories(categoryTotals, isDark),
                        const SizedBox(height: 20),
                        _buildExportOptions(isDark),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _calculateStats(List<TransactionModel> transactions) {
    double income = 0, expense = 0;
    for (var txn in transactions) {
      if (txn.isExpense) { expense += txn.amount; } else { income += txn.amount; }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? const Color(0xFF111125) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "আর্থিক বিশ্লেষণ",
            style: TextStyle(
              color: isDark ? const Color(0xFFE2E0FC) : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Icon(Icons.notifications, color: isDark ? Colors.white70 : Colors.black54),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ?? "https://i.pravatar.cc/150?img=3",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "রিপোর্ট ইনসাইট",
          style: TextStyle(color: Color(0xFF60DCB2), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          "সারসংক্ষেপ",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _chip("মাসিক", _reportType == "মাসিক", isDark),
            _chip("বার্ষিক", _reportType == "বার্ষিক", isDark),
            const Spacer(),
            Icon(Icons.share, color: isDark ? Colors.white70 : Colors.black54),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, bool active, bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _reportType = text),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF60DCB2) : (isDark ? const Color(0xFF1E1E32) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(List<TransactionModel> transactions, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "আয় বনাম ব্যয়",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(width: 6, height: 80 + (index * 10), color: const Color(0xFF60DCB2)),
                      const SizedBox(width: 4),
                      Container(width: 6, height: 50 + (index * 5), color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ["Oct", "Nov", "Dec", "Jan", "Feb", "Mar"][index],
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsCard(Map<String, double> stats) {
    final balance = stats['balance'] ?? 0;
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive ? [const Color(0xFF60DCB2), const Color(0xFF009672)] : [Colors.redAccent, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_wallet, size: 30, color: Colors.white),
          const SizedBox(height: 10),
          const Text("নিট উদ্বৃত্ত (Net Balance)", style: TextStyle(color: Colors.white70)),
          Text(
            "\৳${balance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(Map<String, double> categoryTotals, bool isDark) {
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "শীর্ষ ব্যয় বিভাগ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 16),
          if (sortedCategories.isEmpty)
            const Text("কোনো তথ্য নেই", style: TextStyle(color: Colors.grey))
          else
            ...sortedCategories.take(3).map((entry) {
              return _category(entry.key, "\৳${entry.value.toStringAsFixed(2)}", Colors.redAccent, isDark);
            }).toList(),
        ],
      ),
    );
  }

  Widget _category(String title, String amount, Color color, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withOpacity(.1), child: Icon(Icons.arrow_downward, color: color, size: 18)),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      trailing: Text(amount, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildExportOptions(bool isDark) {
    return Column(
      children: [
        _exportTile(Icons.picture_as_pdf, "PDF রিপোর্ট ডাউনলোড", isDark),
        _exportTile(Icons.table_chart, "CSV রিপোর্ট ডাউনলোড", isDark),
        _exportTile(Icons.mail, "ইমেইল রিপোর্ট পাঠান", isDark),
      ],
    );
  }

  Widget _exportTile(IconData icon, String title, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF60DCB2)),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
