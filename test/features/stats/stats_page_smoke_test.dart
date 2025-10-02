import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_kanji_app/features/stats/presentation/stats_page.dart';

void main() {
  group('StatsPage Smoke Test', () {
    testWidgets('renders key section titles correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(home: StatsPage()));

      // Wait for initial loading to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check that key section titles are displayed
      expect(find.text('Answer accuracy'), findsOneWidget);
      expect(find.text('XP earned'), findsAtLeastNWidgets(1));
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Mastery distribution'), findsOneWidget);
    });

    testWidgets('displays stats page with proper structure', (tester) async {
      await tester.pumpWidget(MaterialApp(home: StatsPage()));

      // Wait for initial loading
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check that the main scaffold and app bar are present
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);

      // Check that the main scrollable content is present
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
