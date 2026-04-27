import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String _filterType = "দৈনিক"; // দৈনিক, মাসিক, বার্ষিক, কাস্টম

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  List<TransactionModel> _getFilteredByDate(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    return transactions.where((txn) {
      final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);

      switch (_filterType) {
        case "দৈনিক":
          return txnDate == today;
        case "মাসিক":
          return txn.date.isAfter(monthStart.subtract(const Duration(days: 1)));
        case "বার্ষিক":
          return txn.date.isAfter(yearStart.subtract(const Duration(days: 1)));
        default:
          return true;
      }
    }).toList();
  }

  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (var txn in transactions) {
      final date = txn.date;
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterdayDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );
      final txnDate = DateTime(date.year, date.month, date.day);

      String key;
      if (txnDate == todayDate) {
        key = "আজ";
      } else if (txnDate == yesterdayDate) {
        key = "গতকাল";
      } else {
        key = "${txnDate.day}/${txnDate.month}/${txnDate.year}";
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(txn);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _topBar(isDark),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _transactionService.getTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      "কোনো লেনদেন নেই",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  );
                }

                var dateFiltered = _getFilteredByDate(snapshot.data!);

                if (_searchController.text.isNotEmpty) {
                  final query = _searchController.text.toLowerCase();
                  dateFiltered = dateFiltered
                      .where(
                        (txn) =>
                            txn.category.toLowerCase().contains(query) ||
                            txn.note.toLowerCase().contains(query),
                      )
                      .toList();
                }

                final grouped = _groupByDate(dateFiltered);
                final sortedKeys = grouped.keys.toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  children: [
                    _searchSection(isDark),
                    const SizedBox(height: 20),
                    if (dateFiltered.isEmpty)
                      Center(
                        child: Text(
                          "কোনো মিলিত লেনদেন নেই",
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      )
                    else
                      ...sortedKeys.map((date) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _groupTitle(date),
                            ...grouped[date]!.map((txn) {
                              return _transactionItem(
                                isDark,
                                icon: _getCategoryIcon(txn.category),
                                title: txn.category,
                                subtitle:
                                    "${txn.date.hour}:${txn.date.minute.toString().padLeft(2, '0')} • ${txn.note}",
                                amount:
                                    "${txn.isExpense ? '-' : '+'}\৳${txn.amount.toStringAsFixed(2)}",
                                isExpense: txn.isExpense,
                              );
                            }).toList(),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "খাবার":
        return Icons.restaurant;
      case "কেনাকাটা":
        return Icons.shopping_bag;
      case "পরিবহন":
        return Icons.directions_car;
      case "বিনোদন":
        return Icons.movie;
      case "স্বাস্থ্য":
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }

  Widget _topBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      color: isDark ? const Color(0xFF111125) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ?? "https://i.pravatar.cc/300",
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _auth.currentUser?.displayName ?? "ব্যবহারকারী",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFE2E0FC) : Colors.black87,
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Color(0xFF60DCB2)),
          ),
        ],
      ),
    );
  }

  Widget _searchSection(bool isDark) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "লেনদেন খুঁজুন...",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: isDark ? const Color(0xFF333348) : Colors.grey[200],
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ["দৈনিক", "মাসিক", "বার্ষিক", "কাস্টম"].map((filter) {
              final isActive = _filterType == filter;
              return GestureDetector(
                onTap: () => setState(() => _filterType = filter),
                child: _filterChip(filter, isActive, isDark),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String text, bool active, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(text),
        backgroundColor: active
            ? const Color(0xFF60DCB2)
            : (isDark ? const Color(0xFF1E1E32) : Colors.grey[300]),
        labelStyle: TextStyle(
          color: active
              ? Colors.black
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _groupTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _transactionItem(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isExpense,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E32) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF60DCB2).withOpacity(.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF60DCB2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isExpense ? Colors.red : const Color(0xFF60DCB2),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
