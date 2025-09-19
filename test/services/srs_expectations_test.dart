import 'package:flutter_test/flutter_test.dart';
import 'package:my_kanji_app/srs/srs_tuning.dart';
import 'dart:math';

int nextIntervalDays({
  required int prev,
  required String rating,
  required double ef,
}) {
  if (prev <= 0) return SrsTuning.baseStepsDays[rating]!;
  final mul = SrsTuning.intervalMul[rating]!;
  final v = (prev * ef * mul);
  return max(1, v.round());
}

double nextEf(double ef, String rating) {
  final d = SrsTuning.easeDelta[rating]!;
  final e = ef + d;
  return e.clamp(SrsTuning.easeMin, SrsTuning.easeMax);
}

void main() {
  group('applyAnswer expectations', () {
    const ef = SrsTuning.easeInit;

    test('table sanity', () {
      expect(nextIntervalDays(prev: 0, rating: 'easy', ef: ef), 2);
      expect(nextIntervalDays(prev: 1, rating: 'good', ef: ef), 2);
      expect(nextIntervalDays(prev: 6, rating: 'easy', ef: ef), 20);
      expect(nextIntervalDays(prev: 15, rating: 'hard', ef: ef), 18);
      expect(nextIntervalDays(prev: 45, rating: 'good', ef: ef), 112);
      expect(nextIntervalDays(prev: 120, rating: 'hard', ef: ef), 144);
    });

    test('ef updates', () {
      expect(nextEf(2.5, 'again'), 2.2);
      expect(nextEf(2.5, 'hard'), 2.35);
      expect(nextEf(2.5, 'good'), 2.5);
      expect(nextEf(2.5, 'easy'), 2.65);
      expect(nextEf(1.31, 'again'), 1.30); // clamp
      expect(nextEf(2.60, 'easy'), 2.70); // clamp
    });
  });
}
