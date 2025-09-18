// lib/services/notes_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static const _key = 'notes.v1';

  static Future<Map<String, String>> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<String, String> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  static Future<String?> loadNote(String kanji) async {
    final m = await _loadAll();
    return m[kanji];
  }

  static Future<bool> hasNote(String kanji) async {
    final m = await _loadAll();
    final s = (m[kanji] ?? '').trim();
    return s.isNotEmpty;
  }

  static Future<void> saveNote(String kanji, String note) async {
    final m = await _loadAll();
    if (note.trim().isEmpty) {
      m.remove(kanji);
    } else {
      m[kanji] = note.trim();
    }
    await _saveAll(m);
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
