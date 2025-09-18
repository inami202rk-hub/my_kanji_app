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
    SrsService.setPickDueOverride(null);
  });

  tearDown(() {
    SrsService.setPickDueOverride(null);
  });

  group('SrsService.dueKeysFromDeck', () {
    test('classifies cards at new/learning/mature boundaries', () async {
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
          'srs.max.new': 10,
          'srs.max.learn': 10,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
          'srsPreset': 'standard',
        },
      );

      final result = await SrsService.dueKeysFromDeck(states.keys, limit: 10, strategy: 'balanced');

      expect(result.toSet(), equals(states.keys.toSet()));
      bool isLearning(SrsState state) => state.reps > 0 && state.interval > 0 && state.interval < 21;

      final newIds = result.where((id) => states[id]!.interval == 0).toSet();
      final learningIds = result.where((id) => isLearning(states[id]!)).toSet();
      final matureIds = result.where((id) => !newIds.contains(id) && !learningIds.contains(id)).toSet();

      expect(newIds, equals({'newA', 'newWithReps'}));
      expect(learningIds, equals({'learningA', 'learningBoundary'}));
      expect(matureIds, containsAll({'preMatureNoReps', 'matureBorder', 'matureA'}));
    });

    test('respects category caps alongside the daily cap', () async {
      final base = today();
      final tomorrow = base.add(const Duration(days: 1));
      final dayAfter = base.add(const Duration(days: 2));

      final states = <String, SrsState>{};
      for (var i = 0; i < 30; i++) {
        states['new_$i'] = SrsState(id: 'new_$i', due: base, ease: 2.5, interval: 0, reps: 0, lapses: 0);
      }
      for (var i = 0; i < 60; i++) {
        states['learning_$i'] = SrsState(
          id: 'learning_$i',
          due: tomorrow,
          ease: 2.4,
          interval: 5 + (i % 3),
          reps: 2,
          lapses: 0,
        );
      }
      for (var i = 0; i < 10; i++) {
        states['mature_$i'] = SrsState(
          id: 'mature_$i',
          due: dayAfter,
          ease: 2.6,
          interval: 30 + i,
          reps: 6,
          lapses: 1,
        );
      }

      await seedPrefs(
        states: states,
        extras: const {
          'srsDailyCap.v1': 50,
          'srs.max.new': 20,
          'srs.max.learn': 50,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
          'srsPreset': 'standard',
        },
      );

      final result = await SrsService.dueKeysFromDeck(states.keys);

      expect(result.length, 50);
      final newCount = result.where((id) => states[id]!.interval == 0).length;
      final learningCount = result.where((id) {
        final state = states[id]!;
        return state.interval > 0 && state.interval < 21 && state.reps > 0;
      }).length;

      expect(newCount, lessThanOrEqualTo(20));
      expect(learningCount, lessThanOrEqualTo(50));
      expect(newCount + learningCount, result.length);
    });

    test('omits categories whose caps are set to zero', () async {
      final baseDue = today();
      final states = <String, SrsState>{
        'newCard': SrsState(id: 'newCard', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0),
        'learningCard': SrsState(id: 'learningCard', due: baseDue, ease: 2.4, interval: 5, reps: 2, lapses: 0),
        'matureCard': SrsState(id: 'matureCard', due: baseDue, ease: 2.6, interval: 30, reps: 4, lapses: 0),
      };

      await seedPrefs(
        states: states,
        extras: const {
          'srsDailyCap.v1': 10,
          'srs.max.new': 0,
          'srs.max.learn': 0,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
        },
      );

      final result = await SrsService.dueKeysFromDeck(states.keys, limit: 10);

      expect(result, equals(['matureCard']));
    });

    test('treats due dates on or before today as immediately due', () async {
      final todayDate = today();
      final yesterday = todayDate.subtract(const Duration(days: 1));
      final tomorrow = todayDate.add(const Duration(days: 1));

      final states = <String, SrsState>{
        'overdue': SrsState(id: 'overdue', due: yesterday, ease: 2.5, interval: 15, reps: 3, lapses: 0),
        'dueToday': SrsState(id: 'dueToday', due: todayDate, ease: 2.4, interval: 5, reps: 2, lapses: 0),
        'upcoming': SrsState(id: 'upcoming', due: tomorrow, ease: 2.6, interval: 40, reps: 6, lapses: 1),
      };

      await seedPrefs(
        states: states,
        extras: const {
          'srsDailyCap.v1': 2,
          'srs.max.new': 10,
          'srs.max.learn': 10,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
        },
      );

      final result = await SrsService.dueKeysFromDeck(states.keys, limit: 2, strategy: 'balanced');

      expect(result, containsAllInOrder(['overdue', 'dueToday']));
      expect(result, isNot(contains('upcoming')));
    });

    group('strategy resolution', () {
      test('uses provided strategy argument when supplied', () async {
        final captured = <String, Object?>{};
        SrsService.setPickDueOverride((keys, {required int limit, String strategy = 'balanced', Map<String, int>? wrongs, bool prioritizeWrongToggle = false, Map<String, SrsState>? statesCache}) async {
          captured['strategy'] = strategy;
          captured['limit'] = limit;
          captured['keys'] = List<String>.from(keys);
          return ['stub'];
        });

        await seedPrefs(
          states: {'card': SrsState.initial('card')},
          extras: const {
            'srsDailyCap.v1': 5,
            'srs.max.new': 5,
            'srs.max.learn': 5,
            'srsShuffle.v1': 'balanced',
            'prioritizeWrong.v1': false,
          },
        );

        final result = await SrsService.dueKeysFromDeck(['card'], limit: 5, strategy: 'random');

        expect(result, equals(['stub']));
        expect(captured['strategy'], 'random');
        expect(captured['limit'], 5);
      });

      test('falls back to stored shuffle setting when strategy is omitted', () async {
        String? observed;
        SrsService.setPickDueOverride((keys, {required int limit, String strategy = 'balanced', Map<String, int>? wrongs, bool prioritizeWrongToggle = false, Map<String, SrsState>? statesCache}) async {
          observed = strategy;
          return ['stub'];
        });

        await seedPrefs(
          states: {'card': SrsState.initial('card')},
          extras: const {
            'srsDailyCap.v1': 5,
            'srs.max.new': 5,
            'srs.max.learn': 5,
            'srsShuffle.v1': 'random',
            'prioritizeWrong.v1': false,
          },
        );

        await SrsService.dueKeysFromDeck(['card'], limit: 5);

        expect(observed, 'random');
      });

      test('defaults to balanced when no shuffle preference exists', () async {
        String? observed;
        SrsService.setPickDueOverride((keys, {required int limit, String strategy = 'balanced', Map<String, int>? wrongs, bool prioritizeWrongToggle = false, Map<String, SrsState>? statesCache}) async {
          observed = strategy;
          return ['stub'];
        });

        await seedPrefs(
          states: {'card': SrsState.initial('card')},
          extras: const {
            'srsDailyCap.v1': 5,
            'srs.max.new': 5,
            'srs.max.learn': 5,
            'srsShuffle.v1': '',
            'prioritizeWrong.v1': false,
          },
        );

        await SrsService.dueKeysFromDeck(['card'], limit: 5);

        expect(observed, 'balanced');
      });
    });

    test('passes prioritizeWrong toggle through to pickDue', () async {
      final observed = <bool>[];
      SrsService.setPickDueOverride((keys, {required int limit, String strategy = 'balanced', Map<String, int>? wrongs, bool prioritizeWrongToggle = false, Map<String, SrsState>? statesCache}) async {
        observed.add(prioritizeWrongToggle);
        return ['stub'];
      });

      await seedPrefs(
        states: {'card': SrsState.initial('card')},
        extras: const {
          'srsDailyCap.v1': 5,
          'srs.max.new': 5,
          'srs.max.learn': 5,
          'srsShuffle.v1': 'balanced',
          'prioritizeWrong.v1': false,
        },
      );

      await SrsService.dueKeysFromDeck(['card'], limit: 1);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('prioritizeWrong.v1', true);
      await SrsService.dueKeysFromDeck(['card'], limit: 1);

      expect(observed, equals([false, true]));
    });
  });

  group('SrsService.applyAnswer', () {
    test('promotes a new card to learning after a good answer', () async {
      final baseDue = today();
      final initial = SrsState(id: 'newCard', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0);

      await seedPrefs(states: {'newCard': initial}, extras: const {'srsPreset': 'standard'});

      final next = await SrsService.applyAnswer('newCard', SrsRating.good);
      final todayStart = today();

      expect(next.interval, 1);
      expect(next.reps, 1);
      expect(next.due.difference(todayStart).inDays, next.interval);

      final stored = await SrsService.loadAll();
      expect(stored['newCard']?.interval, 1);
    });

    test('hard answer keeps interval short and decreases ease', () async {
      final baseDue = today();
      final initial = SrsState(id: 'hardCard', due: baseDue, ease: 2.5, interval: 0, reps: 0, lapses: 0);

      await seedPrefs(states: {'hardCard': initial}, extras: const {'srsPreset': 'standard'});

      final next = await SrsService.applyAnswer('hardCard', SrsRating.hard);

      expect(next.interval, 1);
      expect(next.reps, 1);
      expect(next.ease, closeTo(2.35, 1e-6));
      expect(next.due.difference(today()).inDays, next.interval);
    });

    test('moves a learning card into mature range after a good answer', () async {
      final baseDue = today().subtract(const Duration(days: 3));
      final learning = SrsState(id: 'learningCard', due: baseDue, ease: 2.5, interval: 10, reps: 4, lapses: 1);

      await seedPrefs(states: {'learningCard': learning}, extras: const {'srsPreset': 'standard'});

      final next = await SrsService.applyAnswer('learningCard', SrsRating.good);
      final todayStart = today();

      expect(next.interval, greaterThanOrEqualTo(21));
      expect(next.reps, 5);
      expect(next.due.difference(todayStart).inDays, next.interval);
    });

    test('resets a mature card and increments lapses after an again answer', () async {
      final baseDue = today().subtract(const Duration(days: 5));
      final mature = SrsState(id: 'matureCard', due: baseDue, ease: 2.0, interval: 40, reps: 6, lapses: 2);

      await seedPrefs(states: {'matureCard': mature}, extras: const {'srsPreset': 'standard'});

      final next = await SrsService.applyAnswer('matureCard', SrsRating.again);

      expect(next.interval, 0);
      expect(next.reps, 0);
      expect(next.lapses, 3);
      expect(next.due, today());
      expect(next.ease, closeTo(1.8, 1e-6));
    });

    test('easy answer increases ease and extends interval', () async {
      final baseDue = today().subtract(const Duration(days: 2));
      final mature = SrsState(id: 'easyCard', due: baseDue, ease: 2.3, interval: 25, reps: 5, lapses: 1);

      await seedPrefs(states: {'easyCard': mature}, extras: const {'srsPreset': 'standard'});

      final next = await SrsService.applyAnswer('easyCard', SrsRating.easy);

      expect(next.reps, 6);
      expect(next.ease, closeTo(2.45, 1e-6));
      expect(next.interval, greaterThan(25));
      expect(next.due.difference(today()).inDays, next.interval);
    });
  });
}
