import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hisab_app/main.dart';
import 'package:hisab_app/src/features/edit_profile_screen.dart';
import 'package:hisab_app/src/features/debt_history_screen.dart';
import 'package:hisab_app/src/features/alarm_screen.dart';
import '../../core/services/transaction_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "প্রোফাইল",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE2E0FC) : Colors.black87,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings, color: Color(0xFF60DCB2)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF60DCB2), Color(0xFF009672)],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: NetworkImage(
                      auth.currentUser?.photoURL ?? "https://i.pravatar.cc/300",
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF60DCB2),
                    ),
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              auth.currentUser?.displayName ?? "ব্যবহারকারী",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE2E0FC) : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.currentUser?.email ?? "",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            /// 🔥 MENU ITEMS
            _menuItem(
              Icons.person,
              "প্রোফাইল এডিট করুন",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
            ),
            _menuItem(
              Icons.handshake,
              "ধারের হিসাব",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebtHistoryScreen(),
                ),
              ),
            ),
            _menuItem(
              Icons.alarm,
              "অ্যালার্ম",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AlarmScreen(),
                ),
              ),
            ),
            _menuItem(Icons.notifications, "নোটিফিকেশন"),
            _menuItem(Icons.payment, "মুদ্রা সেটিংস", trailing: "BDT"),
            _menuItem(Icons.lock, "নিরাপত্তা"),
            const SizedBox(height: 10),

            /// 🔥 DARK MODE SWITCH
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (_, mode, __) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                        color: const Color(0xFF60DCB2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mode == ThemeMode.dark ? "ডার্ক মোড (On)" : "ডার্ক মোড (Off)",
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      ),
                      const Spacer(),
                      Switch(
                        value: mode == ThemeMode.dark,
                        onChanged: (v) {
                          themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                        },
                        activeColor: const Color(0xFF60DCB2),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            /// 🔥 LOGOUT
            InkWell(
              onTap: () async {
                await auth.signOut();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text(
                      "লগআউট",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title, {
    String? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF60DCB2)),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
