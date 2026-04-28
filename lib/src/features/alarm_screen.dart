import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/model/alarm_model.dart';
import '../../core/model/note_model.dart';
import '../../core/services/alarm_service.dart';
import '../../core/services/note_service.dart';
import '../../core/services/notification_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {

  final NoteService _noteService = NoteService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _weekDays = ["সোম", "মঙ্গল", "বুধ", "বৃহস্পতি", "শুক্র", "শনি", "রবি"];

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification();
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatOnlyDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showNoteBottomSheet({NoteModel? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);

    DateTime selectedDate = note?.createdAt ?? DateTime.now();
    DateTime? alarmTime = note?.alarmTime;

    List<int> selectedRepeatDays =
    note?.repeatDays != null ? List.from(note!.repeatDays!) : [];

    final dateController =
    TextEditingController(text: _formatOnlyDate(selectedDate));

    final alarmController = TextEditingController(
      text: alarmTime != null ? _formatDate(alarmTime!) : "অ্যালার্ম নেই",
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark =
                Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E32) : Colors.white,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Title
                    Text(
                      note == null ? "নতুন নোট" : "নোট এডিট",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    /// Note Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "শিরোনাম",
                        filled: true,
                        fillColor:
                        isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Date Picker
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                                picked.year, picked.month, picked.day);
                            dateController.text =
                                _formatOnlyDate(selectedDate);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "তারিখ নির্বাচন করুন",
                        suffixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor:
                        isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// Alarm Picker
                    TextField(
                      controller: alarmController,
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: alarmTime ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );

                        if (pickedDate != null) {
                          final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                alarmTime ?? DateTime.now()),
                          );

                          if (pickedTime != null) {
                            setState(() {
                              alarmTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              alarmController.text =
                                  _formatDate(alarmTime!);
                            });
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "অ্যালার্ম সেট করুন",
                        suffixIcon: alarmTime != null
                            ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.red),
                          onPressed: () {
                            setState(() {
                              alarmTime = null;
                              alarmController.text =
                              "অ্যালার্ম নেই";
                            });
                          },
                        )
                            : const Icon(Icons.alarm),
                        filled: true,
                        fillColor:
                        isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    /// Repeat Days
                    if (alarmTime != null) ...[
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("রিপিট দিনগুলো"),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final dayIndex = index + 1;
                          final isSelected =
                          selectedRepeatDays.contains(dayIndex);

                          return FilterChip(
                            label: Text(_weekDays[index]),
                            selected: isSelected,
                            selectedColor: const Color(0xFF60DCB2),
                            onSelected: (selected) {
                              setState(() {
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
                    ],

                    const SizedBox(height: 15),

                    /// Content
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: "বিস্তারিত...",
                        filled: true,
                        fillColor:
                        isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// Save Button
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
                          if (titleController.text.isEmpty) return;

                          final userId =
                              _auth.currentUser?.uid ?? '';
                          final noteId =
                              note?.id ?? const Uuid().v4();

                          final newNote = NoteModel(
                            id: noteId,
                            userId: userId,
                            title: titleController.text,
                            content: contentController.text,
                            createdAt: selectedDate,
                            updatedAt: DateTime.now(),
                            alarmTime: alarmTime,
                            repeatDays: selectedRepeatDays.isEmpty
                                ? null
                                : selectedRepeatDays,
                          );

                          /// Save Note
                          if (note == null) {
                            await _noteService.addNote(newNote);
                          } else {
                            await _noteService.updateNote(newNote);
                          }

                          /// 🔔 Notification Logic (IMPORTANT)
                          if (alarmTime != null) {
                            await _notificationService
                                .cancelNotification(noteId.hashCode);

                            for (int i = 1; i <= 7; i++) {
                              await _notificationService
                                  .cancelNotification(noteId.hashCode + i);
                            }

                            if (selectedRepeatDays.isEmpty) {
                              if (alarmTime!.isAfter(DateTime.now())) {
                                await _notificationService
                                    .scheduleNotification(
                                  noteId.hashCode,
                                  "নোট: ${titleController.text}",
                                  contentController.text,
                                  alarmTime!,
                                );
                              }
                            } else {
                              await _notificationService
                                  .scheduleWeeklyNotifications(
                                noteId.hashCode,
                                "নোট: ${titleController.text}",
                                contentController.text,
                                TimeOfDay.fromDateTime(alarmTime!),
                                selectedRepeatDays,
                              );
                            }
                          } else {
                            await _notificationService
                                .cancelNotification(noteId.hashCode);

                            for (int i = 1; i <= 7; i++) {
                              await _notificationService
                                  .cancelNotification(noteId.hashCode + i);
                            }
                          }

                          if (mounted) Navigator.pop(context);
                        },
                        child: Text(
                          note == null ? "সংরক্ষণ" : "আপডেট",
                          style: const TextStyle(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("অফলাইন অ্যালার্ম", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'alarm_screen_fab',
        onPressed: () => _showNoteBottomSheet(),
        backgroundColor: const Color(0xFF60DCB2),
        child: const Icon(Icons.add_alarm, color: Color(0xFF003829)),
      ),
    );
  }
}
