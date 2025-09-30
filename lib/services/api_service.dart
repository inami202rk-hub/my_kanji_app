// lib/services/api_service.dart
import 'dart:collection';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import '../models/kanji.dart';
import 'favorites_service.dart';
import 'tags_service.dart';

class SearchResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;
  const SearchResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });
}

class ApiService {
  const ApiService();

  static const String _base = 'http://localhost:8080/api';
  static const Duration _ttl = Duration(minutes: 5);
  static final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();
  static const Map<String, String> _deckAssets = {
    'N3': 'assets/decks/n3.json',
    'N4': 'assets/decks/n4.json',
    'N5': 'assets/decks/n5.json',
  };
  static final Map<String, List<Kanji>> _localDeckCache = {};

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

  Future<SearchResult<Kanji>> searchKanji({
    required String query,
    required int page,
    required int size,
    bool favoriteOnly = false,
    String? level,
    String? readingType,
    String? tag,
  }) {
    return _searchKanji(
      query: query,
      page: page,
      size: size,
      favoriteOnly: favoriteOnly,
      level: level,
      readingType: readingType,
      tag: tag,
    );
  }

  static Future<SearchResult<Kanji>> _searchKanji({
    required String query,
    required int page,
    required int size,
    bool favoriteOnly = false,
    String? level,
    String? readingType,
    String? tag,
  }) async {
    final params = <String, String>{
      'q': query,
      'page': page.toString(),
      'size': size.toString(),
    };
    if (favoriteOnly) params['favoriteOnly'] = 'true';
    if (level != null && level.trim().isNotEmpty && level != 'All') {
      params['level'] = level.trim();
    }
    if (readingType != null &&
        readingType.trim().isNotEmpty &&
        readingType != 'All') {
      params['readingType'] = readingType.trim();
    }
    if (tag != null && tag.trim().isNotEmpty) {
      params['tag'] = tag.trim();
    }

    SearchResult<Kanji>? parsed;
    try {
      final path = params.isEmpty
          ? '/kanji/search'
          : '/kanji/search?${Uri(queryParameters: params).query}';
      final e = await _getJson(path);
      parsed = _parseSearchResponse(e.data);
    } catch (_) {
      parsed = null;
    }

    if (parsed != null) {
      return parsed;
    }

    return _localSearch(
      query: query,
      page: page,
      size: size,
      favoriteOnly: favoriteOnly,
      level: level,
      readingType: readingType,
      tag: tag,
    );
  }

  static SearchResult<Kanji>? _parseSearchResponse(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    List<dynamic> rawItems = const [];
    if (data['items'] is List) {
      rawItems = data['items'] as List;
    } else if (data['content'] is List) {
      rawItems = data['content'] as List;
    }
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(Kanji.fromJson)
        .toList();

    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final total = data.containsKey('total')
        ? asInt(data['total'])
        : data.containsKey('totalElements')
        ? asInt(data['totalElements'])
        : data.containsKey('count')
        ? asInt(data['count'])
        : items.length;
    final page = data.containsKey('page')
        ? asInt(data['page'])
        : data.containsKey('pageNumber')
        ? asInt(data['pageNumber'])
        : data.containsKey('pageIndex')
        ? asInt(data['pageIndex'])
        : 0;
    final size = data.containsKey('size')
        ? asInt(data['size'])
        : data.containsKey('pageSize')
        ? asInt(data['pageSize'])
        : data.containsKey('limit')
        ? asInt(data['limit'])
        : items.length;
    return SearchResult<Kanji>(
      items: items,
      total: total,
      page: page,
      size: size,
    );
  }

  static Future<SearchResult<Kanji>> _localSearch({
    required String query,
    required int page,
    required int size,
    required bool favoriteOnly,
    String? level,
    String? readingType,
    String? tag,
  }) async {
    final normalizedLevel =
        (level != null && level.trim().isNotEmpty && level != 'All')
        ? level.trim()
        : null;
    List<String> levels;
    try {
      levels = await fetchLevels();
    } catch (_) {
      levels = _deckAssets.keys.toList();
    }
    if (levels.isEmpty) {
      levels = _deckAssets.keys.toList();
    }
    final targets = normalizedLevel != null ? [normalizedLevel] : levels;

    final all = <Kanji>[];
    for (final lv in targets) {
      final deckKey = lv.toUpperCase();
      bool fetched = false;
      try {
        final list = await fetchKanjiByDeck(lv);
        if (list.isNotEmpty) {
          for (final k in list) {
            all.add(
              (k.deck == null || k.deck!.isEmpty) ? k.copyWith(deck: lv) : k,
            );
          }
          fetched = true;
        }
      } catch (_) {
        fetched = false;
      }
      if (!fetched) {
        final assetList = await _loadDeckFromAssets(deckKey);
        for (final k in assetList) {
          all.add(
            (k.deck == null || k.deck!.isEmpty) ? k.copyWith(deck: lv) : k,
          );
        }
      }
    }

    final favorites = (await FavoritesService.loadFavorites()).toSet();
    final tagsByKanji = await TagsService.loadAllTagsMap();

    final filtered = _filterLocal(
      all,
      query: query,
      favoriteOnly: favoriteOnly,
      level: normalizedLevel,
      readingType: readingType,
      tag: tag,
      favorites: favorites,
      tagsByKanji: tagsByKanji,
    );

    final total = filtered.length;
    final start = page * size;
    final paged = start >= total
        ? <Kanji>[]
        : filtered.skip(start).take(size).toList();
    return SearchResult<Kanji>(
      items: paged,
      total: total,
      page: page,
      size: size,
    );
  }

  static Future<List<Kanji>> _loadDeckFromAssets(String deck) async {
    final cached = _localDeckCache[deck];
    if (cached != null) return cached;
    final assetPath = _deckAssets[deck] ?? _deckAssets[deck.toUpperCase()];
    if (assetPath == null) {
      return const <Kanji>[];
    }
    try {
      final raw = await rootBundle.loadString(assetPath);
      final data = jsonDecode(raw);
      if (data is List) {
        final list = data.whereType<Map<String, dynamic>>().map((json) {
          final parsed = Kanji.fromJson(json);
          return (parsed.deck == null || parsed.deck!.isEmpty)
              ? parsed.copyWith(deck: deck)
              : parsed;
        }).toList();
        _localDeckCache[deck] = list;
        return list;
      }
    } catch (_) {}
    return const <Kanji>[];
  }

  static List<Kanji> _filterLocal(
    List<Kanji> input, {
    required String query,
    required bool favoriteOnly,
    String? level,
    String? readingType,
    String? tag,
    required Set<String> favorites,
    required Map<String, List<String>> tagsByKanji,
  }) {
    Iterable<Kanji> list = input;
    if (level != null && level.isNotEmpty) {
      final lower = level.toLowerCase();
      list = list.where((k) => (k.deck ?? '').toLowerCase() == lower);
    }
    if (favoriteOnly) {
      list = list.where(
        (k) => k.isFavorite == true || favorites.contains(k.kanji),
      );
    }
    final normalizedReading = readingType?.trim().toLowerCase();
    // 読み種別フィルタ
    if (normalizedReading == 'on') {
      list = list.where((k) => k.onyomiList.isNotEmpty);
    } else if (normalizedReading == 'kun') {
      list = list.where((k) => k.kunyomiList.isNotEmpty);
    }

    // タグ
    if (tag != null && tag.trim().isNotEmpty) {
      final loweredTag = tag.trim().toLowerCase();
      list = list.where((k) {
        final tags = k.tags ?? tagsByKanji[k.kanji] ?? const [];
        return tags.any((t) => t.toLowerCase().contains(loweredTag));
      });
    }

    // フリーテキスト
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((k) {
        if (k.kanji.toLowerCase().contains(q)) return true;
        if ((k.meaning ?? '').toLowerCase().contains(q)) return true;
        if (k.meaningsList.any((m) => m.toLowerCase().contains(q))) return true;

        if ((k.reading ?? '').toLowerCase().contains(q)) return true;
        if (k.readingsList.any((r) => r.toLowerCase().contains(q))) return true;

        if (k.onyomiList.any((r) => r.toLowerCase().contains(q))) return true;
        if (k.kunyomiList.any((r) => r.toLowerCase().contains(q))) return true;

        final tags = k.tags ?? tagsByKanji[k.kanji] ?? const [];
        if (tags.any((t) => t.toLowerCase().contains(q))) return true;

        return false;
      });
    }

    return list.toList();
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
