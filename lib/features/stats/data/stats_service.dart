import 'dart:async';

import 'stats_models.dart';

abstract class StatsService {
  Future<StatsSummary> loadSummary();
  Future<StatsTimeseries> loadTimeseries({required StatsRange range});
  Future<MasteryDistribution> loadMasteryDistribution();
  Future<List<KanjiItem>> fetchKanjiByMastery(int stars);
}

class MockStatsService implements StatsService {
  MockStatsService();

  static const Map<int, List<KanjiItem>> _mockMasteryKanji = {
    1: [
      KanjiItem(char: '\u65e5', stars: 1),
      KanjiItem(char: '\u6708', stars: 1),
      KanjiItem(char: '\u6728', stars: 1),
      KanjiItem(char: '\u6c34', stars: 1),
      KanjiItem(char: '\u706b', stars: 1),
      KanjiItem(char: '\u571f', stars: 1),
    ],
    2: [
      KanjiItem(char: '\u91d1', stars: 2),
      KanjiItem(char: '\u5c71', stars: 2),
      KanjiItem(char: '\u5ddd', stars: 2),
      KanjiItem(char: '\u82b1', stars: 2),
      KanjiItem(char: '\u96e8', stars: 2),
    ],
    3: [
      KanjiItem(char: '\u98a8', stars: 3),
      KanjiItem(char: '\u7a7a', stars: 3),
      KanjiItem(char: '\u661f', stars: 3),
      KanjiItem(char: '\u6d77', stars: 3),
      KanjiItem(char: '\u68ee', stars: 3),
      KanjiItem(char: '\u96ea', stars: 3),
    ],
    4: [
      KanjiItem(char: '\u9f8d', stars: 4),
      KanjiItem(char: '\u96f7', stars: 4),
      KanjiItem(char: '\u5149', stars: 4),
      KanjiItem(char: '\u5d50', stars: 4),
      KanjiItem(char: '\u7ffc', stars: 4),
    ],
    5: [
      KanjiItem(char: '\u5922', stars: 5),
      KanjiItem(char: '\u9b42', stars: 5),
      KanjiItem(char: '\u8aa0', stars: 5),
      KanjiItem(char: '\u7d46', stars: 5),
      KanjiItem(char: '\u97ff', stars: 5),
      KanjiItem(char: '\u8000', stars: 5),
    ],
  };

  StatsSummary? _summaryCache;
  final Map<StatsRange, StatsTimeseries> _timeseriesCache = {};
  MasteryDistribution? _masteryDistribution;
  final Map<int, List<KanjiItem>> _masteryKanjiCache = {};

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

  @override
  Future<List<KanjiItem>> fetchKanjiByMastery(int stars) async {
    if (stars < 1 || stars > 5) {
      return const <KanjiItem>[];
    }
    _masteryKanjiCache.putIfAbsent(
      stars,
      () =>
          List<KanjiItem>.from(_mockMasteryKanji[stars] ?? const <KanjiItem>[]),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _masteryKanjiCache[stars]!;
  }
}
