// lib/services/favorites_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'favorites';

  static Future<List<String>> loadFavorites() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_key) ?? <String>[];
  }

  static Future<void> addFavorite(String kanji) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? <String>[];
    if (!list.contains(kanji)) {
      list.add(kanji);
      await p.setStringList(_key, list);
    }
  }

  static Future<void> removeFavorite(String kanji) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_key) ?? <String>[];
    list.remove(kanji);
    await p.setStringList(_key, list);
  }

  static Future<bool> isFavorite(String kanji) async {
    final list = await loadFavorites();
    return list.contains(kanji);
  }
}
