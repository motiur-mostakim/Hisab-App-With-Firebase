import 'package:flutter/material.dart';import '../../../core/services/transaction_service.dart';

class DashboardSummaryWidget extends StatelessWidget {
  final TransactionService transactionService;

  const DashboardSummaryWidget({super.key, required this.transactionService});

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
        final cashBalance = (data['cashBalance'] ?? 0.0) as double;
        final debt = (data['debt'] ?? 0.0) as double;
        final receivable = (data['receivable'] ?? 0.0) as double;
        final netWorth = (data['netWorth'] ?? 0.0) as double;
        final totalIncome = (data['totalIncome'] ?? 0.0) as double;
        final totalExpense = (data['totalExpense'] ?? 0.0) as double;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF009672).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "নগদ ব্যালেন্স",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                  FittedBox(
                    child: Text(
                      "৳${cashBalance.toStringAsFixed(0)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.diamond_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "মোট সম্পদ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "৳${netWorth.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _CardStatItem(
                        label: "মোট আয়",
                        amount: totalIncome,
                        icon: Icons.arrow_downward_rounded,
                        iconColor: Colors.white,
                        bgColor: Colors.white.withOpacity(0.2),
                      ),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _CardStatItem(
                        label: "মোট ব্যয়",
                        amount: totalExpense,
                        icon: Icons.arrow_upward_rounded,
                        iconColor: Colors.white,
                        bgColor: Colors.white.withOpacity(0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (receivable > 0 || debt > 0) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (receivable > 0)
                    _CompactStatItem(
                      label: "পাব",
                      amount: receivable,
                      color: Colors.blue,
                      icon: Icons.call_received_rounded,
                      isDark: isDark,
                    ),
                  if (receivable > 0 && debt > 0) const SizedBox(width: 12),
                  if (debt > 0)
                    _CompactStatItem(
                      label: "দিব",
                      amount: debt,
                      color: Colors.orange,
                      icon: Icons.call_made_rounded,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CardStatItem extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _CardStatItem({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              "৳${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactStatItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _CompactStatItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E32) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    "৳${amount.toStringAsFixed(0)}",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}