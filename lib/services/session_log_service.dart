// lib/services/session_log_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionLog {
  final DateTime at;
  final String deck;
  final bool srsMode;
  final String quizMode; // meaningToKanji | kanjiToMeaning | kanjiToReading
  final int total;
  final int correct;

  const SessionLog({
    required this.at,
    required this.deck,
    required this.srsMode,
    required this.quizMode,
    required this.total,
    required this.correct,
  });

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'deck': deck,
        'srsMode': srsMode,
        'quizMode': quizMode,
        'total': total,
        'correct': correct,
      };

  static SessionLog fromJson(Map<String, dynamic> j) => SessionLog(
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        deck: j['deck'] as String? ?? '',
        srsMode: j['srsMode'] as bool? ?? false,
        quizMode: j['quizMode'] as String? ?? 'meaningToKanji',
        total: (j['total'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
      );
}

class SessionLogService {
  static const _key = 'session.log.v1';

  static Future<List<SessionLog>> list() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final arr = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final items = arr.map(SessionLog.fromJson).toList();
      items.sort((a, b) => b.at.compareTo(a.at)); // 新しい順
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(SessionLog log, {int maxKeep = 200}) async {
    final p = await SharedPreferences.getInstance();
    final items = await list(); // ← メソッド名 list() とローカル変数の衝突を回避
    items.insert(0, log);
    if (items.length > maxKeep) {
      items.removeRange(maxKeep, items.length);
    }
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await p.setString(_key, raw);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
