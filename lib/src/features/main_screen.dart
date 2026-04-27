import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _showExitDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool shouldExit =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "অ্যাপ বন্ধ করবেন?",
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              "আপনি কি নিশ্চিতভাবে অ্যাপ থেকে বের হতে চান?",
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("না", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF60DCB2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "হ্যাঁ",
                  style: TextStyle(
                    color: Color(0xFF003829),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        if (currentIndex != 0) {
          setState(() {
            currentIndex = 0;
          });
        } else {
          await _showExitDialog(context);
        }
      },
      child: Scaffold(
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
            BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: "নোট"),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: "রিপোর্ট",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "প্রোফাইল",
            ),
          ],
        ),
      ),
    );
  }
}
