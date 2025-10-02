import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _kSrsPreviewEnabled = 'srs.preview.enabled';

  Future<bool> getSrsPreviewEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSrsPreviewEnabled) ?? true;
  }

  Future<void> setSrsPreviewEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSrsPreviewEnabled, value);
  }
}
