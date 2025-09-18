// lib/services/selection_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 一覧で選んだサブセットを保存/復元するサービス。
/// - 保存キー: selection.v1
/// - 形式: { deck: String, ids: List<String>, ts: int, mode: String? }
class SelectionService {
  static const _key = 'selection.v1';

  static Future<void> saveSelection({
    required String deck,
    required List<String> ids,
    String? mode, // 'normal' | 'srs' | 任意
  }) async {
    final p = await SharedPreferences.getInstance();
    final obj = {
      'deck': deck,
      'ids': ids,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'mode': mode,
    };
    await p.setString(_key, jsonEncode(obj));
  }

  /// 直近の選択。なければ null
  static Future<SelectionData?> loadSelection() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return SelectionData(
        deck: (j['deck'] ?? '') as String,
        ids: ((j['ids'] as List?) ?? const []).map((e) => e.toString()).toList(),
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        mode: j['mode']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasSelection() async => (await loadSelection()) != null;

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

class SelectionData {
  final String deck;
  final List<String> ids;
  final int ts;     // epoch millis
  final String? mode;
  SelectionData({required this.deck, required this.ids, required this.ts, this.mode});
}
