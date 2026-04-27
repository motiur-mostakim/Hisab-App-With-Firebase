import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hisab_app/main.dart';
import 'package:hisab_app/src/features/edit_profile_screen.dart';
import 'package:hisab_app/src/features/debt_history_screen.dart';
import 'package:uuid/uuid.dart';

import '../../core/model/alarm_model.dart';
import '../../core/services/alarm_service.dart';
import '../../core/services/transaction_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final TransactionService _transactionService = TransactionService();
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _alarmService.getAlarms();
    setState(() {
      _alarms = alarms;
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? "PM" : "AM";
    return "${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period";
  }

  void _showAlarmDialog({AlarmModel? alarm}) {
    final labelController = TextEditingController(text: alarm?.label);
    DateTime selectedTime = alarm?.dateTime ?? DateTime.now();
    List<int> selectedRepeatDays = alarm?.repeatDays != null
        ? List.from(alarm!.repeatDays)
        : [];
    final List<String> weekDays = [
      "সোম",
      "মঙ্গল",
      "বুধ",
      "বৃহস্পতি",
      "শুক্র",
      "শনি",
      "রবি",
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E32) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    alarm == null ? "নতুন অ্যালার্ম" : "অ্যালার্ম এডিট",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedTime),
                      );
                      if (picked != null) {
                        setModalState(() {
                          final now = DateTime.now();
                          selectedTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 40,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF60DCB2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _formatTime(selectedTime),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF60DCB2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: labelController,
                    decoration: InputDecoration(
                      hintText: "অ্যালার্মের নাম (যেমন: নামাজ)",
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("রিপিট দিনগুলো নির্বাচন করুন:"),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(7, (index) {
                      final dayIndex = index + 1;
                      final isSelected = selectedRepeatDays.contains(dayIndex);
                      return FilterChip(
                        label: Text(
                          weekDays[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.black
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFF60DCB2),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedRepeatDays.add(dayIndex);
                            } else {
                              selectedRepeatDays.remove(dayIndex);
                            }
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60DCB2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () async {
                        final newAlarm = AlarmModel(
                          id: alarm?.id ?? const Uuid().v4(),
                          label: labelController.text.isEmpty
                              ? "অ্যালার্ম"
                              : labelController.text,
                          dateTime: selectedTime,
                          repeatDays: selectedRepeatDays,
                        );
                        await _alarmService.saveAlarm(newAlarm);
                        _loadAlarms();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "সেভ করুন",
                        style: TextStyle(
                          color: Color(0xFF003829),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

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
            // ... (Existing Profile UI)
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
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
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

            // 🔥 ALARM SECTION
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.alarm, color: Color(0xFF60DCB2)),
                          SizedBox(width: 8),
                          Text(
                            "অফলাইন অ্যালার্ম",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _showAlarmDialog(),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF60DCB2),
                        ),
                      ),
                    ],
                  ),
                  if (_alarms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "কোনো অ্যালার্ম সেট করা নেই",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        final alarm = _alarms[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _formatTime(alarm.dateTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Text(
                            alarm.label +
                                (alarm.repeatDays.isNotEmpty ? " (রিপিট)" : ""),
                          ),
                          trailing: Switch(
                            value: alarm.isActive,
                            activeColor: const Color(0xFF60DCB2),
                            onChanged: (v) async {
                              await _alarmService.toggleAlarm(alarm.id);
                              _loadAlarms();
                            },
                          ),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("অ্যালার্ম মুছুন?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("না"),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await _alarmService.deleteAlarm(alarm.id);
                                      _loadAlarms();
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      "হ্যাঁ",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                        mode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: const Color(0xFF60DCB2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        mode == ThemeMode.dark
                            ? "ডার্ক মোড (On)"
                            : "ডার্ক মোড (Off)",
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: mode == ThemeMode.dark,
                        onChanged: (v) {
                          themeNotifier.value = v
                              ? ThemeMode.dark
                              : ThemeMode.light;
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
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
