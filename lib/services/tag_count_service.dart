// lib/services/tag_count_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// タグ件数のキャッシュ（全体・デッキ別）
/// - キー: tag.counts.v1
/// - 形式: { "ALL": {tag: count}, "<deck>": {tag: count} }
class TagCountService {
  static const _key = 'tag.counts.v1';

  static Future<Map<String, Map<String, int>>> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      return obj.map((deck, m) {
        final mm = (m as Map<String, dynamic>).map(
          (t, v) => MapEntry(t, (v as num).toInt()),
        );
        return MapEntry(deck, mm);
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<String, Map<String, int>> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  /// 取得（無ければ空）
  static Future<Map<String, int>> getCounts({required String deck}) async {
    final all = await _loadAll();
    return Map<String, int>.from(all[deck] ?? const {});
  }

  static Future<void> putCounts({
    required String deck,
    required Map<String, int> counts,
  }) async {
    final all = await _loadAll();
    all[deck] = Map<String, int>.from(counts);
    await _saveAll(all);
  }

  /// 単一タグの増減（ALL と deck 両方に反映）
  static Future<void> bump({
    required String deck,
    required String tag,
    required int delta,
  }) async {
    final all = await _loadAll();
    void inc(String d) {
      final m = all[d] ?? <String, int>{};
      m[tag] = (m[tag] ?? 0) + delta;
      if (m[tag]! <= 0) m.remove(tag);
      all[d] = m;
    }

    inc('ALL');
    inc(deck);
    await _saveAll(all);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
