import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/model/alarm_model.dart';
import '../../core/services/alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
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
                          var dt = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            picked.hour,
                            picked.minute,
                          );

                          // যদি সময়টি অলরেডি পার হয়ে যায়, তবে আগামীকালের জন্য সেট করা
                          if (dt.isBefore(now)) {
                            dt = dt.add(const Duration(days: 1));
                          }
                          selectedTime = dt;
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
                        if (mounted) Navigator.pop(context);
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
        title: const Text(
          "অফলাইন অ্যালার্ম",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _alarms.isEmpty
          ? const Center(
              child: Text(
                "কোনো অ্যালার্ম সেট করা নেই",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: isDark ? const Color(0xFF1E1E32) : Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    onTap: () => _showAlarmDialog(alarm: alarm),
                    title: Text(
                      _formatTime(alarm.dateTime),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alarm.label, style: const TextStyle(fontSize: 16)),
                        if (alarm.repeatDays.isNotEmpty)
                          Text(
                            "রিপিট: ${alarm.repeatDays.length} দিন",
                            style: const TextStyle(
                              color: Color(0xFF60DCB2),
                              fontSize: 12,
                            ),
                          ),
                      ],
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
                                if (mounted) Navigator.pop(context);
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
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'alarm_screen_fab',
        onPressed: () => _showAlarmDialog(),
        backgroundColor: const Color(0xFF60DCB2),
        child: const Icon(Icons.add_alarm, color: Color(0xFF003829)),
      ),
    );
  }
}
