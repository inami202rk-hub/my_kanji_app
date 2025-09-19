// 変更点：exportAll() と importAll() に wrong.v2 を追加
// lib/services/backup_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static Future<String> exportAll() async {
    final p = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'settings': await _safeGet<String>(p, 'settings.json'),
      'favorites.v1': await _safeGet<String>(p, 'favorites.v1'),
      'wrong.v1': await _safeGet<List<String>>(p, 'wrong.v1'), // list
      'wrong.v2': await _safeGet<String>(p, 'wrong.v2'), // json string
      'srs.v2': await _safeGet<String>(p, 'srs.v2'),
      'notes.v1': await _safeGet<String>(p, 'notes.v1'),
      'tags.v1': await _safeGet<String>(p, 'tags.v1'),
      'session.log.v1': await _safeGet<String>(p, 'session.log.v1'),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<void> importAll(String json) async {
    final p = await SharedPreferences.getInstance();
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('JSONの形式が不正です');
    }

    Future<void> putMaybeString(String key) async {
      if (obj.containsKey(key) && obj[key] != null) {
        final v = obj[key];
        if (v is String) {
          await p.setString(key, v);
        } else {
          await p.setString(key, jsonEncode(v));
        }
      }
    }

    // v1 list<string> は setStringListで保持（後方互換）
    if (obj.containsKey('wrong.v1') && obj['wrong.v1'] != null) {
      final v = obj['wrong.v1'];
      if (v is List) {
        await p.setStringList('wrong.v1', v.map((e) => e.toString()).toList());
      } else if (v is String) {
        try {
          final arr = (jsonDecode(v) as List).map((e) => e.toString()).toList();
          await p.setStringList('wrong.v1', arr);
        } catch (_) {
          // 文字列のままは無視
        }
      }
    }

    // そのほかは文字列保存
    await putMaybeString('settings.json');
    await putMaybeString('favorites.v1');
    await putMaybeString('wrong.v2'); // ★ 追加
    await putMaybeString('srs.v2');
    await putMaybeString('notes.v1');
    await putMaybeString('tags.v1');
    await putMaybeString('session.log.v1');
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<String?> pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    return data?.text;
  }

  static Future<T?> _safeGet<T>(SharedPreferences p, String key) async {
    if (!p.containsKey(key)) return null;
    final v = p.get(key);
    if (T == List<String>) {
      // 型に合わせて返す（favoritesやwrong.v1など）
      return (v is List<String>) ? v as T : null;
    }
    if (v is T) return v;
    return null;
  }
}
