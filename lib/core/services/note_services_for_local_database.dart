import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/note_model.dart';

class NoteServicesForLocalDatabase {
  static const String _key = "notes";

  Future<void> addNote(NoteModel note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    notes.add(note);

    final jsonList = notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<void> updateNote(NoteModel note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    final index = notes.indexWhere((e) => e.id == note.id);
    if (index != -1) {
      notes[index] = note;
    }

    final jsonList = notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  Future<List<NoteModel>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];

    return data
        .map((e) => NoteModel.fromJson(jsonDecode(e)))
        .toList();
  }

  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();

    notes.removeWhere((e) => e.id == id);

    final jsonList = notes.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }
}