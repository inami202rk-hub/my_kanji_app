// lib/srs/srs_tuning.dart
class SrsTuning {
  static const double easeInit = 2.50;
  static const double easeMin = 1.30;
  static const double easeMax = 2.70;

  static const Map<String, double> easeDelta = {
    'again': -0.30,
    'hard': -0.15,
    'good': 0.00,
    'easy': 0.15,
  };

  // review (prevInterval > 0) の倍率
  static const Map<String, double> intervalMul = {
    'again': 0.0, // relearnへ
    'hard': 0.48,
    'good': 0.995,
    'easy': 1.30,
  };

  // new / relearn 用ベース（日）
  static const Map<String, int> baseStepsDays = {
    'again': 1,
    'hard': 1,
    'good': 1,
    'easy': 2,
  };
}
