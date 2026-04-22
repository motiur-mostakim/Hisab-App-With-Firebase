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

  Map<String, double> _getCategoryTotals(
      List<TransactionModel> transactions, bool isExpense) {
    final categoryTotals = <String, double>{};

    for (var txn in transactions) {
      if (txn.isExpense == isExpense) {
        categoryTotals[txn.category] =
            (categoryTotals[txn.category] ?? 0) + txn.amount;
      }
    }

    return categoryTotals;
  }

  List<TransactionModel> _filterByReportType(
      List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    if (_reportType == "মাসিক") {
      return transactions.where((txn) => txn.date.isAfter(monthStart)).toList();
    } else {
      return transactions.where((txn) => txn.date.isAfter(yearStart)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C1F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<TransactionModel>>(
                stream: _transactionService.getTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("কোনো ডেটা নেই",
                          style: TextStyle(color: Colors.white54)),
                    );
                  }

                  final filteredTransactions =
                  _filterByReportType(snapshot.data!);
                  final stats = _calculateStats(filteredTransactions);
                  final categoryTotals =
                  _getCategoryTotals(filteredTransactions, true);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTopSection(),
                        const SizedBox(height: 20),
                        _buildMainChart(filteredTransactions),
                        const SizedBox(height: 20),
                        _buildSavingsCard(stats),
                        const SizedBox(height: 20),
                        _buildTopCategories(categoryTotals),
                        const SizedBox(height: 20),
                        _buildExportOptions(),
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
      if (txn.isExpense) {
        expense += txn.amount;
      } else {
        income += txn.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF111125),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "The Fluid Architect",
            style: TextStyle(
              color: Color(0xFFE2E0FC),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.white70),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ??
                      "https://i.pravatar.cc/150?img=3",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "আর্থিক বিশ্লেষণ",
          style: TextStyle(color: Colors.tealAccent, fontSize: 12),
        ),
        const SizedBox(height: 5),
        const Text(
          "ইনসাইট রিপোর্ট",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _chip("মাসিক", _reportType == "মাসিক"),
            _chip("বার্ষিক", _reportType == "বার্ষিক"),
            const Spacer(),
            const Icon(Icons.share, color: Colors.white70),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _reportType = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.tealAccent : const Color(0xFF1E1E32),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(List<TransactionModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "আয় বনাম ব্যয়",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      Container(
                        width: 6,
                        height: 80 + (index * 10),
                        color: Colors.tealAccent,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 50 + (index * 5),
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ["Oct", "Nov", "Dec", "Jan", "Feb", "Mar"][index],
                    style: const TextStyle(fontSize: 10),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.tealAccent, Colors.green]
              : [Colors.redAccent, Colors.orange],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.account_balance_wallet, size: 30),
          const SizedBox(height: 10),
          const Text("নিট উদ্বৃত্ত"),
          Text(
            "\$${balance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories(Map<String, double> categoryTotals) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "শীর্ষ বিভাগ",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sortedCategories.take(3).map((entry) {
            return _category(
              entry.key,
              "\$${entry.value.toStringAsFixed(2)}",
              Colors.redAccent,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _category(String title, String amount, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(.2)),
      title: Text(title),
      trailing: Text(amount),
    );
  }

  Widget _buildExportOptions() {
    return Column(
      children: [
        _exportTile(Icons.picture_as_pdf, "PDF Export"),
        _exportTile(Icons.table_chart, "CSV Export"),
        _exportTile(Icons.mail, "Email রিপোর্ট"),
      ],
    );
  }

  Widget _exportTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }
}