import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/widgets/auth_check.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0C1F) : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF60DCB2).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Color(0xFF60DCB2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "হিসাব অ্যাপ",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "আপনার প্রতিদিনের ডিজিটাল হিসাবরক্ষক",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF60DCB2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
