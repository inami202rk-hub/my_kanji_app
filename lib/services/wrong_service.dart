// lib/services/wrong_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrong（間違いノート）
/// - v1: List<String>（先頭が最新）
/// - v2: Map<String, {count:int, ts:int(millis)}>
/// 既存コード互換APIを維持しつつ、v2 をメインとして運用します。
class WrongService {
  static const String _keyV1 = 'wrong.v1'; // 旧: List<String>
  static const String _keyV2 = 'wrong.v2'; // 新: JSON Map

  /// 互換用：v1形式の順序付きリスト（新しい順）を返す
  /// v1が無ければ v2 から降順(ts)で生成
  static Future<List<String>> loadWrong() async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_keyV1);
    if (list != null) return List<String>.from(list);
    // v2 → 降順で keys を返す
    final map = await _loadV2(p);
    final entries = map.entries.toList()
      ..sort((a, b) => (b.value.ts ?? 0).compareTo(a.value.ts ?? 0));
    return entries.map((e) => e.key).toList();
  }

  /// 主要API：全件（count, ts付き）を返す（降順: ts）（tsが無い場合は末尾）
  static Future<List<WrongEntry>> listAll() async {
    final p = await SharedPreferences.getInstance();
    await _maybeMigrate(p);
    final map = await _loadV2(p);
    final list =
        map.entries
            .map(
              (e) => WrongEntry(
                kanji: e.key,
                count: e.value.count ?? 1,
                ts: e.value.ts == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(e.value.ts!),
              ),
            )
            .toList()
          ..sort((a, b) {
            final at = a.ts?.millisecondsSinceEpoch ?? 0;
            final bt = b.ts?.millisecondsSinceEpoch ?? 0;
            if (bt != at) return bt.compareTo(at);
            if (b.count != a.count) return b.count.compareTo(a.count);
            return a.kanji.compareTo(b.kanji);
          });
    return list;
  }

  /// 追加：count++ / ts=now に更新。v1（順序リスト）も先頭へ移動。
  static Future<void> addWrong(String kanji) async {
    final key = kanji.trim();
    if (key.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await _maybeMigrate(p);

    // v2更新
    final map = await _loadV2(p);
    final cur = map[key];
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    map[key] = _V2Entry(count: (cur?.count ?? 0) + 1, ts: nowMs);
    await _saveV2(p, map);

    // v1更新（順序）
    final v1 = p.getStringList(_keyV1) ?? <String>[];
    v1.removeWhere((e) => e == key);
    v1.insert(0, key);
    await p.setStringList(_keyV1, v1);
  }

  /// 個別削除：v1/v2 両方から除去
  static Future<void> removeWrong(String kanji) async {
    final p = await SharedPreferences.getInstance();
    await _maybeMigrate(p);

    // v2
    final map = await _loadV2(p);
    map.remove(kanji);
    await _saveV2(p, map);

    // v1
    final v1 = p.getStringList(_keyV1) ?? <String>[];
    v1.removeWhere((e) => e == kanji);
    await p.setStringList(_keyV1, v1);
  }

  /// 全削除：v1/v2両方
  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyV1);
    await p.remove(_keyV2);
  }

  // ===== 内部: v2 の読み書き・移行 =====

  static Future<Map<String, _V2Entry>> _loadV2(SharedPreferences p) async {
    final raw = p.getString(_keyV2);
    if (raw == null || raw.isEmpty) return {};
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      return obj.map((k, v) {
        if (v is Map<String, dynamic>) {
          return MapEntry(k, _V2Entry.fromJson(v));
        } else {
          return MapEntry(k, _V2Entry(count: 1, ts: null));
        }
      });
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveV2(
    SharedPreferences p,
    Map<String, _V2Entry> map,
  ) async {
    final enc = jsonEncode(map.map((k, v) => MapEntry(k, v.toJson())));
    await p.setString(_keyV2, enc);
  }

  /// v1のみ存在 → v2を生成（count=1、tsは並び順に基づいて擬似タイムスタンプを付与）
  static Future<void> _maybeMigrate(SharedPreferences p) async {
    final hasV2 = p.containsKey(_keyV2);
    final hasV1 = p.containsKey(_keyV1);
    if (hasV2 || !hasV1) return;

    final v1 = p.getStringList(_keyV1) ?? <String>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    // 先頭＝最新。順に -1ms ずつ後ろへ
    final map = <String, _V2Entry>{};
    for (int i = 0; i < v1.length; i++) {
      final key = v1[i];
      map[key] = _V2Entry(count: 1, ts: now - i);
    }
    await _saveV2(p, map);
  }
}

class WrongEntry {
  final String kanji;
  final int count;
  final DateTime? ts;
  WrongEntry({required this.kanji, required this.count, this.ts});
}

class _V2Entry {
  final int? count;
  final int? ts; // epoch millis
  _V2Entry({this.count, this.ts});

  Map<String, dynamic> toJson() => {'count': count, 'ts': ts};

  factory _V2Entry.fromJson(Map<String, dynamic> j) => _V2Entry(
    count: (j['count'] as num?)?.toInt() ?? 1,
    ts: (j['ts'] as num?)?.toInt(),
  );
}
