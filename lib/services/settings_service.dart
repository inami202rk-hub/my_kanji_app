// lib/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyDeck = 'defaultDeck';
  static const _keyQuizSize = 'quizSize';
  static const _keyQuizMode =
      'quizMode'; // meaningToKanji | kanjiToMeaning | kanjiToReading

  static const _keyTimerEnabled = 'quizTimerEnabled';
  static const _keyTimerSeconds = 'quizTimerSeconds';

  // 既存拡張（重み付け・一覧既定・目標）
  static const _keyWeightedEnabled = 'weightedEnabled';
  static const _keyBrowseSort = 'browseSort';
  static const _keyBrowseSrsFilter = 'browseSrsFilter';
  static const _keyBrowseFavOnly = 'browseFavoritesOnly';
  static const _keyDailyGoal = 'dailyGoal';
  static const _keyWeeklyGoal = 'weeklyGoal';
  // 追記：キー
  static const _keySrsDailyCap = 'srsDailyCap.v1'; // int
  static const _keySrsShuffle = 'srsShuffle.v1';

  // lib/services/settings_service.dart

  static const _keySrsMaxNew = 'srs.max.new';
  static const _keySrsMaxLearn = 'srs.max.learn';

  static Future<int> loadSrsMaxNew() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keySrsMaxNew) ?? 20; // デフォルト20
  }

  static Future<void> saveSrsMaxNew(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keySrsMaxNew, v);
  }

  static Future<int> loadSrsMaxLearn() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keySrsMaxLearn) ?? 50; // デフォルト50
  }

  static Future<void> saveSrsMaxLearn(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keySrsMaxLearn, v);
  }
  // 'balanced' | 'random'

  // 追記：保存/読込
  static Future<void> saveSrsDailyCap(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keySrsDailyCap, v);
  }

  static Future<int?> loadSrsDailyCap() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keySrsDailyCap);
  }

  static Future<void> saveSrsShuffle(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySrsShuffle, v);
  }

  static Future<String?> loadSrsShuffle() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySrsShuffle);
  }

  // 追加：SRSプリセット
  static const _keySrsPreset = 'srsPreset'; // light | standard | heavy

  // 追加：間違いノート強優先
  static const _keyPrioritizeWrong = 'prioritizeWrong.v1';

  // 既存メソッドは省略（あなたの現行版に合わせて残してください）

  // ---- 強優先 ----
  static Future<void> savePrioritizeWrong(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyPrioritizeWrong, v);
  }

  static Future<bool> loadPrioritizeWrong() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyPrioritizeWrong) ?? false;
  }

  // ---- Deck ----
  static Future<void> saveDeck(String deck) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeck, deck);
  }

  static Future<String?> loadDeck() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeck);
  }

  // ---- Quiz Size ----
  static Future<void> saveQuizSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyQuizSize, size);
  }

  static Future<int?> loadQuizSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyQuizSize);
  }

  // ---- Quiz Mode ----
  static Future<void> saveQuizMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyQuizMode, mode);
  }

  static Future<String?> loadQuizMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyQuizMode);
  }

  // ---- Timer ----
  static Future<void> saveTimerEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTimerEnabled, enabled);
  }

  static Future<bool> loadTimerEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTimerEnabled) ?? false;
  }

  static Future<void> saveTimerSeconds(int sec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTimerSeconds, sec);
  }

  static Future<int> loadTimerSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTimerSeconds) ?? 15;
  }

  // ---- Weighted ----
  static Future<void> saveWeightedEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeightedEnabled, v);
  }

  static Future<bool> loadWeightedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWeightedEnabled) ?? true;
  }

  // ---- Browse defaults ----
  static Future<void> saveBrowseSort(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyBrowseSort, v);
  }

  static Future<String> loadBrowseSort() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyBrowseSort) ?? 'kanji';
  }

  static Future<void> saveBrowseSrsFilter(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyBrowseSrsFilter, v);
  }

  static Future<String> loadBrowseSrsFilter() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyBrowseSrsFilter) ?? 'all';
  }

  static Future<void> saveBrowseFavoritesOnly(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyBrowseFavOnly, v);
  }

  static Future<bool> loadBrowseFavoritesOnly() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyBrowseFavOnly) ?? false;
  }

  // ---- Goals ----
  static Future<void> saveDailyGoal(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyDailyGoal, v);
  }

  static Future<int> loadDailyGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyDailyGoal) ?? 20;
  }

  static Future<void> saveWeeklyGoal(int v) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyWeeklyGoal, v);
  }

  static Future<int> loadWeeklyGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyWeeklyGoal) ?? 100;
  }

  // ---- SRS Preset ----
  static Future<void> saveSrsPreset(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keySrsPreset, v);
  }

  static Future<String> loadSrsPreset() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keySrsPreset) ?? 'standard';
  }
}
