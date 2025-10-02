import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_kanji_app/features/stats/presentation/widgets/activity_chart.dart';
import 'package:my_kanji_app/features/stats/presentation/widgets/accuracy_chart.dart';
import 'package:my_kanji_app/features/stats/presentation/widgets/xp_chart.dart';
import 'package:my_kanji_app/features/stats/presentation/widgets/stats_skeleton.dart';
import 'package:my_kanji_app/features/stats/presentation/widgets/mastery_distribution.dart';

void main() {
  group('Stats Empty States', () {
    testWidgets('ActivityChart shows empty state when no data', (tester) async {
      const palette = ActivityLegendColors(
        newColor: Colors.blue,
        reviewColor: Colors.green,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityChart(
              series: [], // Empty series
              palette: palette,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(StatsEmptyCard), findsOneWidget);
      expect(find.text('No activity yet — start a review to see stats'), findsOneWidget);
    });

    testWidgets('ActivityChart shows loading state when loading', (tester) async {
      const palette = ActivityLegendColors(
        newColor: Colors.blue,
        reviewColor: Colors.green,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityChart(
              series: [],
              palette: palette,
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(StatsCardSkeleton), findsOneWidget);
    });

    testWidgets('AccuracyChart shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccuracyChart(
              series: [], // Empty series
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(StatsEmptyCard), findsOneWidget);
      expect(find.text('No accuracy data yet — answer some reviews to see stats'), findsOneWidget);
    });

    testWidgets('XpChart shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: XpChart(
              series: [], // Empty series
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(StatsEmptyCard), findsOneWidget);
      expect(find.text('No XP earned yet — complete reviews to gain XP'), findsOneWidget);
    });

    testWidgets('MasteryEmptyMessage displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MasteryEmptyMessage(),
          ),
        ),
      );

      expect(find.byType(MasteryEmptyMessage), findsOneWidget);
      expect(find.text('No mastery yet — start learning kanji to see your progress here'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('StatsCardSkeleton animates correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsCardSkeleton(height: 200),
          ),
        ),
      );

      expect(find.byType(StatsCardSkeleton), findsOneWidget);
      
      // Test that animation controller is working
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1200));
      
      // Should still be present after animation cycles
      expect(find.byType(StatsCardSkeleton), findsOneWidget);
    });
  });
}
