import 'package:flutter/material.dart';
import 'package:hisab_app/src/features/note_screen.dart';
import 'package:hisab_app/src/features/profile_screen.dart';
import 'package:hisab_app/src/features/report_screen.dart';

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
    NoteScreen(),
    ReportScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF111125) : Colors.white,
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
            icon: Icon(Icons.note_alt),
            label: "নোট",
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
