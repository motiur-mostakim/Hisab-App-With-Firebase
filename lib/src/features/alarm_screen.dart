import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/model/note_model.dart';
import '../../core/services/note_services_for_local_database.dart';
import '../../core/services/notification_service.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final NoteServicesForLocalDatabase _noteService =
      NoteServicesForLocalDatabase();
  final NotificationService _notificationService = NotificationService();
  List<NoteModel> _notes = [];

  final List<String> _weekDays = [
    "সোম",
    "মঙ্গল",
    "বুধ",
    "বৃহস্পতি",
    "শুক্র",
    "শনি",
    "রবি",
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final data = await _noteService.getNotes();
    setState(() {
      _notes = data;
    });
  }

  Future<void> _deleteNote(NoteModel note) async {
    await _noteService.deleteNote(note.id);
    await _notificationService.cancelNotification(note.id.hashCode);
    for (int i = 1; i <= 7; i++) {
      await _notificationService.cancelNotification(note.id.hashCode + i);
    }
    await _loadNotes();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? "PM" : "AM";
    return "${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period";
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showNoteBottomSheet({NoteModel? note}) {
    final titleController = TextEditingController(text: note?.title);
    DateTime? alarmTime = note?.alarmTime;
    List<int> selectedRepeatDays = note?.repeatDays != null
        ? List.from(note!.repeatDays!)
        : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
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
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      note == null ? "নতুন অ্যালার্ম" : "অ্যালার্ম এডিট",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),

                    /// Time & Date Picker Trigger
                    InkWell(
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
                              alarmTime ?? DateTime.now(),
                            ),
                          );
                          if (pickedTime != null) {
                            setModalState(() {
                              alarmTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 30,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF60DCB2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF60DCB2).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _formatTime(alarmTime ?? DateTime.now()),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF60DCB2),
                              ),
                            ),
                            Text(
                              _formatDate(alarmTime ?? DateTime.now()),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "অ্যালার্মের নাম (যেমন: নামাজ)",
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.label_outline,
                          color: Color(0xFF60DCB2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "রিপিট দিনগুলো নির্বাচন করুন:",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        final dayIndex = index + 1;
                        final isSelected = selectedRepeatDays.contains(
                          dayIndex,
                        );
                        return ChoiceChip(
                          label: Text(_weekDays[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedRepeatDays.add(dayIndex);
                              } else {
                                selectedRepeatDays.remove(dayIndex);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF60DCB2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF60DCB2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {

                          final finalAlarmTime = alarmTime ?? DateTime.now();

                          final noteId = note?.id ?? const Uuid().v4();
                          final newNote = NoteModel(
                            id: noteId,
                            userId: note?.userId ?? '',
                            title: titleController.text.isEmpty
                                ? ''
                                : titleController.text,
                            createdAt: note?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                            alarmTime: finalAlarmTime,
                            repeatDays: selectedRepeatDays.isEmpty
                                ? null
                                : selectedRepeatDays,
                          );

                          if (note == null) {
                            await _noteService.addNote(newNote);
                          } else {
                            await _noteService.updateNote(newNote);
                          }

                          // আগের নোটিফিকেশন ক্যানসেল করে নতুন করে সেট করা
                          await _notificationService.cancelNotification(
                            noteId.hashCode,
                          );
                          for (int i = 1; i <= 7; i++) {
                            await _notificationService.cancelNotification(
                              noteId.hashCode + i,
                            );
                          }

                          if (selectedRepeatDays.isEmpty) {
                            if (finalAlarmTime.isAfter(DateTime.now())) {
                              await _notificationService.scheduleNotification(
                                noteId.hashCode,
                                "অ্যালার্ম: ${titleController.text}",
                                "এখনই সময়!",
                                finalAlarmTime,
                              );
                            }
                          } else {
                            await _notificationService
                                .scheduleWeeklyNotifications(
                                  noteId.hashCode,
                                  "অ্যালার্ম: ${titleController.text}",
                                  "এখনই সময়!",
                                  TimeOfDay.fromDateTime(finalAlarmTime),
                                  selectedRepeatDays,
                                );
                          }

                          await _loadNotes();
                          if (mounted) Navigator.pop(context);
                        },
                        child: Text(
                          note == null ? "সেভ করুন" : "আপডেট করুন",
                          style: const TextStyle(
                            color: Color(0xFF003829),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
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
      backgroundColor: isDark ? const Color(0xFF0C0C1F) : Colors.white,
      appBar: AppBar(
        title: const Text(
          "অফলাইন অ্যালার্ম",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "কোনো অ্যালার্ম সেট করা নেই",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                final bool hasRepeat =
                    note.repeatDays != null && note.repeatDays!.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E32) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    onTap: () => _showNoteBottomSheet(note: note),
                    title: Text(
                      note.alarmTime != null
                          ? _formatTime(note.alarmTime!)
                          : "সময় নেই",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (note.title != null ||
                            note.title != '' ||
                            note.title!.isNotEmpty)
                          Text(
                            note.title ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        if (note.title != null ||
                            note.title != '' ||
                            note.title!.isNotEmpty)
                          const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              size: 14,
                              color: const Color(0xFF60DCB2).withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasRepeat
                                  ? "প্রতি সপ্তাহে রিপিট"
                                  : _formatDate(
                                      note.alarmTime ?? DateTime.now(),
                                    ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF60DCB2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Color(0xFF60DCB2),
                          ),
                          onPressed: () => _showNoteBottomSheet(note: note),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteNote(note),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteBottomSheet(),
        backgroundColor: const Color(0xFF60DCB2),
        icon: const Icon(Icons.add_alarm, color: Color(0xFF003829)),
        label: const Text(
          "নতুন অ্যালার্ম",
          style: TextStyle(
            color: Color(0xFF003829),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
