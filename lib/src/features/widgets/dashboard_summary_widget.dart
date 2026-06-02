import 'package:flutter/material.dart';
import '../../../core/services/transaction_service.dart';

class DashboardSummaryWidget extends StatelessWidget {
  final TransactionService transactionService;

  const DashboardSummaryWidget({
    super.key,
    required this.transactionService,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<Map<String, dynamic>>(
      stream: transactionService.getDashboardData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final cashBalance = data['cashBalance'] as double;
        final debt = data['debt'] as double;
        final receivable = data['receivable'] as double;
        final netWorth = data['netWorth'] as double;
        final totalIncome = data['totalIncome'] as double;
        final totalExpense = data['totalExpense'] as double;

        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF60DCB2),
                      Color(0xFF009672),
                    ],
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "নগদ ব্যালেন্স",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "৳${cashBalance.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white.withOpacity(0.6),
                          size: 35,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BalanceInfo(
                          label: "আয়",
                          amount: totalIncome,
                          isDark: isDark,
                        ),
                        _BalanceInfo(
                          label: "ব্যয়",
                          amount: totalExpense,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if(receivable > 0)
                  Expanded(
                    child: _LoanCard(
                      title: "আমি পাব",
                      subtitle: "ঋণ প্রাপ্য",
                      amount: receivable,
                      icon: Icons.trending_up,
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                  ),
                  if(receivable > 0)
                  const SizedBox(width: 12),
                  if(debt > 0)
                  Expanded(
                    child: _LoanCard(
                      title: "আমি দিব",
                      subtitle: "ঋণ বকেয়া",
                      amount: debt,
                      icon: Icons.trending_down,
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if(debt > 0 || receivable > 0)
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E32).withOpacity(0.7)
                      : Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "মোট সম্পদ",
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "৳${netWorth.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.diamond,
                          color: Colors.amber[600],
                          size: 40,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "নগদ ব্যালেন্স + প্রাপ্য - বকেয়া",
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BalanceInfo extends StatelessWidget {
  final String label;
  final double amount;
  final bool isDark;

  const _BalanceInfo({
    required this.label,
    required this.amount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "৳${amount.toStringAsFixed(0)}",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _LoanCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? color.withOpacity(0.15)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Icon(
                icon,
                color: color.withOpacity(0.6),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "৳${amount.toStringAsFixed(2)}",
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

