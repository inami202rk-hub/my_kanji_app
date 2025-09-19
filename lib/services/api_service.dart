// lib/services/api_service.dart
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/kanji.dart';

class Paged<T> {
  final List<T> content;
  final int page;
  final int size;
  final int total;
  const Paged({
    required this.content,
    required this.page,
    required this.size,
    required this.total,
  });
}

class ApiService {
  static const String _base = 'http://localhost:8080/api';
  static const Duration _ttl = Duration(minutes: 5);
  static final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();

  static Future<_CacheEntry> _getJson(String path) async {
    final url = '$_base$path';
    final now = DateTime.now();

    final existed = _cache[url];
    if (existed != null && now.difference(existed.storedAt) <= _ttl) {
      return existed;
    }

    final headers = <String, String>{};
    if (existed?.etag != null) {
      headers['If-None-Match'] = existed!.etag!;
    }

    final res = await http.get(Uri.parse(url), headers: headers);

    if (res.statusCode == 304 && existed != null) {
      final refreshed = _CacheEntry(existed.data, existed.etag);
      _cache[url] = refreshed;
      return refreshed;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final etag = res.headers['etag'];
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final entry = _CacheEntry(data, etag);
      _cache[url] = entry;
      return entry;
    }

    if (existed != null) return existed;
    throw Exception('GET $url failed: ${res.statusCode}');
  }

  /// /api/levels → ["N5","N4","N3"] など
  static Future<List<String>> fetchLevels() async {
    final e = await _getJson('/levels');
    final data = e.data;
    if (data is List) {
      return data.whereType<String>().toList();
    }
    throw Exception('levels response is not List<String>');
  }

  /// /api/kanji?deck=N5 → List<Kanji>
  static Future<List<Kanji>> fetchKanjiByDeck(String deck) async {
    final e = await _getJson('/kanji?deck=$deck');
    final data = e.data;
    if (data is List) {
      return data
          .map((j) => Kanji.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('kanji response is not List');
  }

  /// /api/kanji/search?deck=N5&q=...&page=0&size=20
  static Future<Paged<Kanji>> searchKanji({
    required String deck,
    required String q,
    int page = 0,
    int size = 20,
  }) async {
    final e = await _getJson(
      '/kanji/search?deck=$deck&q=${Uri.encodeQueryComponent(q)}&page=$page&size=$size',
    );
    final data = e.data;
    if (data is Map<String, dynamic>) {
      final content = (data['content'] as List)
          .map((x) => Kanji.fromJson(x as Map<String, dynamic>))
          .toList();
      final pg = (data['page'] as num).toInt();
      final sz = (data['size'] as num).toInt();
      final total = (data['total'] as num).toInt();
      return Paged<Kanji>(content: content, page: pg, size: sz, total: total);
    }
    throw Exception('search response invalid');
  }

  static Future<void> prefetchDecks(List<String> decks) async {
    for (final d in decks) {
      try {
        await fetchKanjiByDeck(d);
      } catch (_) {}
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final String? etag;
  final DateTime storedAt;
  _CacheEntry(this.data, this.etag) : storedAt = DateTime.now();
}
