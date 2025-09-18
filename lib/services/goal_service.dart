// lib/services/goal_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GoalService {
  static const _keyDaily = 'goal.daily.v1';   // {"2025-09-16": 23, ...}
  static const _keyWeekly = 'goal.weekly.v1'; // {"2025-W37": 120, ...}

  static String _today() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
  }

  static String _thisWeek() {
    final now = DateTime.now();
    // ISO week-ish（簡易）：年- W + weekOfYear
    final week = _weekOfYear(now);
    return '${now.year}-W${week.toString().padLeft(2,'0')}';
  }

  static int _weekOfYear(DateTime d) {
    final first = DateTime(d.year, 1, 1);
    final diff = d.difference(first).inDays + first.weekday; // rough
    return ((diff) / 7).floor() + 1;
  }

  static Future<Map<String,int>> _load(String key) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try { return (jsonDecode(raw) as Map<String,dynamic>).map((k,v)=>MapEntry(k, (v as num).toInt())); }
    catch (_) { return {}; }
  }

  static Future<void> _save(String key, Map<String,int> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, jsonEncode(m));
  }

  static Future<void> addSolved(int n) async {
    final daily = await _load(_keyDaily);
    final weekly = await _load(_keyWeekly);

    final td = _today();
    final tw = _thisWeek();

    daily[td] = (daily[td] ?? 0) + n;
    weekly[tw] = (weekly[tw] ?? 0) + n;

    await _save(_keyDaily, daily);
    await _save(_keyWeekly, weekly);
  }

  static Future<int> todaySolved() async {
    final daily = await _load(_keyDaily);
    return daily[_today()] ?? 0;
  }

  static Future<int> thisWeekSolved() async {
    final weekly = await _load(_keyWeekly);
    return weekly[_thisWeek()] ?? 0;
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyDaily);
    await p.remove(_keyWeekly);
  }
}
