import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/model/note_model.dart';
import '../../core/services/note_service.dart';
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
    "রবি"
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initNotification();
    _loadNotes();
  }

  /// 🔥 Load Notes
  Future<void> _loadNotes() async {
    final data = await _noteService.getNotes();
    setState(() {
      _notes = data;
    });
  }

  /// 🔥 Delete
  Future<void> _deleteNote(NoteModel note) async {
    await _noteService.deleteNote(note.id);

    /// cancel alarm
    await _notificationService.cancelNotification(note.id.hashCode);
    for (int i = 1; i <= 7; i++) {
      await _notificationService.cancelNotification(note.id.hashCode + i);
    }

    await _loadNotes();
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showNoteBottomSheet({NoteModel? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);

    DateTime? alarmTime = note?.alarmTime;

    List<int> selectedRepeatDays =
        note?.repeatDays != null ? List.from(note!.repeatDays!) : [];

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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// TITLE
                    Text(
                      note == null ? "নতুন নোট" : "নোট এডিট",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 20),

                    /// NOTE TITLE
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "শিরোনাম",
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// ALARM PICKER (Handles both Date and Time)
                    TextField(
                      controller: alarmController,
                      readOnly: true,
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: alarmTime ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 0)),
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

                              alarmController.text = _formatDate(alarmTime!);
                            });
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "অ্যালার্ম সেট করুন (তারিখ ও সময়)",
                        suffixIcon: alarmTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    alarmTime = null;
                                    selectedRepeatDays.clear();
                                    alarmController.text = "অ্যালার্ম নেই";
                                  });
                                },
                              )
                            : const Icon(Icons.alarm),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    /// REPEAT DAYS
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

                    const SizedBox(height: 25),

                    /// SAVE BUTTON
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

                          final noteId = note?.id ?? const Uuid().v4();

                          final newNote = NoteModel(
                            id: noteId,
                            userId: '',
                            title: titleController.text,
                            content: contentController.text,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            alarmTime: alarmTime,
                            repeatDays: selectedRepeatDays.isEmpty
                                ? null
                                : selectedRepeatDays,
                          );

                          /// SAVE
                          if (note == null) {
                            await _noteService.addNote(newNote);
                          } else {
                            await _noteService.updateNote(newNote);
                          }

                          /// NOTIFICATION
                          await _notificationService
                              .cancelNotification(noteId.hashCode);

                          for (int i = 1; i <= 7; i++) {
                            await _notificationService
                                .cancelNotification(noteId.hashCode + i);
                          }

                          if (alarmTime != null) {
                            if (selectedRepeatDays.isEmpty) {
                              if (alarmTime!.isAfter(DateTime.now())) {
                                await _notificationService.scheduleNotification(
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
                          }

                          await _loadNotes();
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

  /// 🔥 MAIN UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("অফলাইন অ্যালার্ম")),
      body: _notes.isEmpty
          ? const Center(child: Text("কোনো অ্যালার্ম নেই"))
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];

                return Card(
                  child: ListTile(
                    title: Text(note.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (note.alarmTime != null)
                          Text("⏰ ${_formatDate(note.alarmTime!)}"),
                        if (note.repeatDays != null)
                          Text("🔁 ${note.repeatDays}"),
                      ],
                    ),
                    onTap: () => _showNoteBottomSheet(note: note), // edit
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteNote(note),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteBottomSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
