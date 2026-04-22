import 'package:flutter/material.dart';
import 'package:hisab_app/src/features/profile_screen.dart';
import 'package:hisab_app/src/features/report_screen.dart';

import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final screens = const [
    DashboardScreen(),
    HistoryScreen(),
    AddTransactionScreen(),
    ReportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: const Color(0xFF111125),
        selectedItemColor: const Color(0xFF60DCB2),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "ড্যাশবোর্ড",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "ইতিহাস"),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: "যোগ করুন",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "রিপোর্ট",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "প্রোফাইল"),
        ],
      ),
    );
  }
}
