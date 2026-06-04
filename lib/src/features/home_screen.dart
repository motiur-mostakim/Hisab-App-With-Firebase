import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hisab_app/core/services/fcm_notification_services.dart';
import 'package:hisab_app/src/features/notification_screen.dart';
import 'package:hisab_app/src/features/widgets/dashboard_summary_widget.dart';

import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';
import 'add_transaction_screen.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();
  int _notificationCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadNotificationCount();
  }

  double _getMonthlyExpense(List<TransactionModel> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return transactions
        .where(
          (txn) =>
              txn.type == 'expense' &&
              txn.transactionDate.isAfter(monthStart) &&
              txn.transactionDate.isBefore(DateTime.now().add(const Duration(days: 1))),
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

  // বাজেট সেট করার ডায়ালগ
  void _showSetBudgetDialog(double currentBudget) {
    final controller = TextEditingController(text: currentBudget == 0 ? "" : currentBudget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("মাসিক বাজেট সেট করুন"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "বাজেট পরিমাণ",
            hintText: "উদাঃ ৫০০০",
            prefixText: "৳ ",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            onPressed: () {
              final budget = double.tryParse(controller.text) ?? 0.0;
              _transactionService.updateBudget(budget);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("বাজেট আপডেট করা হয়েছে")),
              );
            },
            child: const Text("সেভ করুন"),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNotificationCount() async {
    final count = await FcmNotificationServices().getNotificationCount();
    setState(() {
      _notificationCount = count;
    });
  }

  void _showCalculator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalculatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
                _loadNotificationCount();
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_none),
                  if (_notificationCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          '$_notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DashboardSummaryWidget(transactionService: _transactionService),
            const SizedBox(height: 20),

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
            const SizedBox(height: 4),
            
            // ডাইনামিক বাজেট সেকশন
            StreamBuilder<double>(
              stream: _transactionService.getBudget(),
              builder: (context, budgetSnapshot) {
                final monthlyBudget = budgetSnapshot.data ?? 0.0;
                
                return StreamBuilder<List<TransactionModel>>(
                  stream: _transactionService.getTransactions(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final monthlyExpense = _getMonthlyExpense(snapshot.data!);
                    final isOverBudget = monthlyBudget > 0 && monthlyExpense > monthlyBudget;
                    final percentageUsed = monthlyBudget > 0 
                        ? (monthlyExpense / monthlyBudget) * 100 
                        : 0.0;
                    
                    return Column(
                      children: [
                        if (isOverBudget)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(top: 16),
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
                                        "৳${(monthlyExpense - monthlyBudget).toStringAsFixed(2)} অতিরিক্ত খরচ করেছেন",
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
                        GestureDetector(
                          onTap: () => _showSetBudgetDialog(monthlyBudget),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E32)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "মাসিক বাজেট",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit,
                                          size: 14,
                                          color: isDark ? Colors.white54 : Colors.black45,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      monthlyBudget > 0 
                                          ? "${percentageUsed.toStringAsFixed(0)}% ব্যবহৃত"
                                          : "বাজেট সেট নেই",
                                      style: TextStyle(
                                        color: isOverBudget
                                            ? Colors.red
                                            : (monthlyBudget > 0 ? Colors.green : Colors.grey),
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
                                    value: monthlyBudget > 0 
                                        ? (monthlyExpense / monthlyBudget).clamp(0.0, 1.0)
                                        : 0.0,
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
                                      "৳${monthlyExpense.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "সীমা: ৳${monthlyBudget.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
            ),
            const SizedBox(height: 20),
            _BottomSection(transactionService: _transactionService),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "calculator_tab",
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

class _BottomSection extends StatelessWidget {
  final TransactionService transactionService;
  const _BottomSection({required this.transactionService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "সাম্প্রতিক লেনদেন",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              child: const Text(
                "সব দেখুন",
                style: TextStyle(color: Color(0xFF60DCB2)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<TransactionModel>>(
          stream: transactionService.getTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    "কোনো লেনদেন নেই",
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              );
            }

            // ধার সহ সব লেনদেন দেখানোর জন্য ফিল্টার আপডেট
            final transactions = snapshot.data!.take(10).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final txn = transactions[index];
                final isLoan = txn.type.contains('loan');
                
                // ধারের জন্য আলাদা কালার এবং আইকন
                final color = isLoan ? Colors.orange : (txn.type == 'expense' ? Colors.red : Colors.green);
                final icon = isLoan ? Icons.handshake : (txn.type == 'expense' ? Icons.remove : Icons.add);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E32) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoan 
                                  ? (txn.type == 'loan_given' ? "ধার দেওয়া" : "ধার নেওয়া")
                                  : (txn.category ?? "অন্যান্য"),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              isLoan 
                                  ? "ব্যক্তি: ${txn.personId ?? 'অজানা'}" 
                                  : (txn.note?.isEmpty ?? true ? (txn.type == 'expense' ? "ব্যয়" : "আয়") : txn.note!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "${(txn.type == 'expense' || txn.type == 'loan_given') ? '-' : '+'} ৳${txn.amount.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
