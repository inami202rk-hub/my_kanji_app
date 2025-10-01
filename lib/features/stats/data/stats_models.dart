import 'package:intl/intl.dart';

class DailyStat {
  final DateTime date;
  final int reviews;
  final int newCards;

  const DailyStat({
    required this.date,
    required this.reviews,
    required this.newCards,
  });

  int get reviewOnly => (reviews - newCards).clamp(0, reviews);
}

enum StatsRange { d7, d30, d90 }

extension StatsRangeX on StatsRange {
  int get days => switch (this) {
    StatsRange.d7 => 7,
    StatsRange.d30 => 30,
    StatsRange.d90 => 90,
  };

  String label() {
    return switch (this) {
      StatsRange.d7 => '7',
      StatsRange.d30 => '30',
      StatsRange.d90 => '90',
    };
  }
}

class StatsSummary {
  final int learnedWords;
  final double totalAccuracy; // 0..1
  final int streak;
  final int bestStreak;

  const StatsSummary({
    required this.learnedWords,
    required this.totalAccuracy,
    required this.streak,
    required this.bestStreak,
  });

  String formatAccuracy(String locale) {
    final formatter = NumberFormat.percentPattern(locale);
    return formatter.format(totalAccuracy);
  }
}

class StatsTimeseries {
  final List<DailyStat> series;
  final int streak;
  final int bestStreak;

  const StatsTimeseries({
    required this.series,
    required this.streak,
    required this.bestStreak,
  });

  bool get isEmpty => series.isEmpty;
}
