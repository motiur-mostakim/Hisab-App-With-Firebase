import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen> {
  String? activeFilter; // 'receivable', 'payable', 'settled'
  final TransactionService _transactionService = TransactionService();
  final Set<String> _settlingPersons = {};

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

  Future<void> _settleFullBalance(_PersonDebtInfo info, bool isReceivable) async {
    if (info.amount <= 0 || _settlingPersons.contains(info.name)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("পরিশোধ নিশ্চিত করুন"),
        content: Text(
          isReceivable
              ? "${info.name}-এর থেকে সব পাওনা (৳${info.amount.toStringAsFixed(0)}) কি ফেরত পেয়েছেন?"
              : "${info.name}-কে সব দেনা (৳${info.amount.toStringAsFixed(0)}) কি পরিশোধ করেছেন?",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("না")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text("হ্যাঁ, হয়েছে"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _settlingPersons.add(info.name));
      try {
        final settlement = TransactionModel(
          id: const Uuid().v4(),
          userId: info.transactions.first.userId,
          amount: info.amount,
          type: isReceivable ? 'loan_collected' : 'loan_repaid',
          category: 'ধার/বাকি',
          personId: info.name,
          note: "পুরো হিসাব পরিশোধিত",
          transactionDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await _transactionService.addTransaction(settlement);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("হিসাব মিটিয়ে ফেলা হয়েছে এবং ইতিহাসে যোগ হয়েছে")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("ত্রুটি: $e")),
          );
        }
      } finally {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _settlingPersons.remove(info.name));
        });
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
              snapshot.data?.where((txn) => txn.type.startsWith('loan')).toList() ?? [];

          if (allDebts.isEmpty) {
            return _buildEmptyState();
          }

          final Map<String, List<TransactionModel>> personGrouped = {};
          final Map<String, double> personBalances = {};
          final Map<String, String> displayNameMap = {};

          for (var txn in allDebts) {
            final rawName = (txn.personId?.trim().isNotEmpty == true)
                ? txn.personId!.trim()
                : ((txn.note?.trim().isNotEmpty == true) ? txn.note!.trim() : 'নামহীন');
            final normalizedName = rawName.toLowerCase();

            if (!personGrouped.containsKey(normalizedName)) {
              personGrouped[normalizedName] = [];
              personBalances[normalizedName] = 0;
              displayNameMap[normalizedName] = rawName;
            }
            personGrouped[normalizedName]!.add(txn);
            
            double delta = 0;
            if (txn.type == 'loan_given') delta = txn.amount;
            if (txn.type == 'loan_collected') delta = -txn.amount;
            if (txn.type == 'loan_taken') delta = -txn.amount;
            if (txn.type == 'loan_repaid') delta = txn.amount;

            personBalances[normalizedName] = personBalances[normalizedName]! + delta;
          }

          final List<_PersonDebtInfo> iWillGet = [];
          final List<_PersonDebtInfo> iWillGive = [];
          final List<_PersonDebtInfo> iSettled = [];

          personBalances.forEach((normalizedName, balance) {
            final info = _PersonDebtInfo(
              name: displayNameMap[normalizedName]!,
              amount: balance.abs(),
              transactions: personGrouped[normalizedName]!
                ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate)),
            );

            if (balance.abs() >= 1.0) {
              if (balance > 0) {
                iWillGet.add(info);
              } else {
                iWillGive.add(info);
              }
            } else {
              iSettled.add(info);
            }
          });

          double netOwedToMe = iWillGet.fold(0, (sum, item) => sum + item.amount);
          double netIOwe = iWillGive.fold(0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      "পাওনা",
                      netOwedToMe,
                      Colors.green,
                      isDark,
                      activeFilter == 'receivable',
                      () => setState(() => activeFilter = activeFilter == 'receivable' ? null : 'receivable'),
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryCard(
                      "দেনা",
                      netIOwe,
                      Colors.red,
                      isDark,
                      activeFilter == 'payable',
                      () => setState(() => activeFilter = activeFilter == 'payable' ? null : 'payable'),
                    ),
                    const SizedBox(width: 8),
                    _buildSummaryCard(
                      "ইতিহাস",
                      iSettled.length.toDouble(),
                      Colors.blueGrey,
                      isDark,
                      activeFilter == 'settled',
                      () => setState(() => activeFilter = activeFilter == 'settled' ? null : 'settled'),
                      isCount: true,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    if (activeFilter == null || activeFilter == 'receivable') ...[
                      if (iWillGet.isNotEmpty) ...[
                        _buildSectionHeader("পাওনা তালিকা (আমি পাব)", Colors.green),
                        ...iWillGet.map((info) => _buildPersonCard(info, Colors.green, isDark)),
                      ] else if (activeFilter == 'receivable')
                        _buildNoDataMessage("কোনো পাওনা নেই"),
                    ],
                    
                    if (activeFilter == null || activeFilter == 'payable') ...[
                      if (iWillGive.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSectionHeader("দেনা তালিকা (আমি দেব)", Colors.red),
                        ...iWillGive.map((info) => _buildPersonCard(info, Colors.red, isDark)),
                      ] else if (activeFilter == 'payable')
                        _buildNoDataMessage("কোনো দেনা নেই"),
                    ],

                    if (activeFilter == null || activeFilter == 'settled') ...[
                      if (iSettled.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSectionHeader("পরিশোধিত হিসাব (ইতিহাস)", Colors.blueGrey),
                        ...iSettled.map((info) => _buildPersonCard(info, Colors.blueGrey, isDark, isHistory: true)),
                      ] else if (activeFilter == 'settled')
                        _buildNoDataMessage("কোনো পরিশোধিত হিসাব নেই"),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNoDataMessage(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Text(msg, style: const TextStyle(color: Colors.grey)),
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
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double value,
    Color color,
    bool isDark,
    bool isActive,
    VoidCallback onTap, {
    bool isCount = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : (isDark ? const Color(0xFF1E1E32) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isActive ? color : (isDark ? Colors.white10 : Colors.transparent),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive ? color : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCount ? value.toInt().toString() : "৳${value.toStringAsFixed(0)}",
                style: TextStyle(
                  color: isActive ? color : (isDark ? Colors.white : Colors.black87),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(_PersonDebtInfo info, Color color, bool isDark, {bool isHistory = false}) {
    final bool isSettling = _settlingPersons.contains(info.name);

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
            info.name.isNotEmpty ? info.name[0].toUpperCase() : "?",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(info.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${info.transactions.length} টি লেনদেন"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "৳${info.amount.toStringAsFixed(0)}",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (!isHistory) ...[
              const SizedBox(width: 8),
              if (isSettling)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                )
              else
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                  onPressed: () => _settleFullBalance(info, color == Colors.green),
                  tooltip: "পুরো হিসাব মিটিয়ে ফেলুন",
                ),
            ],
          ],
        ),
        children: info.transactions.map((t) {
          final bool iGave = (t.type == 'loan_given' || t.type == 'loan_repaid');
          final leadingColor = iGave ? Colors.green : Colors.red;
          final titleText = iGave ? (t.type == 'loan_given' ? "ধারি দিয়েছি" : "পরিশোধ করেছি") 
                                  : (t.type == 'loan_taken' ? "ধারি নিয়েছি" : "ফেরত পেয়েছি");

          return ListTile(
            dense: true,
            leading: Icon(iGave ? Icons.arrow_upward : Icons.arrow_downward, color: leadingColor, size: 16),
            title: Text(titleText, style: const TextStyle(fontSize: 13)),
            subtitle: Text("${t.transactionDate.day}/${t.transactionDate.month}/${t.transactionDate.year}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("৳${t.amount.toStringAsFixed(0)}", 
                  style: TextStyle(color: leadingColor, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => _deleteTransaction(t),
                  tooltip: "মুছে ফেলুন",
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text("কোনো ধারের হিসাব নেই", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _PersonDebtInfo {
  final String name;
  final double amount;
  final List<TransactionModel> transactions;
  _PersonDebtInfo({required this.name, required this.amount, required this.transactions});
}
