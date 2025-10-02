import 'package:flutter_test/flutter_test.dart';
import 'package:my_kanji_app/features/stats/data/stats_models.dart';
import 'package:my_kanji_app/features/stats/services/stats_empty_utils.dart';

void main() {
  group('Stats Empty Utils', () {
    test('isActivityEmpty returns true for null timeseries', () {
      expect(StatsEmptyUtils.isActivityEmpty(null), isTrue);
    });

    test('isActivityEmpty returns true for empty series', () {
      const timeseries = StatsTimeseries(series: [], streak: 0, bestStreak: 0);
      expect(StatsEmptyUtils.isActivityEmpty(timeseries), isTrue);
    });

    test('isActivityEmpty returns false for series with reviews', () {
      final timeseries = StatsTimeseries(
        series: [
          DailyStat(
            date: DateTime.now(),
            reviews: 5,
            newCards: 2,
            correctReviews: 4,
            incorrectReviews: 1,
            xp: 50,
          ),
        ],
        streak: 1,
        bestStreak: 1,
      );
      expect(StatsEmptyUtils.isActivityEmpty(timeseries), isFalse);
    });

    test('isAccuracyEmpty returns true for null timeseries', () {
      expect(StatsEmptyUtils.isAccuracyEmpty(null), isTrue);
    });

    test('isAccuracyEmpty returns true for series with no answers', () {
      final timeseries = StatsTimeseries(
        series: [
          DailyStat(
            date: DateTime.now(),
            reviews: 0,
            newCards: 0,
            correctReviews: 0,
            incorrectReviews: 0,
            xp: 0,
          ),
        ],
        streak: 0,
        bestStreak: 0,
      );
      expect(StatsEmptyUtils.isAccuracyEmpty(timeseries), isTrue);
    });

    test('isAccuracyEmpty returns false for series with answers', () {
      final timeseries = StatsTimeseries(
        series: [
          DailyStat(
            date: DateTime.now(),
            reviews: 5,
            newCards: 2,
            correctReviews: 4,
            incorrectReviews: 1,
            xp: 50,
          ),
        ],
        streak: 1,
        bestStreak: 1,
      );
      expect(StatsEmptyUtils.isAccuracyEmpty(timeseries), isFalse);
    });

    test('isXpEmpty returns true for null timeseries', () {
      expect(StatsEmptyUtils.isXpEmpty(null), isTrue);
    });

    test('isXpEmpty returns true for series with no XP', () {
      final timeseries = StatsTimeseries(
        series: [
          DailyStat(
            date: DateTime.now(),
            reviews: 0,
            newCards: 0,
            correctReviews: 0,
            incorrectReviews: 0,
            xp: 0,
          ),
        ],
        streak: 0,
        bestStreak: 0,
      );
      expect(StatsEmptyUtils.isXpEmpty(timeseries), isTrue);
    });

    test('isXpEmpty returns false for series with XP', () {
      final timeseries = StatsTimeseries(
        series: [
          DailyStat(
            date: DateTime.now(),
            reviews: 5,
            newCards: 2,
            correctReviews: 4,
            incorrectReviews: 1,
            xp: 50,
          ),
        ],
        streak: 1,
        bestStreak: 1,
      );
      expect(StatsEmptyUtils.isXpEmpty(timeseries), isFalse);
    });

    test('isMasteryEmpty returns true for null distribution', () {
      expect(StatsEmptyUtils.isMasteryEmpty(null), isTrue);
    });

    test('isMasteryEmpty returns true for empty distribution', () {
      const distribution = MasteryDistribution(counts: [0, 0, 0, 0, 0]);
      expect(StatsEmptyUtils.isMasteryEmpty(distribution), isTrue);
    });

    test('isMasteryEmpty returns false for distribution with counts', () {
      const distribution = MasteryDistribution(counts: [1, 2, 3, 4, 5]);
      expect(StatsEmptyUtils.isMasteryEmpty(distribution), isFalse);
    });
  });
}
