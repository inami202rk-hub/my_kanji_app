import 'package:flutter_test/flutter_test.dart';
import 'package:my_kanji_app/srs/sim_core.dart';
// パッケージ名が違う場合は相対importに変更：
// import '../../lib/srs/sim_core.dart';

void main() {
  final cfg = SrsCoreConfig(
    easeGoodDelta: 0.15,
    easeEasyDelta: 0.3,
    easeHardPenalty: -0.15,
    minEase: 1.3,
    learningSteps: const [Duration(minutes: 1), Duration(minutes: 10)],
    minInterval: const Duration(days: 1),
    maxInterval: const Duration(days: 365),
    againInterval: const Duration(minutes: 1),
    hardFactor: 1.2,
    goodFactor: 2.0,
    easyFactor: 2.5,
  );

  test('review: Hard <= Good <= Easy for next interval', () {
    final s = SrsCoreInput(
      cfg: cfg,
      stage: SrsStage.review,
      learningIndex: 0,
      currentInterval: const Duration(days: 2),
      ease: 2.5,
      lapses: 0,
      now: DateTime(2025, 1, 1),
    );
    final r = SimCore.simulateAll(s);
    final hard = r.rows
        .firstWhere((e) => e.action == SrsAction.hard)
        .nextInterval;
    final good = r.rows
        .firstWhere((e) => e.action == SrsAction.good)
        .nextInterval;
    final easy = r.rows
        .firstWhere((e) => e.action == SrsAction.easy)
        .nextInterval;
    expect(hard <= good, true);
    expect(good <= easy, true);
  });

  test('learning Good progresses step; Easy exits to review(minInterval)', () {
    final s0 = SrsCoreInput(
      cfg: cfg,
      stage: SrsStage.learning,
      learningIndex: 0,
      currentInterval: Duration.zero,
      ease: 2.5,
      lapses: 0,
      now: DateTime(2025, 1, 1),
    );
    final r0 = SimCore.simulateAll(s0);
    final good0 = r0.rows.firstWhere((e) => e.action == SrsAction.good);
    expect(good0.nextStage, SrsStage.learning);
    expect(good0.nextLearningIndex, 1);
    expect(good0.nextInterval, const Duration(minutes: 10));

    final s1 = SrsCoreInput(
      cfg: cfg,
      stage: SrsStage.learning,
      learningIndex: 1,
      currentInterval: Duration.zero,
      ease: 2.5,
      lapses: 0,
      now: DateTime(2025, 1, 1),
    );
    final r1 = SimCore.simulateAll(s1);
    final easy1 = r1.rows.firstWhere((e) => e.action == SrsAction.easy);
    expect(easy1.nextStage, SrsStage.review);
    expect(easy1.nextInterval, cfg.minInterval);
  });

  test('review Again goes back to learning with againInterval', () {
    final s = SrsCoreInput(
      cfg: cfg,
      stage: SrsStage.review,
      learningIndex: 0,
      currentInterval: const Duration(days: 5),
      ease: 2.3,
      lapses: 2,
      now: DateTime(2025, 1, 1),
    );
    final r = SimCore.simulateAll(s);
    final again = r.rows.firstWhere((e) => e.action == SrsAction.again);
    expect(again.nextStage, SrsStage.learning);
    expect(again.nextInterval, cfg.againInterval);
  });

  test('clamps to maxInterval on very large multipliers', () {
    final cfgTight = SrsCoreConfig(
      easeGoodDelta: 0.15,
      easeEasyDelta: 0.3,
      easeHardPenalty: -0.15,
      minEase: 1.3,
      learningSteps: const [Duration(minutes: 1)],
      minInterval: const Duration(days: 1),
      maxInterval: const Duration(days: 10),
      againInterval: const Duration(minutes: 1),
      hardFactor: 10.0,
      goodFactor: 10.0,
      easyFactor: 10.0,
    );
    final s = SrsCoreInput(
      cfg: cfgTight,
      stage: SrsStage.review,
      learningIndex: 0,
      currentInterval: const Duration(days: 5),
      ease: 3.0,
      lapses: 0,
      now: DateTime(2025, 1, 1),
    );
    final r = SimCore.simulateAll(s);
    final easy = r.rows
        .firstWhere((e) => e.action == SrsAction.easy)
        .nextInterval;
    expect(easy, cfgTight.maxInterval);
  });
}
