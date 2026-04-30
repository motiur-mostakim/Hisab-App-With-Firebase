import 'package:flutter/material.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/transaction_service.dart';

class DebtHistoryScreen extends StatefulWidget {
  const DebtHistoryScreen({super.key});

  @override
  State<DebtHistoryScreen> createState() => _DebtHistoryScreenState();
}

class _DebtHistoryScreenState extends State<DebtHistoryScreen> {
  // বর্তমানে কোন ক্যাটাগরি দেখাচ্ছে তা ট্র্যাক করার জন্য (null = সব, true = পাওনা, false = দেনা)
  bool? showOwedToMe;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TransactionService transactionService = TransactionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ধারের বিস্তারিত হিসাব",
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


          if (allDebts.isEmpty) {
            return _buildEmptyState();
          }

          // ১. নাম অনুযায়ী লেনদেন গ্রুপ করা (Case-insensitive matching)
          final Map<String, List<TransactionModel>> personGrouped = {};
          final Map<String, double> personBalances = {};
          final Map<String, String> displayNameMap = {}; // অরিজিনাল নাম সংরক্ষণের জন্য

          for (var txn in allDebts) {
            final rawName = txn.note.trim().isEmpty ? "নামহীন" : txn.note.trim();
            final normalizedName = rawName.toLowerCase(); // ছোট হাতের অক্ষরে রূপান্তর

            if (!personGrouped.containsKey(normalizedName)) {
              personGrouped[normalizedName] = [];
              personBalances[normalizedName] = 0;
              displayNameMap[normalizedName] = rawName; // প্রথমবার যে নাম পাবে সেটিই দেখাবে
            }
            personGrouped[normalizedName]!.add(txn);

            // Expense = আমি দিয়েছি (পাওনা বাড়ে)
            // Income = আমি নিয়েছি (দেনা বাড়ে / পাওনা কমে)
            personBalances[normalizedName] = personBalances[normalizedName]! + (txn.isExpense ? txn.amount : -txn.amount);
          }

          // ২. পাওনা ও দেনা আলাদা লিস্টে ভাগ করা (ব্যালেন্স ০ হলে পুরোপুরি বাদ দেওয়া)
          final List<_PersonDebtInfo> iWillGet = []; // পাওনা (আমি পাব)
          final List<_PersonDebtInfo> iWillGive = []; // দেনা (আমি দেব)

          personBalances.forEach((normalizedName, balance) {
            // ব্যালেন্স যদি ১ টাকার কম হয় (যেমন ০.০১), তবে সেটাকে ০ ধরা হবে
            if (balance.abs() >= 1.0) {
              final info = _PersonDebtInfo(
                name: displayNameMap[normalizedName]!,
                amount: balance.abs(),
                transactions: personGrouped[normalizedName]!..sort((a, b) => b.date.compareTo(a.date)),
              );
              if (balance > 0) {
                iWillGet.add(info);
              } else {
                iWillGive.add(info);
              }
            }
          });

          double totalGet = iWillGet.fold(0, (sum, item) => sum + item.amount);
          double totalGive = iWillGive.fold(0, (sum, item) => sum + item.amount);

          // ৩. বর্তমান ফিল্টার অনুযায়ী লিস্ট তৈরি
          List<_PersonDebtInfo> displayList = [];
          if (showOwedToMe == true) {
            displayList = iWillGet;
          } else if (showOwedToMe == false) {
            displayList = iWillGive;
          } else {
            displayList = [...iWillGet, ...iWillGive];
          }

          return Column(
            children: [
              // ৪. সামারি কার্ড
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
                            () => setState(() => showOwedToMe = showOwedToMe == true ? null : true)
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                        "মোট দেনা",
                        netIOwe,
                        Colors.red,
                        isDark,
                        showOwedToMe == false,
                            () => setState(() => showOwedToMe = showOwedToMe == false ? null : false)
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ব্যক্তিগত ধারের তালিকা",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),

              Expanded(
                child: displayList.isEmpty
                    ? Center(
                    child: Text(
                        showOwedToMe == null ? "সব ধার পরিশোধ করা হয়েছে ✅" : "এই তালিকায় কেউ নেই",
                        style: const TextStyle(color: Colors.grey)
                    )
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final info = displayList[index];
                    final isPawn = iWillGet.any((p) => p.name == info.name);
                    return _buildPersonCard(info, isPawn ? Colors.green : Colors.red, isDark);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, bool isDark, bool isActive, VoidCallback onTap) {
    // যদি অ্যামাউন্ট ০ হয় তবে সেটি আবছা দেখাবে
    final bool isZero = amount < 1;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : (isDark ? const Color(0xFF1E1E32) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color.withOpacity(0.5) : (isDark ? Colors.white10 : Colors.transparent),
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
                      fontWeight: FontWeight.bold
                  )
              ),
              const SizedBox(height: 6),
              Text(
                "৳${amount.toStringAsFixed(0)}",
                style: TextStyle(
                    color: isZero ? Colors.grey : (isActive ? color : (isDark ? Colors.white : Colors.black87)),
                    fontSize: 20,
                    fontWeight: FontWeight.bold
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
          child: Text(info.name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(info.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${info.transactions.length} টি লেনদেন"),
        trailing: Text(
          "৳${info.amount.toStringAsFixed(0)}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: info.transactions.map((t) => ListTile(
          dense: true,
          title: Text(t.isExpense ? "দিয়েছি / পরিশোধ" : "নিয়েছি / ফেরত"),
          subtitle: Text("${t.date.day}/${t.date.month}/${t.date.year}"),
          trailing: Text(
            "৳${t.amount.toStringAsFixed(0)}",
            style: TextStyle(color: t.isExpense ? Colors.green : Colors.red, fontWeight: FontWeight.w600),
          ),
        )).toList(),
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