import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';
import 'add_transaction_screen.dart';
import 'calculator_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();
  final double monthlyBudget = 3000.0; // মাসিক বাজেট লিমিট

  double _getMonthlyExpense(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return transactions
        .where(
          (txn) =>
              txn.isExpense &&
              txn.date.isAfter(monthStart) &&
              txn.date.isBefore(DateTime.now()),
        )
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  void _showAddTransactionDialog(bool isExpense) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AddTransactionScreen(initialIsExpense: isExpense),
          ),
        ),
      ),
    );
  }

  void _showCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalculatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                auth.currentUser?.photoURL ?? "https://i.pravatar.cc/150?img=3",
              ),
            ),
            const SizedBox(width: 10),
            Text(
              auth.currentUser?.displayName ?? "",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Horizontally buttons for Income and Expense
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    title: "আয়",
                    icon: Icons.add_circle_outline,
                    color: Colors.green,
                    onTap: () => _showAddTransactionDialog(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionBtn(
                    title: "ব্যয়",
                    icon: Icons.remove_circle_outline,
                    color: Colors.red,
                    onTap: () => _showAddTransactionDialog(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            StreamBuilder<Map<String, double>>(
              stream: _transactionService.getDailyStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {'income': 0.0, 'expense': 0.0};
                final balance =
                    (stats['income'] ?? 0.0) - (stats['expense'] ?? 0.0);

                return _BalanceSection(balance: balance);
              },
            ),
            const SizedBox(height: 20),
            _SummaryCards(transactionService: _transactionService),
            const SizedBox(height: 20),
            StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getTransactions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final monthlyExpense = _getMonthlyExpense(snapshot.data!);
                final isOverBudget = monthlyExpense > monthlyBudget;
                final percentageUsed = (monthlyExpense / monthlyBudget) * 100;
                return Column(
                  children: [
                    if (isOverBudget)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_rounded,
                              color: Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "বাজেট অতিক্রম করেছেন!",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "\৳${(monthlyExpense - monthlyBudget).toStringAsFixed(2)} অতিরিক্ত খরচ করেছেন",
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "মাসিক বাজেট",
                                style: TextStyle(
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "${percentageUsed.toStringAsFixed(0)}% ব্যবহৃত",
                                style: TextStyle(
                                  color: isOverBudget
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (monthlyExpense / monthlyBudget).clamp(
                                0.0,
                                1.0,
                              ),
                              minHeight: 8,
                              backgroundColor: Colors.grey.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOverBudget ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "\৳${monthlyExpense.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "সীমা: \৳${monthlyBudget.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            _BottomSection(transactionService: _transactionService),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCalculator,
        backgroundColor: const Color(0xFF60DCB2),
        child: const Icon(Icons.calculate, color: Color(0xFF003829)),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSection extends StatelessWidget {
  final double balance;

  const _BalanceSection({required this.balance});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "বর্তমান মোট সম্পদ",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
        const SizedBox(height: 5),
        Text(
          "\৳${balance.toStringAsFixed(2)}",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final TransactionService transactionService;

  const _SummaryCards({required this.transactionService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: transactionService.getDailyStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'income': 0.0, 'expense': 0.0};
        final income = stats['income'] ?? 0.0;
        final expense = stats['expense'] ?? 0.0;

        return Column(
          children: [
            _CardItem(
              title: "মোট আয়",
              amount: "+\৳${income.toStringAsFixed(2)}",
              color: Colors.green,
            ),
            const SizedBox(height: 10),
            _CardItem(
              title: "মোট ব্যয়",
              amount: "-\৳${expense.toStringAsFixed(2)}",
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }
}

class _CardItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _CardItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 5),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSection extends StatelessWidget {
  final TransactionService transactionService;

  const _BottomSection({required this.transactionService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "সাম্প্রতিক কার্যক্রম",
          style: TextStyle(
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<TransactionModel>>(
          stream: transactionService.getTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "কোনো লেনদেন নেই",
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                ),
              );
            }

            final transactions = snapshot.data!.take(10).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                return _TransactionItem(
                  title: txn.category,
                  subtitle: txn.note,
                  amount:
                      "${txn.isExpense ? '-' : '+'}\৳${txn.amount.toStringAsFixed(2)}",
                  isExpense: txn.isExpense,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title, subtitle, amount;
  final bool isExpense;

  const _TransactionItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDark ? const Color(0xFF333348) : Colors.grey[300],
        child: Icon(
          isExpense ? Icons.arrow_upward : Icons.arrow_downward,
          color: isExpense ? Colors.red : Colors.green,
        ),
      ),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
      trailing: Text(
        amount,
        style: TextStyle(
          color: isExpense ? Colors.red : Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
