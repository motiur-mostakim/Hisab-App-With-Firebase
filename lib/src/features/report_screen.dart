import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert' show utf8;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/model/transaction_model.dart';
import '../../core/services/savepdf.dart';
import '../../core/services/transaction_service.dart';
import '../../core/services/dashboard_calculations.dart';
import '../../core/services/report_generator_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with AutomaticKeepAliveClientMixin {
  final TransactionService _transactionService = TransactionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ReportGeneratorService _reportGenerator = ReportGeneratorService();
  String _reportType = "মাসিক";
  bool _isGeneratingPdf = false;

  @override
  bool get wantKeepAlive => true;
  Future<void> _downloadPdfReport(List<TransactionModel> transactions) async {
    try {
      setState(() => _isGeneratingPdf = true);

      final filteredTransactions = _filterByReportType(transactions);

      final stats = _calculateStats(filteredTransactions);

      final categoryTotals = _getCategoryTotals(filteredTransactions, true);

      final pdfFile = await _reportGenerator.generatePdfReport(
        transactions: filteredTransactions,
        reportType: _reportType,
        totalIncome: stats['income']!,
        totalExpense: stats['expense']!,
        netWorth: stats['balance']!,
        categoryTotals: categoryTotals,
      );

      final downloadsDir = Directory('/storage/emulated/0/Download');

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName =
          'Hisab_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final finalPath = uniqueFilePath(downloadsDir.path, fileName);

      final newFile = await pdfFile.copy(finalPath);

      setState(() => _isGeneratingPdf = false);

      if (mounted) {
        _showSnackbar('PDF Downloads folder এ save হয়েছে');

        print("Saved Path => ${newFile.path}");
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      _showSnackbar('Error: $e');
      print("Errors: $e");
    }
  }

  Future<void> _openFileManager(String filePath) async {
    try {
      if (Platform.isAndroid) {
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'আর্থিক রিপোর্ট ডাউনলোড হয়েছে');
      }
    } catch (e) {
      print('File manager খোলার error: $e');
    }
  }

  Future<void> _sendReportViaEmail(List<TransactionModel> transactions) async {
    try {
      setState(() => _isGeneratingPdf = true);

      final filteredTransactions = _filterByReportType(transactions);
      final stats = _calculateStats(filteredTransactions);
      final categoryTotals = _getCategoryTotals(filteredTransactions, true);
      final file = await _reportGenerator.generatePdfReport(
        transactions: filteredTransactions,
        reportType: _reportType,
        totalIncome: stats['income']!,
        totalExpense: stats['expense']!,
        netWorth: stats['balance']!,
        categoryTotals: categoryTotals,
      );

      setState(() => _isGeneratingPdf = false);

      if (mounted) {
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'আমার আর্থিক রিপোর্ট ($_reportType)');
        _showSnackbar('রিপোর্ট শেয়ার করার জন্য প্রস্তুত');
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      _showSnackbar('Email পাঠাতে error: $e');
    }
  }

  Future<void> _exportCsvReport(List<TransactionModel> transactions) async {
    try {
      setState(() => _isGeneratingPdf = true);

      final filteredTransactions = _filterByReportType(transactions);

      String csvContent = 'তারিখ,বিভাগ,বিবরণ,ধরন,পরিমাণ\n';

      for (var txn in filteredTransactions) {
        final date =
            '${txn.transactionDate.year}-${txn.transactionDate.month.toString().padLeft(2, '0')}-${txn.transactionDate.day.toString().padLeft(2, '0')}';
        final category = txn.category ?? 'অন্যান্য';
        final type = txn.type == 'income' ? 'আয়' : 'ব্যয়';
        final note = txn.note ?? 'No description';
        csvContent += '$date,$category,$note,$type,${txn.amount}\n';
      }
      final directory =
          await getDownloadsDirectory() ?? await getTemporaryDirectory();
      final fileName =
          'Hisab_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent, encoding: utf8);
      print("Directory: ${directory.path}");
      setState(() => _isGeneratingPdf = false);

      if (mounted) {
        _showSnackbar('CSV রিপোর্ট ডাউনলোড হয়েছে: ${file.path}');
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'আর্থিক রিপোর্ট (CSV)');
      }
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      _showSnackbar('CSV export এ error: $e');
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF60DCB2),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Map<String, double> _getCategoryTotals(
    List<TransactionModel> transactions,
    bool isExpense,
  ) {
    final categoryTotals = <String, double>{};
    for (var txn in transactions) {
      final matchesType =
          (isExpense && txn.type == 'expense') ||
          (!isExpense && txn.type == 'income');
      if (matchesType) {
        final cat = txn.category ?? 'অন্যান্য';
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + txn.amount;
      }
    }
    return categoryTotals;
  }

  List<TransactionModel> _filterByReportType(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final yearStart = DateTime(now.year, 1, 1);

    if (_reportType == "মাসিক") {
      return transactions
          .where(
            (txn) => txn.transactionDate.isAfter(
              monthStart.subtract(const Duration(days: 1)),
            ),
          )
          .toList();
    } else {
      return transactions
          .where(
            (txn) => txn.transactionDate.isAfter(
              yearStart.subtract(const Duration(days: 1)),
            ),
          )
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                      child: Text(
                        "কোনো ডেটা নেই",
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    );
                  }

                  final allTransactions = snapshot.data!;
                  final filteredTransactions = _filterByReportType(
                    allTransactions,
                  );
                  final netWorth = DashboardCalculations.calculateNetWorth(
                    allTransactions,
                  );
                  final stats = _calculateStats(filteredTransactions);
                  final categoryTotals = _getCategoryTotals(
                    filteredTransactions,
                    true,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTotalAssetCard(netWorth, isDark),
                        const SizedBox(height: 20),
                        _buildTopSection(isDark),
                        const SizedBox(height: 20),
                        _buildMainChart(allTransactions, isDark),
                        const SizedBox(height: 20),
                        _buildTopCategories(categoryTotals, isDark),
                        const SizedBox(height: 20),
                        _buildExportOptions(allTransactions, isDark),
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
      if (txn.type == 'expense') {
        expense += txn.amount;
      } else if (txn.type == 'income') {
        income += txn.amount;
      }
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
              Icon(
                Icons.notifications,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  _auth.currentUser?.photoURL ??
                      "https://lh3.googleusercontent.com/a/ACg8ocIxFdhaqwmoBefje8HCKUATauYQpeQyecV7wZCCyQbvLOXMk8lHKA=s432-c-no",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAssetCard(double netWorth, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60DCB2), Color(0xFF009672)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60DCB2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "মোট সম্পদ (Total Asset)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "৳${netWorth.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "সারসংক্ষেপ",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _chip("মাসিক", _reportType == "মাসিক", isDark),
            _chip("বার্ষিক", _reportType == "বার্ষিক", isDark),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.share,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
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
          color: active
              ? const Color(0xFF60DCB2)
              : (isDark ? const Color(0xFF1E1E32) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active
                ? Colors.black
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(List<TransactionModel> transactions, bool isDark) {
    final monthlyData = _getMonthlyHistory(transactions);
    final maxAmount = monthlyData.values
        .map((e) => e['income']! > e['expense']! ? e['income']! : e['expense']!)
        .fold(0.0, (max, e) => e > max ? e : max);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "আয় বনাম ব্যয় (বিগত ৬ মাস)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: monthlyData.entries.map((entry) {
              final incomeHeight = maxAmount > 0
                  ? (entry.value['income']! / maxAmount) * 120
                  : 0.0;
              final expenseHeight = maxAmount > 0
                  ? (entry.value['expense']! / maxAmount) * 120
                  : 0.0;

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 10,
                        height: incomeHeight + 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF60DCB2),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 10,
                        height: expenseHeight + 5,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.8),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegend("আয়", const Color(0xFF60DCB2), isDark),
              const SizedBox(width: 20),
              _chartLegend("ব্যয়", Colors.redAccent, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Map<String, Map<String, double>> _getMonthlyHistory(
    List<TransactionModel> transactions,
  ) {
    final Map<String, Map<String, double>> history = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = _getMonthName(date.month);
      history[monthName] = {'income': 0.0, 'expense': 0.0};
    }

    for (var txn in transactions) {
      final date = txn.transactionDate;
      final monthName = _getMonthName(date.month);
      if (history.containsKey(monthName)) {
        if (txn.type == 'income') {
          history[monthName]!['income'] =
              (history[monthName]!['income'] ?? 0) + txn.amount;
        } else if (txn.type == 'expense') {
          history[monthName]!['expense'] =
              (history[monthName]!['expense'] ?? 0) + txn.amount;
        }
      }
    }
    return history;
  }

  String _getMonthName(int month) {
    const names = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return names[month - 1];
  }

  Widget _buildTopCategories(Map<String, double> categoryTotals, bool isDark) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "শীর্ষ ব্যয় বিভাগ",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedCategories.isEmpty)
            const Text("কোনো তথ্য নেই", style: TextStyle(color: Colors.grey))
          else
            ...sortedCategories.take(3).map((entry) {
              return _category(
                entry.key,
                "৳${entry.value.toStringAsFixed(2)}",
                Colors.redAccent,
                isDark,
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _category(String title, String amount, Color color, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(.1),
        child: Icon(Icons.arrow_downward, color: color, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExportOptions(List<TransactionModel> transactions, bool isDark) {
    return Column(
      children: [
        _exportTile(
          Icons.picture_as_pdf,
          "PDF রিপোর্ট ডাউনলোড",
          isDark,
          _isGeneratingPdf,
          () => _downloadPdfReport(transactions),
        ),
        // _exportTile(
        //   Icons.table_chart,
        //   "CSV রিপোর্ট ডাউনলোড",
        //   isDark,
        //   _isGeneratingPdf,
        //   () => _exportCsvReport(transactions),
        // ),
        _exportTile(
          Icons.mail,
          "ইমেইল রিপোর্ট পাঠান",
          isDark,
          _isGeneratingPdf,
          () => _sendReportViaEmail(transactions),
        ),
      ],
    );
  }

  void _showActionSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF60DCB2),
      ),
    );
  }

  Widget _exportTile(
    IconData icon,
    String title,
    bool isDark,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return Opacity(
      opacity: isLoading ? 0.6 : 1.0,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
              Text(
                title,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
