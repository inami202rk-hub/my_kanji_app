import 'package:intl/intl.dart';

class DailyStat {
  final DateTime date;
  final int reviews;
  final int newCards;
  final int correctReviews;
  final int incorrectReviews;
  final int xp;

  const DailyStat({
    required this.date,
    required this.reviews,
    required this.newCards,
    this.correctReviews = 0,
    this.incorrectReviews = 0,
    this.xp = 0,
  });

  int get reviewOnly => (reviews - newCards).clamp(0, reviews);

  int get totalAnswers => correctReviews + incorrectReviews;

  double get accuracyPercent =>
      totalAnswers == 0 ? 0 : (correctReviews / totalAnswers) * 100;
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

  double get averageAccuracy {
    if (series.isEmpty) {
      return 0;
    }
    final totals = series.fold<List<double>>([0, 0], (acc, stat) {
      acc[0] += stat.correctReviews.toDouble();
      acc[1] += stat.incorrectReviews.toDouble();
      return acc;
    });
    final attempts = totals[0] + totals[1];
    if (attempts == 0) {
      return 0;
    }
    return (totals[0] / attempts) * 100;
  }
}
