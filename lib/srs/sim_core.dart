import 'dart:math';

/// 依存のない純粋コア。既存SrsServiceを壊さずに予測だけを行う。
/// 後で SrsService から薄いアダプタで呼び出せる構造。

enum SrsStage { newCard, learning, review }

enum SrsAction { again, hard, good, easy }

class SrsCoreConfig {
  /// SM2系の基本パラメータ群（あなたの SrsConfig に合わせて後でアダプタを作る）
  final double easeGoodDelta; // +0.15 など
  final double easeEasyDelta; // +0.30 など
  final double easeHardPenalty; // -0.15 など
  final double minEase; // 1.3 など（下限）

  final List<Duration> learningSteps; // 例: [1m, 10m]
  final Duration minInterval; // 例: 1d
  final Duration maxInterval; // 例: 365d
  final Duration againInterval; // 例: 1m

  /// review用の倍率（プロジェクトの調整値に合わせて後で変更可）
  final double hardFactor; // 1.2 など（小さめ）
  final double goodFactor; // 2.0 など（基準）
  final double easyFactor; // 2.5 など（大きめ）

  const SrsCoreConfig({
    required this.easeGoodDelta,
    required this.easeEasyDelta,
    required this.easeHardPenalty,
    required this.minEase,
    required this.learningSteps,
    required this.minInterval,
    required this.maxInterval,
    required this.againInterval,
    required this.hardFactor,
    required this.goodFactor,
    required this.easyFactor,
  });
}

class SrsCoreInput {
  final SrsCoreConfig cfg;
  final SrsStage stage;
  final int learningIndex; // 0..(steps-1)（newCardは0扱い）
  final Duration currentInterval; // review中の現在間隔、learning/newは Duration.zero 可
  final double ease; // 現在の ease（学習中は初期値想定でもOK）
  final int lapses; // 失敗回数。ここでは将来拡張用
  final DateTime now; // 基準時刻

  const SrsCoreInput({
    required this.cfg,
    required this.stage,
    required this.learningIndex,
    required this.currentInterval,
    required this.ease,
    required this.lapses,
    required this.now,
  });
}

class SrsPreviewRow {
  final SrsAction action;
  final Duration nextInterval;
  final DateTime nextDue;
  final double nextEase;
  final SrsStage nextStage;
  final int nextLearningIndex;

  const SrsPreviewRow({
    required this.action,
    required this.nextInterval,
    required this.nextDue,
    required this.nextEase,
    required this.nextStage,
    required this.nextLearningIndex,
  });
}

class SrsPreviewResult {
  final List<SrsPreviewRow> rows;
  final List<Duration> futureGoodIntervals; // Good連打の簡易シミュレーション
  const SrsPreviewResult({
    required this.rows,
    required this.futureGoodIntervals,
  });
}

class SimCore {
  static SrsPreviewResult simulateAll(SrsCoreInput input, {int goodDepth = 5}) {
    final rows = <SrsPreviewRow>[];
    for (final a in SrsAction.values) {
      rows.add(_simulateOne(input, a));
    }
    final futureGood = _simulateGoodChain(input, depth: goodDepth);
    return SrsPreviewResult(rows: rows, futureGoodIntervals: futureGood);
  }

  static SrsPreviewRow _simulateOne(SrsCoreInput s, SrsAction a) {
    final easeNext = _nextEase(s.ease, a, s.cfg);
    final trans = _transition(s, a, easeNext);
    final due = s.now.add(trans.interval);
    return SrsPreviewRow(
      action: a,
      nextInterval: trans.interval,
      nextDue: due,
      nextEase: easeNext,
      nextStage: trans.stage,
      nextLearningIndex: trans.learningIndex,
    );
  }

  static List<Duration> _simulateGoodChain(
    SrsCoreInput s, {
    required int depth,
  }) {
    var cur = s;
    final out = <Duration>[];
    for (var i = 0; i < depth; i++) {
      final row = _simulateOne(cur, SrsAction.good);
      out.add(row.nextInterval);
      cur = SrsCoreInput(
        cfg: s.cfg,
        stage: row.nextStage,
        learningIndex: row.nextLearningIndex,
        currentInterval: row.nextInterval,
        ease: row.nextEase,
        lapses: s.lapses,
        now: s.now.add(row.nextInterval),
      );
    }
    return out;
  }

  // ---- helpers ----

  static double _nextEase(double ease, SrsAction a, SrsCoreConfig c) {
    switch (a) {
      case SrsAction.again:
        return max(c.minEase, ease + c.easeHardPenalty);
      case SrsAction.hard:
        return max(c.minEase, ease + c.easeHardPenalty / 2);
      case SrsAction.good:
        return max(c.minEase, ease + c.easeGoodDelta);
      case SrsAction.easy:
        return max(c.minEase, ease + c.easeEasyDelta);
    }
  }

  static _Transition _transition(SrsCoreInput s, SrsAction a, double easeNext) {
    final c = s.cfg;
    if (s.stage == SrsStage.review) {
      switch (a) {
        case SrsAction.again:
          // 学習へ戻す
          return _Transition(
            stage: SrsStage.learning,
            learningIndex: 0,
            interval: c.againInterval,
          );
        case SrsAction.hard:
          return _Transition(
            stage: SrsStage.review,
            learningIndex: s.learningIndex,
            interval: _clamp(
              _scale(s.currentInterval, c.hardFactor * easeNext),
              c,
            ),
          );
        case SrsAction.good:
          return _Transition(
            stage: SrsStage.review,
            learningIndex: s.learningIndex,
            interval: _clamp(
              _scale(s.currentInterval, c.goodFactor * easeNext),
              c,
            ),
          );
        case SrsAction.easy:
          return _Transition(
            stage: SrsStage.review,
            learningIndex: s.learningIndex,
            interval: _clamp(
              _scale(s.currentInterval, c.easyFactor * easeNext),
              c,
            ),
          );
      }
    } else {
      // new / learning
      final steps = c.learningSteps.isEmpty
          ? <Duration>[const Duration(minutes: 1)]
          : c.learningSteps;
      final last = steps.length - 1;
      switch (a) {
        case SrsAction.again:
          return _Transition(
            stage: SrsStage.learning,
            learningIndex: 0,
            interval: steps.first,
          );
        case SrsAction.hard:
          final idx = s.stage == SrsStage.newCard ? 0 : s.learningIndex;
          return _Transition(
            stage: SrsStage.learning,
            learningIndex: idx, // 同じステップをやり直し
            interval: steps[idx],
          );
        case SrsAction.good:
          final curIdx = s.stage == SrsStage.newCard ? 0 : s.learningIndex;
          if (curIdx < last) {
            final nextIdx = curIdx + 1;
            return _Transition(
              stage: SrsStage.learning,
              learningIndex: nextIdx,
              interval: steps[nextIdx],
            );
          } else {
            // 学習脱出→review最小間隔へ
            return _Transition(
              stage: SrsStage.review,
              learningIndex: 0,
              interval: _clamp(c.minInterval, c),
            );
          }
        case SrsAction.easy:
          // 早期脱出
          return _Transition(
            stage: SrsStage.review,
            learningIndex: 0,
            interval: _clamp(c.minInterval, c),
          );
      }
    }
  }

  static Duration _scale(Duration base, double factor) {
    final ms = base.inMilliseconds * factor;
    return Duration(milliseconds: ms.round());
  }

  static Duration _clamp(Duration d, SrsCoreConfig c) {
    final lo = c.minInterval.inMilliseconds;
    final hi = c.maxInterval.inMilliseconds;
    final x = d.inMilliseconds;
    return Duration(milliseconds: x.clamp(lo, hi));
  }
}

class _Transition {
  final SrsStage stage;
  final int learningIndex;
  final Duration interval;
  _Transition({
    required this.stage,
    required this.learningIndex,
    required this.interval,
  });
}
