import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../core/model/note_model.dart';
import '../../core/model/notification_model.dart';
import '../../core/services/note_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/fcm_notification_services.dart';

class NoteScreen extends StatefulWidget {
  const NoteScreen({super.key});

  @override
  State<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final NoteService _noteService = NoteService();
  final NotificationService _notificationService = NotificationService();
  final FcmNotificationServices _fcmStorage = FcmNotificationServices();
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
    _checkAndShowInAppMessage();
    
    // Listen for real-time in-app messages
    _fcmStorage.messageStream.listen((message) {
      if (message != null && mounted) {
        _showInAppMessageDialog(message);
      }
    });
  }

  Future<void> _checkAndShowInAppMessage() async {
    final messages = await _fcmStorage.getSavedNotifications();
    if (messages.isNotEmpty && mounted) {
      // Show the latest message as a popup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showInAppMessageDialog(messages.first);
      });
    }
  }

  void _showInAppMessageDialog(NotificationModel message) {
    showDialog(context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final hasImage = message.imageUrl != null && message.imageUrl!.isNotEmpty;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E1E32) : Colors.white,
          clipBehavior: Clip.antiAlias, // ডায়ালগের কোণাগুলো যাতে ইমেজের সাথে সুন্দর দেখায়
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasImage)
                Stack(
                  children: [
                    Image.network(
                      message.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey.withOpacity(0.1),
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.black26,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  children: [
                    Text(
                      message.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message.body,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60DCB2),
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "ঠিক আছে",
                        style: TextStyle(
                          color: Color(0xFF003829),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatOnlyDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
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
      text: _formatOnlyDate(selectedDate),
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
                            );
                            dateController.text = _formatOnlyDate(selectedDate);
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
                      await _updateNote(newNote);
                    }

                    if (alarmTime != null) {
                      await _notificationService.cancelNotification(
                        noteId.hashCode,
                      );
                      for (int i = 1; i <= 7; i++) {
                        await _notificationService.cancelNotification(
                          noteId.hashCode + i,
                        );
                      }

                      if (selectedRepeatDays.isEmpty) {
                        if (alarmTime!.isAfter(DateTime.now())) {
                          await _notificationService.scheduleNotification(
                            noteId.hashCode,
                            "নোট রিমাইন্ডার: ${titleController.text}",
                            contentController.text,
                            alarmTime!,
                          );
                        }
                      } else {
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

  Future<void> _updateNote(NoteModel note) async {
    await _noteService.updateNote(note);
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
          
          final notes = snapshot.data ?? [];
          
          if (notes.isEmpty) {
            return const Center(
              child: Text("কোনো নোট নেই", style: TextStyle(color: Colors.grey)),
            );
          }

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
