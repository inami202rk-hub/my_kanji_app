import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'favorites_service.dart';
import 'srs_config_store.dart';
import 'srs_service.dart';

class BackupService {
  static const _appName = 'my_kanji_app';
  static const _appBuild = '1.0.0+1';

  const BackupService();

  Future<String> exportJson() => _exportJsonInternal();

  static Future<String> _exportJsonInternal() async {
    final config = await SharedPrefsSrsConfigStore().load();
    final states = await SrsService.loadAll();
    final favorites = await FavoritesService.loadFavorites();

    final sortedKeys = states.keys.toList()..sort();
    final srsItems = <Map<String, dynamic>>[];
    for (final key in sortedKeys) {
      final state = states[key];
      if (state == null) continue;
      srsItems.add(_toSrsItem(key, state));
    }

    final sortedFavorites = [...favorites]..sort();

    final payload = <String, dynamic>{
      'version': '1',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'app': <String, String>{
        'name': _appName,
        'build': _appBuild,
        'platform': _platformName(),
      },
      'settings': <String, dynamic>{
        'maxNew': config.maxNew,
        'maxLearn': config.maxLearn,
        'dailyCap': config.dailyCap,
        'prioritizeWrong': config.prioritizeWrong,
        'strategy': config.strategy.name,
      },
      'srsState': srsItems,
      'favorites': sortedFavorites,
    };

    return jsonEncode(payload);
  }

  static Map<String, dynamic> _toSrsItem(String key, SrsState state) {
    final effectiveKey = key.isNotEmpty ? key : state.id;
    return <String, dynamic>{
      'key': effectiveKey,
      'ef': state.ease,
      'prevIntervalDays': state.interval,
      'due': _formatDate(state.due),
      'lapses': state.lapses,
      'streak': state.reps,
    };
  }

  static String _formatDate(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _platformName() {
    if (kIsWeb) return 'web';
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android) return 'android';
    if (platform == TargetPlatform.iOS) return 'ios';
    if (platform == TargetPlatform.windows) return 'windows';
    if (platform == TargetPlatform.macOS) return 'macos';
    if (platform == TargetPlatform.linux) return 'linux';
    if (platform == TargetPlatform.fuchsia) return 'fuchsia';
    return 'unknown';
  }

  static Future<String> exportAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'settings': await _safeGet<String>(prefs, 'settings.json'),
      'favorites.v1': await _safeGet<String>(prefs, 'favorites.v1'),
      'wrong.v1': await _safeGet<List<String>>(prefs, 'wrong.v1'),
      'wrong.v2': await _safeGet<String>(prefs, 'wrong.v2'),
      'srs.v2': await _safeGet<String>(prefs, 'srs.v2'),
      'notes.v1': await _safeGet<String>(prefs, 'notes.v1'),
      'tags.v1': await _safeGet<String>(prefs, 'tags.v1'),
      'session.log.v1': await _safeGet<String>(prefs, 'session.log.v1'),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<void> importAll(String json) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('JSONの形式が不正です');
    }

    Future<void> putMaybeString(String key) async {
      if (obj.containsKey(key) && obj[key] != null) {
        final value = obj[key];
        if (value is String) {
          await prefs.setString(key, value);
        } else {
          await prefs.setString(key, jsonEncode(value));
        }
      }
    }

    if (obj.containsKey('wrong.v1') && obj['wrong.v1'] != null) {
      final value = obj['wrong.v1'];
      if (value is List) {
        await prefs.setStringList(
          'wrong.v1',
          value.map((e) => e.toString()).toList(),
        );
      } else if (value is String) {
        try {
          final arr = (jsonDecode(value) as List)
              .map((e) => e.toString())
              .toList();
          await prefs.setStringList('wrong.v1', arr);
        } catch (_) {}
      }
    }

    await putMaybeString('settings.json');
    await putMaybeString('favorites.v1');
    await putMaybeString('wrong.v2');
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

  static Future<T?> _safeGet<T>(SharedPreferences prefs, String key) async {
    if (!prefs.containsKey(key)) return null;
    final value = prefs.get(key);
    if (T == List<String>) {
      return (value is List<String>) ? value as T : null;
    }
    if (value is T) return value;
    return null;
  }
}
