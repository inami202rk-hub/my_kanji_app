// lib/services/session_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuizSession {
  final String deck;
  final bool srsMode;
  final List<String> kanjiList; // 出題順の配列
  final int index; // 次に解くインデックス（0-based）
  final int correct; // これまでの正解数

  const QuizSession({
    required this.deck,
    required this.srsMode,
    required this.kanjiList,
    required this.index,
    required this.correct,
  });

  Map<String, dynamic> toJson() => {
    'deck': deck,
    'srsMode': srsMode,
    'kanjiList': kanjiList,
    'index': index,
    'correct': correct,
  };

  static QuizSession fromJson(Map<String, dynamic> j) => QuizSession(
    deck: j['deck'] as String,
    srsMode: j['srsMode'] as bool,
    kanjiList: (j['kanjiList'] as List).map((e) => e.toString()).toList(),
    index: (j['index'] as num).toInt(),
    correct: (j['correct'] as num).toInt(),
  );
}

class SessionService {
  static const _key = 'session.v1';

  static Future<bool> exists() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString(_key) ?? '').isNotEmpty;
  }

  static Future<void> save(QuizSession s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(s.toJson()));
  }

  static Future<QuizSession?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return QuizSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
