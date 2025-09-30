import 'package:flutter_test/flutter_test.dart';
import 'package:my_kanji_app/models/srs_config.dart';
import 'package:my_kanji_app/services/srs_service.dart';

dateTime(int year, int month, int day) => DateTime(year, month, day);

void main() {
  group('SrsService.simulate', () {
    const baseConfig = SrsConfig(
      maxNew: 20,
      maxLearn: 40,
      dailyCap: 200,
      prioritizeWrong: true,
      strategy: SrsStrategy.balanced,
    );

    test('new card preview reflects base steps', () {
      final result = SrsService.simulate(
        SrsPreviewInput(
          config: baseConfig,
          state: PreviewCardState.newCard,
          ease: 2.5,
          interval: Duration.zero,
          lapses: 0,
          now: dateTime(2025, 1, 1),
          futureGoodSteps: 3,
        ),
      );

      expect(result.nextIntervals[SrsRating.again], Duration.zero);
      expect(result.nextIntervals[SrsRating.hard], const Duration(days: 1));
      expect(result.nextIntervals[SrsRating.good], const Duration(days: 1));
      expect(result.nextIntervals[SrsRating.easy], const Duration(days: 2));
      expect(result.futureGoodIntervals.length, 3);
      expect(result.futureGoodIntervals.first, const Duration(days: 1));
      expect(result.eta.first, dateTime(2025, 1, 2));
    });

    test('learning card produces increasing intervals', () {
      final result = SrsService.simulate(
        SrsPreviewInput(
          config: baseConfig,
          state: PreviewCardState.learning,
          ease: 2.4,
          interval: const Duration(days: 5),
          lapses: 1,
          now: dateTime(2025, 1, 10),
          futureGoodSteps: 2,
        ),
      );

      final hard = result.nextIntervals[SrsRating.hard]!;
      final good = result.nextIntervals[SrsRating.good]!;
      final easy = result.nextIntervals[SrsRating.easy]!;

      expect(hard.inDays, greaterThanOrEqualTo(1));
      expect(good, greaterThan(hard));
      expect(easy, greaterThan(good));
      expect(result.nextEase[SrsRating.again]!, lessThan(2.4));
      expect(result.futureGoodIntervals.length, 2);
      expect(
        result.futureGoodIntervals[1],
        greaterThan(result.futureGoodIntervals[0]),
      );
      expect(result.eta[1].isAfter(result.eta[0]), isTrue);
    });

    test('review card clamps negative inputs and limits steps', () {
      final result = SrsService.simulate(
        SrsPreviewInput(
          config: const SrsConfig(
            maxNew: 5,
            maxLearn: 5,
            dailyCap: 2,
            prioritizeWrong: false,
            strategy: SrsStrategy.shuffle,
          ),
          state: PreviewCardState.review,
          ease: double.nan,
          interval: const Duration(days: -3),
          lapses: -5,
          now: dateTime(2025, 5, 1),
          futureGoodSteps: 10,
        ),
      );

      // futureGoodSteps should clamp to dailyCap (2)
      expect(result.futureGoodIntervals.length, 2);
      expect(result.eta.length, 2);
      expect(
        result.futureGoodIntervals.first,
        greaterThanOrEqualTo(Duration.zero),
      );
      expect(
        result.futureGoodIntervals[1],
        greaterThanOrEqualTo(result.futureGoodIntervals.first),
      );
      expect(result.eta[1].isAfter(result.eta[0]), isTrue);
      for (final entry in result.nextIntervals.values) {
        expect(entry.isNegative, isFalse);
      }
    });
  });
}
