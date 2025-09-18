import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_kanji_app/services/srs_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> seedPrefs({
    Map<String, SrsState> states = const {},
    Map<String, Object> extras = const {},
  }) async {
    final data = <String, Object>{...extras};
    data['srs.v2'] = jsonEncode(states.map((key, value) => MapEntry(key, value.toJson())));
    SharedPreferences.setMockInitialValues(data);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  group('SrsService.dueKeysFromDeck', () {
    test('classifies cards into new, learning, and mature at category boundaries', () async {
      final baseDue = today();
      final states = <String, SrsState>{
        'newA': SrsState(id: 'newA', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0),
        'newWithReps': SrsState(id: 'newWithReps', due: baseDue, ease: 2.4, interval: 0, reps: 3, lapses: 1),
        'learningA': SrsState(id: 'learningA', due: baseDue, ease: 2.2, interval: 10, reps: 2, lapses: 0),
        'learningBoundary': SrsState(id: 'learningBoundary', due: baseDue, ease: 2.1, interval: 20, reps: 4, lapses: 1),
        'preMatureNoReps': SrsState(id: 'preMatureNoReps', due: baseDue, ease: 2.5, interval: 5, reps: 0, lapses: 0),
        'matureBorder': SrsState(id: 'matureBorder', due: baseDue, ease: 2.3, interval: 21, reps: 2, lapses: 0),
        'matureA': SrsState(id: 'matureA', due: baseDue, ease: 2.6, interval: 30, reps: 5, lapses: 1),
      };

      await seedPrefs(
        states: states,
        extras: const {
          'srsDailyCap.v1': 10,
          'srs.max.new': 5,
          'srs.max.learn': 5,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
          'wrong.v2': '{}',
          'srsPreset': 'standard',
        },
      );

      final deckOrder = [
        'newA',
        'newWithReps',
        'learningA',
        'learningBoundary',
        'preMatureNoReps',
        'matureBorder',
        'matureA',
      ];

      final result = await SrsService.dueKeysFromDeck(deckOrder, limit: 10, strategy: 'balanced');

      expect(result.toSet(), equals(states.keys.toSet()));
      bool isLearning(SrsState state) => state.interval > 0 && state.interval < 21 && state.reps > 0;
      final newIds = result.where((id) => states[id]!.interval == 0).toSet();
      final learningIds = result.where((id) => isLearning(states[id]!)).toSet();
      expect(newIds, equals({'newA', 'newWithReps'}));
      expect(learningIds, equals({'learningA', 'learningBoundary'}));
      expect(result, containsAll({'preMatureNoReps', 'matureBorder', 'matureA'}));
    });

    test('enforces maxNew/maxLearn limits and daily cap boundaries', () async {
      final baseDue = today();
      final tomorrow = baseDue.add(const Duration(days: 1));
      final states = <String, SrsState>{
        'new1': SrsState(id: 'new1', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0),
        'new2': SrsState(id: 'new2', due: baseDue, ease: 2.4, interval: 0, reps: 0, lapses: 0),
        'new3': SrsState(id: 'new3', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0),
        'learning1': SrsState(id: 'learning1', due: baseDue, ease: 2.3, interval: 5, reps: 2, lapses: 1),
        'learning2': SrsState(id: 'learning2', due: tomorrow, ease: 2.2, interval: 7, reps: 3, lapses: 0),
        'mature1': SrsState(id: 'mature1', due: baseDue, ease: 2.6, interval: 30, reps: 6, lapses: 3),
      };

      await seedPrefs(
        states: states,
        extras: const {
          'srsDailyCap.v1': 4,
          'srs.max.new': 2,
          'srs.max.learn': 1,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
          'wrong.v2': '{}',
          'srsPreset': 'standard',
        },
      );

      final deckOrder = ['new1', 'new2', 'new3', 'learning1', 'learning2', 'mature1'];

      final result = await SrsService.dueKeysFromDeck(deckOrder);

      expect(result.length, 4);
      final newCount = result.where((id) => states[id]!.interval == 0).length;
      final learningCount = result.where((id) => states[id]!.interval > 0 && states[id]!.interval < 21 && states[id]!.reps > 0).length;
      expect(newCount, 2);
      expect(learningCount, 1);
      expect(result, contains('mature1'));
      expect(result, isNot(contains('new3')));
      expect(result, isNot(contains('learning2')));
    });

    test('prioritizes wrong-marked cards when toggle is enabled', () async {
      final baseDue = today();
      final states = <String, SrsState>{
        'lapsesHeavy': SrsState(id: 'lapsesHeavy', due: baseDue, ease: 2.4, interval: 28, reps: 6, lapses: 6),
        'wrongCard': SrsState(id: 'wrongCard', due: baseDue, ease: 2.5, interval: 28, reps: 6, lapses: 0),
      };

      await seedPrefs(
        states: states,
        extras: {
          'srsDailyCap.v1': 5,
          'srs.max.new': 5,
          'srs.max.learn': 5,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
          'wrong.v2': jsonEncode({
            'wrongCard': {'count': 1, 'ts': 0},
          }),
          'srsPreset': 'standard',
        },
      );

      final deckOrder = ['lapsesHeavy', 'wrongCard'];

      final withoutToggle = await SrsService.dueKeysFromDeck(deckOrder, limit: 1, strategy: 'balanced');
      expect(withoutToggle.single, 'lapsesHeavy');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prioritizeWrong.v1', true);

      final withToggle = await SrsService.dueKeysFromDeck(deckOrder, limit: 1, strategy: 'balanced');
      expect(withToggle.single, 'wrongCard');
    });
  });

  group('SrsService.applyAnswer', () {
    test('promotes a new card to learning after a good answer', () async {
      final baseDue = today();
      final initial = SrsState(id: 'newCard', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0);

      await seedPrefs(
        states: {'newCard': initial},
        extras: const {
          'srsPreset': 'standard',
        },
      );

      final next = await SrsService.applyAnswer('newCard', SrsRating.good);
      final todayStart = today();

      expect(next.interval, 1);
      expect(next.reps, 1);
      expect(next.due.difference(todayStart).inDays, next.interval);

      final stored = await SrsService.loadAll();
      expect(stored['newCard']?.interval, 1);
    });

    test('moves a learning card into mature range after a good answer', () async {
      final baseDue = today().subtract(const Duration(days: 3));
      final learning = SrsState(id: 'learningCard', due: baseDue, ease: 2.5, interval: 10, reps: 4, lapses: 1);

      await seedPrefs(
        states: {'learningCard': learning},
        extras: const {
          'srsPreset': 'standard',
        },
      );

      final next = await SrsService.applyAnswer('learningCard', SrsRating.good);
      final todayStart = today();

      expect(next.interval, greaterThanOrEqualTo(21));
      expect(next.reps, 5);
      expect(next.due.difference(todayStart).inDays, next.interval);
    });

    test('resets a mature card to new state after an again answer', () async {
      final baseDue = today().subtract(const Duration(days: 5));
      final mature = SrsState(id: 'matureCard', due: baseDue, ease: 2.0, interval: 40, reps: 6, lapses: 2);

      await seedPrefs(
        states: {'matureCard': mature},
        extras: const {
          'srsPreset': 'standard',
        },
      );

      final next = await SrsService.applyAnswer('matureCard', SrsRating.again);

      expect(next.interval, 0);
      expect(next.reps, 0);
      expect(next.lapses, 3);
      expect(next.due, today());
      expect(next.ease, closeTo(1.8, 1e-6));
    });
  });
}
