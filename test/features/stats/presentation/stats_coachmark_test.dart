import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_kanji_app/features/stats/presentation/stats_page.dart';
import 'package:my_kanji_app/features/stats/services/onboarding_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingService> serviceWithInitial(bool seen) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      if (seen) OnboardingService.statsCoachmarkKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    return OnboardingService(prefs: prefs);
  }

  group('Stats coachmark', () {
    testWidgets('shows on first visit and hides after dismissal', (
      tester,
    ) async {
      final onboarding = await serviceWithInitial(false);

      await tester.pumpWidget(
        MaterialApp(home: StatsPage(onboardingService: onboarding)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to your Kanji Journey'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to your Kanji Journey'), findsNothing);
    });

    testWidgets('does not show when flag already true', (tester) async {
      final onboarding = await serviceWithInitial(true);

      await tester.pumpWidget(
        MaterialApp(home: StatsPage(onboardingService: onboarding)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Welcome to your Kanji Journey'), findsNothing);
    });
  });
}
