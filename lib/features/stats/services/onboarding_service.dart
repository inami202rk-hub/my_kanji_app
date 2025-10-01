import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  OnboardingService({SharedPreferences? prefs})
    : _prefsFuture = prefs != null
          ? Future.value(prefs)
          : SharedPreferences.getInstance();

  static const String statsCoachmarkKey = 'stats_coachmark_seen';

  final Future<SharedPreferences> _prefsFuture;

  Future<bool> isStatsCoachmarkSeen() async {
    final prefs = await _prefsFuture;
    return prefs.getBool(statsCoachmarkKey) ?? false;
  }

  Future<void> setStatsCoachmarkSeen(bool value) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(statsCoachmarkKey, value);
  }
}
