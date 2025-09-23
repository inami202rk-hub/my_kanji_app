import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_kanji_app/models/srs_config.dart';
import 'package:my_kanji_app/services/backup_service.dart';
import 'package:my_kanji_app/services/favorites_service.dart';
import 'package:my_kanji_app/services/restore_service.dart';
import 'package:my_kanji_app/services/srs_config_store.dart';
import 'package:my_kanji_app/services/srs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'backup -> restore roundtrip preserves settings/SRS/favorites',
    () async {
      final configStore = SharedPrefsSrsConfigStore();
      const seededConfig = SrsConfig(
        maxNew: 21,
        maxLearn: 34,
        dailyCap: 123,
        prioritizeWrong: true,
        strategy: SrsStrategy.balanced,
      );
      await configStore.save(seededConfig);

      final now = DateTime.now();
      final originalStates = <String, SrsState>{
        'kanji:海': SrsState(
          id: 'kanji:海',
          due: DateTime(now.year, now.month, now.day + 3),
          ease: 2.5,
          interval: 15,
          reps: 4,
          lapses: 1,
        ),
        'kanji:山': SrsState(
          id: 'kanji:山',
          due: DateTime(now.year, now.month, now.day + 1),
          ease: 2.3,
          interval: 10,
          reps: 2,
          lapses: 0,
        ),
      };
      await SrsService.restoreAll(originalStates);

      await FavoritesService.addFavorite('kanji:海');
      await FavoritesService.addFavorite('kanji:山');

      final jsonStr = await const BackupService().exportJson();
      final exported = jsonDecode(jsonStr) as Map<String, dynamic>;

      await configStore.save(
        const SrsConfig(
          maxNew: 0,
          maxLearn: 0,
          dailyCap: 0,
          prioritizeWrong: false,
          strategy: SrsStrategy.balanced,
        ),
      );
      await SrsService.restoreAll(<String, SrsState>{});
      final existingFavorites = await FavoritesService.loadFavorites();
      for (final favorite in existingFavorites) {
        await FavoritesService.removeFavorite(favorite);
      }

      await const RestoreService().importJson(jsonStr);

      final restoredConfig = await configStore.load();
      expect(restoredConfig.maxNew, seededConfig.maxNew);
      expect(restoredConfig.maxLearn, seededConfig.maxLearn);
      expect(restoredConfig.dailyCap, seededConfig.dailyCap);
      expect(restoredConfig.prioritizeWrong, seededConfig.prioritizeWrong);
      expect(restoredConfig.strategy, seededConfig.strategy);

      final restoredStates = await SrsService.loadAll();
      expect(restoredStates.keys.toSet(), originalStates.keys.toSet());
      for (final key in originalStates.keys) {
        final a = originalStates[key]!;
        final b = restoredStates[key]!;
        expect(b.ease, closeTo(a.ease, 1e-9));
        expect(b.interval, a.interval);
        expect(_fmt(b.due), _fmt(a.due));
        expect(b.lapses, a.lapses);
        expect(b.reps, a.reps);
      }

      final restoredFavorites = await FavoritesService.loadFavorites();
      expect(restoredFavorites.contains('kanji:海'), isTrue);
      expect(restoredFavorites.contains('kanji:山'), isTrue);

      final jsonStr2 = await const BackupService().exportJson();
      final exportedAgain = jsonDecode(jsonStr2) as Map<String, dynamic>;
      _assertCorePayloadEqual(exported, exportedAgain);
    },
  );
}

String? _fmt(DateTime? value) {
  if (value == null) {
    return null;
  }
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

void _assertCorePayloadEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
  Map<String, dynamic> normalize(Map<String, dynamic> source) {
    final settings = Map<String, dynamic>.from(
      source['settings'] as Map<String, dynamic>,
    );
    final srsState =
        (source['srsState'] as List)
            .map(
              (entry) =>
                  Map<String, dynamic>.from(entry as Map<String, dynamic>),
            )
            .toList()
          ..sort(
            (lhs, rhs) =>
                (lhs['key'] as String).compareTo(rhs['key'] as String),
          );
    final favorites =
        (source['favorites'] as List).map((entry) => entry.toString()).toList()
          ..sort();
    return <String, dynamic>{
      'settings': settings,
      'srsState': srsState,
      'favorites': favorites,
    };
  }

  final normalizedA = normalize(a);
  final normalizedB = normalize(b);
  expect(jsonEncode(normalizedA), jsonEncode(normalizedB));
}
