import 'package:flutter_test/flutter_test.dart';
import 'package:my_kanji_app/models/srs_config.dart';
import 'package:my_kanji_app/services/srs_service.dart';

void main() {
  group('simulatePreview()', () {
    const baseConfig = SrsConfig(
      maxNew: 20,
      maxLearn: 40,
      dailyCap: 200,
      prioritizeWrong: true,
      strategy: SrsStrategy.balanced,
    );

    test('Again <= Good <= Easy', () {
      final result = SrsService.simulatePreview(
        const SrsPreviewDurationsInput(
          config: baseConfig,
          previousIntervalDays: 3,
          easeFactor: 2.5,
        ),
      );

      expect(result.again <= result.good, isTrue);
      expect(result.good <= result.easy, isTrue);
    });

    test('Durations are clamped to reasonable upper bound', () {
      final result = SrsService.simulatePreview(
        const SrsPreviewDurationsInput(
          config: baseConfig,
          previousIntervalDays: 10000,
          easeFactor: 3.0,
        ),
      );

      const maxAllowed = Duration(days: 365);
      expect(result.good <= maxAllowed, isTrue);
      expect(result.easy <= maxAllowed, isTrue);
    });

    test('Again respects base step and good is at least one day', () {
      final result = SrsService.simulatePreview(
        const SrsPreviewDurationsInput(
          config: baseConfig,
          previousIntervalDays: 0,
        ),
      );

      expect(result.again >= const Duration(minutes: 1), isTrue);
      expect(result.good >= const Duration(days: 1), isTrue);
    });
  });
}
