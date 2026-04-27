import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../core/model/note_model.dart';
import '../../core/services/note_service.dart';
import '../../core/services/notification_service.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final NoteService _noteService = NoteService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showNoteDialog({NoteModel? note}) {
    final titleController = TextEditingController(text: note?.title);
    final contentController = TextEditingController(text: note?.content);
    DateTime selectedDate = note?.createdAt ?? DateTime.now();
    DateTime? alarmTime = note?.alarmTime;
    List<int> selectedRepeatDays = note?.repeatDays != null
        ? List.from(note!.repeatDays!)
        : [];

    final dateController = TextEditingController(
      text: _formatDate(selectedDate),
    );
    final alarmController = TextEditingController(
      text: alarmTime != null ? _formatDate(alarmTime) : "অ্যালার্ম নেই",
    );

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                note == null ? "নতুন নোট" : "নোট এডিট করুন",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "শিরোনাম",
                        hintStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              DateTime.now().hour,
                              DateTime.now().minute,
                            );
                            dateController.text = _formatDate(selectedDate);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "তারিখ নির্বাচন করুন",
                        hintStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                          size: 20,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: alarmController,
                      readOnly: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
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
                            setDialogState(() {
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
                        hintText: "অ্যালার্ম সেট করুন",
                        hintStyle: const TextStyle(color: Colors.grey),
                        suffixIcon: alarmTime != null
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.red,
                                ),
                                onPressed: () => setDialogState(() {
                                  alarmTime = null;
                                  alarmController.text = "অ্যালার্ম নেই";
                                }),
                              )
                            : const Icon(
                                Icons.alarm,
                                color: Colors.grey,
                                size: 20,
                              ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    if (alarmTime != null) ...[
                      const SizedBox(height: 15),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "রিপিট করবেন?",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final dayIndex = index + 1;
                          final isSelected = selectedRepeatDays.contains(
                            dayIndex,
                          );
                          return FilterChip(
                            label: Text(
                              _weekDays[index],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? Colors.black
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF60DCB2),
                            onSelected: (bool selected) {
                              setDialogState(() {
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
                    TextField(
                      controller: contentController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: "বিস্তারিত...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "বাতিল",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF60DCB2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    final userId = _auth.currentUser?.uid ?? '';
                    final noteId = note?.id ?? const Uuid().v4();

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

                    if (note == null) {
                      await _noteService.addNote(newNote);
                    } else {
                      await _noteService.updateNote(newNote);
                    }

                    if (alarmTime != null) {
                      // আগের সব রিমাইন্ডার ক্যানসেল করা
                      await _notificationService.cancelNotification(
                        noteId.hashCode,
                      );
                      for (int i = 1; i <= 7; i++) {
                        await _notificationService.cancelNotification(
                          noteId.hashCode + i,
                        );
                      }

                      if (selectedRepeatDays.isEmpty) {
                        // শুধু একবারের জন্য
                        if (alarmTime!.isAfter(DateTime.now())) {
                          await _notificationService.scheduleNotification(
                            noteId.hashCode,
                            "নোট রিমাইন্ডার: ${titleController.text}",
                            contentController.text,
                            alarmTime!,
                          );
                        }
                      } else {
                        // নির্দিষ্ট বার অনুযায়ী রিপিট করার জন্য
                        await _notificationService.scheduleWeeklyNotifications(
                          noteId.hashCode,
                          "নোট রিমাইন্ডার: ${titleController.text}",
                          contentController.text,
                          TimeOfDay.fromDateTime(alarmTime!),
                          selectedRepeatDays,
                        );
                      }
                    } else {
                      await _notificationService.cancelNotification(
                        noteId.hashCode,
                      );
                      for (int i = 1; i <= 7; i++) {
                        await _notificationService.cancelNotification(
                          noteId.hashCode + i,
                        );
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
              ],
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
        title: const Text("নোট", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<NoteModel>>(
        stream: _noteService.getNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("কোনো নোট নেই", style: TextStyle(color: Colors.grey)),
            );
          }
          final notes = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                color: isDark ? const Color(0xFF1E1E32) : Colors.grey[200],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                onPressed: () => _showNoteDialog(note: note),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _noteService.deleteNote(note.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        note.content,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark ? Colors.tealAccent : Colors.teal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(note.createdAt),
                            style: TextStyle(
                              color: isDark ? Colors.tealAccent : Colors.teal,
                              fontSize: 12,
                            ),
                          ),
                          if (note.alarmTime != null) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.alarm,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${note.alarmTime!.hour}:${note.alarmTime!.minute.toString().padLeft(2, '0')}${note.repeatDays != null ? ' (রিপিট)' : ''}",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'note_fab',
        backgroundColor: const Color(0xFF60DCB2),
        onPressed: () => _showNoteDialog(),
        child: const Icon(Icons.add, color: Color(0xFF003829)),
      ),
    );
  }
}
