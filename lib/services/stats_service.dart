// lib/services/stats_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const _kXp = 'statsXp';
  static const _kStreak = 'statsStreak';
  static const _kLastActive = 'statsLastActive'; // yyyy-MM-dd
  static const _kTotal = 'statsAnsweredTotal';
  static const _kCorrect = 'statsAnsweredCorrect';

  // ---- ロード ----
  static Future<int> loadXp() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kXp) ?? 0;
  }

  static Future<int> loadStreak() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kStreak) ?? 0;
  }

  static Future<int> loadTotal() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kTotal) ?? 0;
  }

  static Future<int> loadCorrect() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kCorrect) ?? 0;
  }

  static Future<double> loadAccuracy() async {
    final total = await loadTotal();
    if (total == 0) return 0.0;
    final correct = await loadCorrect();
    return correct / total;
  }

  // ---- 更新系（クイズ終了時に呼ぶ）----
  static Future<void> addXp(int delta) async {
    final p = await SharedPreferences.getInstance();
    final now = (p.getInt(_kXp) ?? 0) + delta;
    await p.setInt(_kXp, now);
    await _touchStreak(p); // アクティビティ発生＝ストリーク更新
  }

  /// クイズ結果を反映（合計/正答を加算）
  static Future<void> recordQuiz({
    required int total,
    required int correct,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTotal, (p.getInt(_kTotal) ?? 0) + total);
    await p.setInt(_kCorrect, (p.getInt(_kCorrect) ?? 0) + correct);
    // XPルール：正答×10
    await addXp(correct * 10);
    await _touchStreak(p);
  }

  /// 今日アクティブにしたらストリークを更新（00:00基準で計算）
  static Future<void> _touchStreak(SharedPreferences p) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // 00:00
    final todayStr = _yyyyMMdd(today);

    final last = p.getString(_kLastActive);
    int streak = p.getInt(_kStreak) ?? 0;

    if (last == null) {
      streak = 1;
    } else {
      // last は "yyyy-MM-dd"
      DateTime lastDate;
      try {
        final parts = last.split('-'); // [yyyy, MM, dd]
        lastDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } catch (_) {
        lastDate = today;
      }
      final diffDays = today.difference(lastDate).inDays;
      if (diffDays == 0) {
        // 同じ日 → 変化なし
      } else if (diffDays == 1) {
        streak += 1; // 昨日も実施 → +1
      } else {
        streak = 1; // 1日以上空いた → リセット
      }
    }

    await p.setString(_kLastActive, todayStr);
    await p.setInt(_kStreak, streak);
  }

  static String _yyyyMMdd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  // ---- 全消し（デバッグ用）----
  static Future<void> resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kXp);
    await p.remove(_kStreak);
    await p.remove(_kLastActive);
    await p.remove(_kTotal);
    await p.remove(_kCorrect);
  }
}
