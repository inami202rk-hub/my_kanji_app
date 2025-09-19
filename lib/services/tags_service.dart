// lib/services/tags_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'tag_count_service.dart';

class TagsService {
  static const _key = 'tags.v1'; // Map<String kanji, List<String> tags>
  static const _keyColors = 'tags.colors.v1'; // Map<String tag, int argb>

  // ---- タグ付け (既存) ----
  static Future<Map<String, List<String>>> _loadAll() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map(
        (k, v) => MapEntry(
          k,
          ((v as List?) ?? const []).map((e) => e.toString()).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<String, List<String>> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(m));
  }

  static Future<List<String>> loadTags(String kanji) async {
    final m = await _loadAll();
    return m[kanji] ?? const [];
  }

  static Future<void> addTag(String kanji, String tag) async {
    final t = tag.trim();
    if (t.isEmpty) return;
    final m = await _loadAll();
    final list = (m[kanji] ?? <String>[]);
    if (!list.contains(t)) list.add(t);
    m[kanji] = list;
    await _saveAll(m);
    // addTag() の末尾に追加（保存後）
    await TagCountService.bump(deck: 'ALL', tag: t, delta: 1);
    // ※ deckName は呼び出し側で渡せないなら 'ALL' 固定でOK
  }

  static Future<void> removeTag(String kanji, String tag) async {
    final m = await _loadAll();
    final list = m[kanji] ?? <String>[];
    list.remove(tag);
    if (list.isEmpty) {
      m.remove(kanji);
    } else {
      m[kanji] = list;
    }
    await _saveAll(m);
    // removeTag() の末尾に追加（保存後）
    await TagCountService.bump(deck: 'ALL', tag: tag, delta: -1);
  }

  static Future<List<String>> allTags() async {
    final m = await _loadAll();
    final set = <String>{};
    for (final list in m.values) {
      set.addAll(list);
    }
    final arr = set.toList()..sort();
    return arr;
  }

  static Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }

  // ---- タグ色 (追加) ----
  static Future<Map<String, int>> _loadColors() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_keyColors);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return m.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveColors(Map<String, int> m) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyColors, jsonEncode(m));
  }

  static Future<int?> loadTagColor(String tag) async {
    final m = await _loadColors();
    return m[tag];
  }

  static Future<void> saveTagColor(String tag, int argb) async {
    final m = await _loadColors();
    m[tag] = argb;
    await _saveColors(m);
  }

  static Future<void> removeTagColor(String tag) async {
    final m = await _loadColors();
    m.remove(tag);
    await _saveColors(m);
  }

  static Future<Map<String, int>> allTagColors() => _loadColors();
}
