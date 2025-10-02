import '../data/stats_models.dart';

/// Utility functions to determine if stats data is empty or has no meaningful content
class StatsEmptyUtils {
  /// Checks if activity data (timeseries) is empty or has no activity
  static bool isActivityEmpty(StatsTimeseries? timeseries) {
    if (timeseries == null) return true;
    if (timeseries.series.isEmpty) return true;
    
    // Consider empty if all days have zero reviews
    return timeseries.series.every((stat) => stat.reviews == 0);
  }

  /// Checks if accuracy data is empty or has no meaningful accuracy data
  static bool isAccuracyEmpty(StatsTimeseries? timeseries) {
    if (timeseries == null) return true;
    if (timeseries.series.isEmpty) return true;
    
    // Consider empty if all days have zero total answers (correct + incorrect)
    return timeseries.series.every((stat) => stat.totalAnswers == 0);
  }

  /// Checks if XP data is empty or has no XP earned
  static bool isXpEmpty(StatsTimeseries? timeseries) {
    if (timeseries == null) return true;
    if (timeseries.series.isEmpty) return true;
    
    // Consider empty if all days have zero XP
    return timeseries.series.every((stat) => stat.xp <= 0);
  }

  /// Checks if mastery distribution is empty
  static bool isMasteryEmpty(MasteryDistribution? distribution) {
    if (distribution == null) return true;
    return distribution.isEmpty;
  }

  /// Checks if summary data is empty (all zeros)
  static bool isSummaryEmpty(StatsSummary? summary) {
    if (summary == null) return true;
    return summary.learnedWords == 0 && 
           summary.totalAccuracy == 0 && 
           summary.streak == 0 && 
           summary.bestStreak == 0;
  }
}
