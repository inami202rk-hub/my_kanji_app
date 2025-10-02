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
      KanjiItem(
        char: '\u65e5',
        stars: 1,
        meaning: 'sun, day',
        hint: 'Think of the sun rising over the horizon',
      ),
      KanjiItem(
        char: '\u6708',
        stars: 1,
        meaning: 'moon, month',
        hint: 'Resembles the crescent moon shape',
      ),
      KanjiItem(
        char: '\u6728',
        stars: 1,
        meaning: 'tree, wood',
        hint: 'Branches stretch upward and roots downward',
      ),
      KanjiItem(
        char: '\u6c34',
        stars: 1,
        meaning: 'water',
        hint: 'Droplets flowing downward',
      ),
      KanjiItem(
        char: '\u706b',
        stars: 1,
        meaning: 'fire',
        hint: 'Flames flickering upward',
      ),
      KanjiItem(
        char: '\u571f',
        stars: 1,
        meaning: 'earth, soil',
        hint: 'Layers of ground and a sprout on top',
      ),
    ],
    2: [
      KanjiItem(
        char: '\u91d1',
        stars: 2,
        meaning: 'gold, metal',
        hint: 'Shining nuggets stacked together',
      ),
      KanjiItem(
        char: '\u5c71',
        stars: 2,
        meaning: 'mountain',
        hint: 'Three peaks forming a range',
      ),
      KanjiItem(
        char: '\u5ddd',
        stars: 2,
        meaning: 'river',
        hint: 'Water flowing in parallel streams',
      ),
      KanjiItem(
        char: '\u82b1',
        stars: 2,
        meaning: 'flower',
        hint: 'Petals opening to bloom',
      ),
      KanjiItem(
        char: '\u96e8',
        stars: 2,
        meaning: 'rain',
        hint: 'Raindrops falling from the sky',
      ),
    ],
    3: [
      KanjiItem(
        char: '\u98a8',
        stars: 3,
        meaning: 'wind',
        hint: 'Swirling gust pushing through the trees',
      ),
      KanjiItem(
        char: '\u7a7a',
        stars: 3,
        meaning: 'sky, empty',
        hint: 'Vast space above the roof',
      ),
      KanjiItem(
        char: '\u661f',
        stars: 3,
        meaning: 'star',
        hint: 'Sparkle in the night sky',
      ),
      KanjiItem(
        char: '\u6d77',
        stars: 3,
        meaning: 'sea, ocean',
        hint: 'Water next to a mother giving birth to life',
      ),
      KanjiItem(
        char: '\u68ee',
        stars: 3,
        meaning: 'forest',
        hint: 'Three trees together make a forest',
      ),
      KanjiItem(
        char: '\u96ea',
        stars: 3,
        meaning: 'snow',
        hint: 'Rain turns to crystals in cold air',
      ),
    ],
    4: [
      KanjiItem(
        char: '\u9f8d',
        stars: 4,
        meaning: 'dragon',
        hint: 'A dragon coiling through clouds',
      ),
      KanjiItem(
        char: '\u96f7',
        stars: 4,
        meaning: 'thunder',
        hint: 'Rain clouds shaking with noise',
      ),
      KanjiItem(
        char: '\u5149',
        stars: 4,
        meaning: 'light',
        hint: 'Sunbeams shining outward',
      ),
      KanjiItem(
        char: '\u5d50',
        stars: 4,
        meaning: 'storm',
        hint: 'Wind swirling around the mountain',
      ),
      KanjiItem(
        char: '\u7ffc',
        stars: 4,
        meaning: 'wing',
        hint: 'Feathers spread gracefully',
      ),
    ],
    5: [
      KanjiItem(
        char: '\u5922',
        stars: 5,
        meaning: 'dream',
        hint: 'Eyes closed imagining scenes',
      ),
      KanjiItem(
        char: '\u9b42',
        stars: 5,
        meaning: 'spirit',
        hint: 'Soul rising like vapor',
      ),
      KanjiItem(
        char: '\u8aa0',
        stars: 5,
        meaning: 'sincerity',
        hint: 'Words born from the heart',
      ),
      KanjiItem(
        char: '\u7d46',
        stars: 5,
        meaning: 'bond, ties',
        hint: 'Threads linking people together',
      ),
      KanjiItem(
        char: '\u97ff',
        stars: 5,
        meaning: 'echo, resonance',
        hint: 'Sound waves reverberating',
      ),
      KanjiItem(
        char: '\u8000',
        stars: 5,
        meaning: 'shine brightly',
        hint: 'Radiant light blazing outward',
      ),
    ],
  };

  StatsSummary? _summaryCache;
  final Map<StatsRange, StatsTimeseries> _timeseriesCache = {};
  MasteryDistribution? _masteryDistribution;
  final Map<int, List<KanjiItem>> _masteryKanjiCache = {};

  @override
  Future<StatsSummary> loadSummary() async {
    _summaryCache ??= const StatsSummary(
      learnedWords: 182,
      totalAccuracy: 0.873,
      streak: 12,
      bestStreak: 24,
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
