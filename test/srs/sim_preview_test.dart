import 'package:flutter_test/flutter_test.dart';
import 'package:my_kanji_app/models/srs_config.dart';
import 'package:my_kanji_app/services/srs_service.dart';
import 'package:my_kanji_app/srs/srs_tuning.dart';

void main() {
  group('simulatePreview()', () {
    const baseConfig = SrsConfig(
      maxNew: 20,
      maxLearn: 40,
      dailyCap: 200,
      prioritizeWrong: true,
      strategy: SrsStrategy.balanced,
    );

    test('monotonic: Again <= Good <= Easy', () {
      final input = const SrsPreviewDurationsInput(
        config: baseConfig,
        previousIntervalDays: 4,
        easeFactor: 2.5,
      );

      final result = SrsService.simulatePreview(input);
      expect(result.again <= result.good, isTrue,
          reason: 'again should be shortest');
      expect(result.good <= result.easy, isTrue,
          reason: 'easy should be longest');
    });

    test('clamping: Good/Easy never exceed 365 days', () {
      final input = const SrsPreviewDurationsInput(
        config: baseConfig,
        previousIntervalDays: 100000,
        easeFactor: 3.0,
      );

      final result = SrsService.simulatePreview(input);
      const maxInterval = Duration(days: 365);
      expect(result.good <= maxInterval, isTrue);
      expect(result.easy <= maxInterval, isTrue);
    });

    test('respects base step for again and min floor for good', () {
      final input = const SrsPreviewDurationsInput(
        config: baseConfig,
        previousIntervalDays: 0,
        easeFactor: SrsTuning.easeInit,
      );

      final result = SrsService.simulatePreview(input);
      expect(result.again, const Duration(days: 1));
      expect(result.good >= const Duration(days: 1), isTrue,
          reason: 'good should honour the min interval floor');
    });
  });
}
