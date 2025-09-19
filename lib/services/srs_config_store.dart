// lib/services/srs_config_store.dart

import 'package:shared_preferences/shared_preferences.dart';

import '../models/srs_config.dart';

abstract class SrsConfigStore {
  Future<SrsConfig> load();
  Future<void> save(SrsConfig config);
  Future<void> resetToDefault();
}

class SharedPrefsSrsConfigStore implements SrsConfigStore {
  static const _keyMaxNew = 'srs.max.new';
  static const _keyMaxLearn = 'srs.max.learn';
  static const _keyDailyCap = 'srsDailyCap.v1';
  static const _keyPrioritizeWrong = 'prioritizeWrong.v1';
  static const _keyStrategy = 'srsShuffle.v1';

  @override
  Future<SrsConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SrsConfig(
      maxNew: prefs.getInt(_keyMaxNew) ?? SrsConfig.defaults.maxNew,
      maxLearn: prefs.getInt(_keyMaxLearn) ?? SrsConfig.defaults.maxLearn,
      dailyCap: prefs.getInt(_keyDailyCap) ?? SrsConfig.defaults.dailyCap,
      prioritizeWrong:
          prefs.getBool(_keyPrioritizeWrong) ??
          SrsConfig.defaults.prioritizeWrong,
      strategy: _parseStrategy(prefs.getString(_keyStrategy)),
    );
  }

  @override
  Future<void> save(SrsConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxNew, config.maxNew);
    await prefs.setInt(_keyMaxLearn, config.maxLearn);
    await prefs.setInt(_keyDailyCap, config.dailyCap);
    await prefs.setBool(_keyPrioritizeWrong, config.prioritizeWrong);
    await prefs.setString(_keyStrategy, config.strategy.name);
  }

  @override
  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMaxNew);
    await prefs.remove(_keyMaxLearn);
    await prefs.remove(_keyDailyCap);
    await prefs.remove(_keyPrioritizeWrong);
    await prefs.remove(_keyStrategy);
  }

  SrsStrategy _parseStrategy(String? raw) {
    switch (raw) {
      case 'front':
        return SrsStrategy.front;
      case 'shuffle':
      case 'random':
        return SrsStrategy.shuffle;
      case 'balanced':
        return SrsStrategy.balanced;
      default:
        return SrsStrategy.balanced;
    }
  }
}
