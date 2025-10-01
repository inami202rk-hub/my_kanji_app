import 'dart:async';

import 'stats_models.dart';

abstract class StatsService {
  Future<StatsSummary> loadSummary();
  Future<StatsTimeseries> loadTimeseries({required StatsRange range});
  Future<MasteryDistribution> loadMasteryDistribution();
}

class MockStatsService implements StatsService {
  MockStatsService();

  StatsSummary? _summaryCache;
  final Map<StatsRange, StatsTimeseries> _timeseriesCache = {};
  MasteryDistribution? _masteryDistribution;

  @override
  Future<StatsSummary> loadSummary() async {
    _summaryCache ??= const StatsSummary(
      learnedWords: 20,
      totalAccuracy: 0.97,
      streak: 3,
      bestStreak: 10,
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _summaryCache!;
  }

  @override
  Future<StatsTimeseries> loadTimeseries({required StatsRange range}) async {
    if (_timeseriesCache.containsKey(range)) {
      return _timeseriesCache[range]!;
    }
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = range.days;
    final series = List<DailyStat>.generate(days, (index) {
      final day = today.subtract(Duration(days: days - 1 - index));
      final newCards = index % 3 == 0 ? 2 : 0;
      final reviews = newCards + (index % 5) + 1;
      final accuracyTarget = 0.7 + (index % 5) * 0.05;
      final correct = (reviews * accuracyTarget)
          .clamp(0, reviews.toDouble())
          .round();
      final incorrect = (reviews - correct).clamp(0, reviews);
      return DailyStat(
        date: day,
        reviews: reviews,
        newCards: newCards,
        correctReviews: correct,
        incorrectReviews: incorrect,
        xp: (correct * 10) + (newCards * 5),
      );
    });
    final result = StatsTimeseries(series: series, streak: 3, bestStreak: 10);
    _timeseriesCache[range] = result;
    return result;
  }

  @override
  Future<MasteryDistribution> loadMasteryDistribution() async {
    _masteryDistribution ??= const MasteryDistribution(
      counts: [12, 8, 5, 3, 2],
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _masteryDistribution!;
  }
}
