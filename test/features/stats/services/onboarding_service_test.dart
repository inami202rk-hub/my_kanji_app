import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_kanji_app/features/stats/services/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    test('returns false when flag not set', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = OnboardingService(prefs: prefs);

      expect(await service.isStatsCoachmarkSeen(), isFalse);
    });

    test('set and read stats coachmark flag', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = OnboardingService(prefs: prefs);

      await service.setStatsCoachmarkSeen(true);
      expect(await service.isStatsCoachmarkSeen(), isTrue);

      await service.setStatsCoachmarkSeen(false);
      expect(await service.isStatsCoachmarkSeen(), isFalse);
    });
  });
}
