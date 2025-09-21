import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_kanji_app/srs/srs_tuning.dart';

import '../models/srs_config.dart';
import 'srs_config_store.dart';
import 'wrong_service.dart';

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime _addDays(DateTime base, int days) =>
    DateTime(base.year, base.month, base.day).add(Duration(days: days));

int calcNextIntervalDays({
  required int prevIntervalDays,
  required String rating,
  required double ef,
}) {
  if (prevIntervalDays <= 0) {
    return SrsTuning.baseStepsDays[rating]!;
  }
  final mul = SrsTuning.intervalMul[rating]!;
  final rounded = (prevIntervalDays * ef * mul).round();
  const lower = 1;
  const upper = 1 << 30;
  if (rounded < lower) return lower;
  if (rounded > upper) return upper;
  return rounded;
}

double calcNextEf({required double currentEf, required String rating}) {
  final delta = SrsTuning.easeDelta[rating]!;
  final next = currentEf + delta;
  final minEf = SrsTuning.easeMin;
  final maxEf = SrsTuning.easeMax;
  if (next < minEf) return minEf;
  if (next > maxEf) return maxEf;
  return next;
}

class SrsState {
  final String id;
  final DateTime due;
  final double ease;
  final int interval;
  final int reps;
  final int lapses;

  const SrsState({
    required this.id,
    required this.due,
    required this.ease,
    required this.interval,
    required this.reps,
    required this.lapses,
  });

  SrsState copyWith({
    String? id,
    DateTime? due,
    double? ease,
    int? interval,
    int? reps,
    int? lapses,
  }) {
    return SrsState(
      id: id ?? this.id,
      due: due ?? this.due,
      ease: ease ?? this.ease,
      interval: interval ?? this.interval,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
    );
  }

  static SrsState initial([String id = '']) {
    final today = _today();
    return SrsState(
      id: id,
      due: today,
      ease: SrsTuning.easeInit,
      interval: 0,
      reps: 0,
      lapses: 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'due': due.millisecondsSinceEpoch,
    'ease': ease,
    'interval': interval,
    'reps': reps,
    'lapses': lapses,
  };

  factory SrsState.fromJson(Map<String, dynamic> json) => SrsState(
    id: json['id'] as String,
    due: DateTime.fromMillisecondsSinceEpoch((json['due'] as num).toInt()),
    ease: (json['ease'] as num).toDouble(),
    interval: (json['interval'] as num).toInt(),
    reps: (json['reps'] as num).toInt(),
    lapses: (json['lapses'] as num).toInt(),
  );
}

class SrsSummary {
  final int totalTracked;
  final double avgEase;
  final double avgInterval;
  final double avgReps;
  final int totalLapses;
  final int newCount;
  final int learning;
  final int mature;

  const SrsSummary({
    required this.totalTracked,
    required this.avgEase,
    required this.avgInterval,
    required this.avgReps,
    required this.totalLapses,
    required this.newCount,
    required this.learning,
    required this.mature,
  });
}

enum SrsRating { again, hard, good, easy }

String _ratingKey(SrsRating rating) {
  switch (rating) {
    case SrsRating.again:
      return 'again';
    case SrsRating.hard:
      return 'hard';
    case SrsRating.good:
      return 'good';
    case SrsRating.easy:
      return 'easy';
  }
}

typedef PickDueFn =
    Future<List<String>> Function(
      Iterable<String> keys, {
      required int limit,
      SrsStrategy strategy,
      Map<String, int>? wrongs,
      bool prioritizeWrongToggle,
      Map<String, SrsState>? statesCache,
    });

class SrsService {
  static const _storageKey = 'srs.v2';

  static PickDueFn? _pickDueOverride;
  static SrsConfigStore _configStore = SharedPrefsSrsConfigStore();

  @visibleForTesting
  static void setPickDueOverride(PickDueFn? override) {
    _pickDueOverride = override;
  }

  @visibleForTesting
  static void resetPickDueOverride() {
    _pickDueOverride = null;
  }

  @visibleForTesting
  static void setConfigStoreForTesting(SrsConfigStore store) {
    _configStore = store;
  }

  @visibleForTesting
  static void resetConfigStoreForTesting() {
    _configStore = SharedPrefsSrsConfigStore();
  }

  static Future<SrsConfig> loadConfig() {
    return _configStore.load();
  }

  static Future<Map<String, SrsState>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) =>
            MapEntry(key, SrsState.fromJson(value as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveAll(Map<String, SrsState> states) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      states.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString(_storageKey, encoded);
  }

  static Future<void> restoreAll(Map<String, SrsState> states) async {
    await _saveAll(states);
  }

  static Future<int> countOverdue() async {
    final today = _today();
    final all = await loadAll();
    return all.values.where((s) => _dateOnly(s.due).isBefore(today)).length;
  }

  static Future<int> countDueToday() async {
    final today = _today();
    final all = await loadAll();
    return all.values.where((s) => _dateOnly(s.due) == today).length;
  }

  static Future<int> countUpcoming({required int days}) async {
    final today = _today();
    final end = _addDays(today, days);
    final all = await loadAll();
    return all.values.where((s) {
      final due = _dateOnly(s.due);
      return (due.isAfter(today) || due == today) && !due.isAfter(end);
    }).length;
  }

  static Future<SrsSummary> summarizeAll() async {
    final all = await loadAll();
    if (all.isEmpty) {
      return const SrsSummary(
        totalTracked: 0,
        avgEase: 0,
        avgInterval: 0,
        avgReps: 0,
        totalLapses: 0,
        newCount: 0,
        learning: 0,
        mature: 0,
      );
    }

    double easeSum = 0;
    double intervalSum = 0;
    double repsSum = 0;
    int lapsesSum = 0;
    int newCount = 0;
    int learning = 0;
    int mature = 0;

    for (final state in all.values) {
      easeSum += state.ease;
      intervalSum += state.interval;
      repsSum += state.reps;
      lapsesSum += state.lapses;
      if (state.interval == 0) {
        newCount++;
      } else if (state.interval < 21 && state.reps > 0) {
        learning++;
      } else {
        mature++;
      }
    }

    final count = all.length;
    return SrsSummary(
      totalTracked: count,
      avgEase: easeSum / count,
      avgInterval: intervalSum / count,
      avgReps: repsSum / count,
      totalLapses: lapsesSum,
      newCount: newCount,
      learning: learning,
      mature: mature,
    );
  }

  static Future<SrsState> applyAnswer(String id, SrsRating rating) async {
    final all = await loadAll();
    final current = all[id] ?? SrsState.initial(id);
    final today = _today();

    final ratingKey = _ratingKey(rating);
    final nextEase = calcNextEf(currentEf: current.ease, rating: ratingKey);
    final nextIntervalDays = calcNextIntervalDays(
      prevIntervalDays: current.interval,
      rating: ratingKey,
      ef: nextEase,
    );

    final nextReps = rating == SrsRating.again ? 0 : current.reps + 1;
    final nextLapses = rating == SrsRating.again
        ? current.lapses + 1
        : current.lapses;

    final nextDue = rating == SrsRating.again
        ? today
        : _addDays(today, nextIntervalDays);
    final next = current.copyWith(
      due: nextDue,
      ease: nextEase,
      interval: rating == SrsRating.again ? 0 : nextIntervalDays,
      lapses: nextLapses,
      reps: nextReps,
    );

    all[id] = next;
    await _saveAll(all);
    return next;
  }

  static Future<SrsState> applyReview(String id, dynamic rating) {
    SrsRating toRating(dynamic value) {
      if (value is SrsRating) return value;
      if (value is int) {
        switch (value) {
          case 0:
            return SrsRating.again;
          case 1:
            return SrsRating.hard;
          case 2:
            return SrsRating.good;
          case 3:
            return SrsRating.easy;
        }
      }
      if (value is String) {
        switch (value.toLowerCase()) {
          case 'again':
          case 'a':
          case '0':
            return SrsRating.again;
          case 'hard':
          case 'h':
          case '1':
            return SrsRating.hard;
          case 'good':
          case 'g':
          case '2':
            return SrsRating.good;
          case 'easy':
          case 'e':
          case '3':
            return SrsRating.easy;
        }
      }
      return SrsRating.good;
    }

    return applyAnswer(id, toRating(rating));
  }

  static Future<List<String>> dueKeysFromDeck(
    Iterable<String> deckKeys, {
    int? limit,
    SrsStrategy? strategy,
  }) async {
    final config = await _configStore.load();
    final effectiveLimit =
        limit ??
        (config.dailyCap <= 0 ? SrsConfig.defaults.dailyCap : config.dailyCap);
    final maxNew = config.maxNew < 0 ? 0 : config.maxNew;
    final maxLearn = config.maxLearn < 0 ? 0 : config.maxLearn;
    final effectiveStrategy = strategy ?? config.strategy;
    final prioritizeWrong = config.prioritizeWrong;

    Map<String, int> wrongCounts = {};
    try {
      final wrongList = await WrongService.listAll();
      wrongCounts = {for (final item in wrongList) item.kanji: item.count};
    } catch (_) {
      wrongCounts = {};
    }

    final allStates = await loadAll();
    final entries = <String, SrsState>{};
    for (final key in deckKeys) {
      final state = allStates[key];
      if (state != null) {
        entries[key] = state;
      }
    }

    bool isLearning(SrsState state) =>
        state.interval > 0 && state.interval < 21 && state.reps > 0;

    final newCards = entries.entries
        .where((entry) => entry.value.interval == 0)
        .map((entry) => entry.key)
        .toList();
    final learning = entries.entries
        .where((entry) => isLearning(entry.value))
        .map((entry) => entry.key)
        .toList();
    final others = entries.entries
        .where(
          (entry) => !(entry.value.interval == 0 || isLearning(entry.value)),
        )
        .map((entry) => entry.key)
        .toList();

    final candidate = <String>[];
    if (maxNew > 0) {
      candidate.addAll(newCards.take(maxNew));
    }
    if (maxLearn > 0) {
      candidate.addAll(learning.take(maxLearn));
    }
    candidate.addAll(others);

    final deduped = candidate.toSet().toList();

    final pick = _pickDueOverride ?? pickDue;
    return pick(
      deduped,
      limit: effectiveLimit <= 0 ? SrsConfig.defaults.dailyCap : effectiveLimit,
      strategy: effectiveStrategy,
      wrongs: wrongCounts,
      prioritizeWrongToggle: prioritizeWrong,
      statesCache: allStates,
    );
  }

  static Future<List<String>> pickDue(
    Iterable<String> keys, {
    required int limit,
    SrsStrategy strategy = SrsStrategy.balanced,
    Map<String, int>? wrongs,
    bool prioritizeWrongToggle = false,
    Map<String, SrsState>? statesCache,
  }) async {
    final states = statesCache ?? await loadAll();
    final today = _today();

    final overdue = <String>[];
    final dueToday = <String>[];
    final upcoming = <String>[];

    for (final key in keys) {
      final state = states[key];
      if (state == null) continue;
      final dueDate = _dateOnly(state.due);
      if (dueDate.isBefore(today)) {
        overdue.add(key);
      } else if (dueDate == today) {
        dueToday.add(key);
      } else {
        upcoming.add(key);
      }
    }

    overdue.shuffle();
    dueToday.shuffle();
    upcoming.shuffle();

    double weightOf(String key) {
      final state = states[key]!;
      final wrong = (wrongs?[key] ?? 0).toDouble();
      final isOverdue = _dateOnly(state.due).isBefore(today);
      final isDueToday = _dateOnly(state.due) == today;
      final isLearning = state.reps > 0 && state.interval < 21;
      final lapseBonus = state.lapses * 0.5;
      double weight =
          1.0 +
          (isOverdue ? 3.0 : 0.0) +
          (isDueToday ? 1.5 : 0.0) +
          (isLearning ? 1.0 : 0.0) +
          lapseBonus +
          wrong * 2.0;
      if (prioritizeWrongToggle && wrong > 0) {
        weight *= 2.0;
      }
      return weight;
    }

    switch (strategy) {
      case SrsStrategy.balanced:
        final picked = <String>[];
        overdue.sort((a, b) => weightOf(b).compareTo(weightOf(a)));
        dueToday.sort((a, b) => weightOf(b).compareTo(weightOf(a)));
        upcoming.sort((a, b) => weightOf(b).compareTo(weightOf(a)));

        int idxOverdue = 0;
        int idxToday = 0;
        int idxUpcoming = 0;

        while (picked.length < limit &&
            (idxOverdue < overdue.length ||
                idxToday < dueToday.length ||
                idxUpcoming < upcoming.length)) {
          if (idxOverdue < overdue.length) {
            picked.add(overdue[idxOverdue++]);
          }
          if (picked.length >= limit) break;
          if (idxToday < dueToday.length) {
            picked.add(dueToday[idxToday++]);
          }
          if (picked.length >= limit) break;
          if (idxUpcoming < upcoming.length) {
            picked.add(upcoming[idxUpcoming++]);
          }
        }
        return picked.take(limit).toList();
      case SrsStrategy.front:
        final ordered = <String>[...overdue, ...dueToday, ...upcoming];
        ordered.sort((a, b) {
          final wrongA = wrongs?[a] ?? 0;
          final wrongB = wrongs?[b] ?? 0;
          if (prioritizeWrongToggle && wrongA != wrongB) {
            return wrongB.compareTo(wrongA);
          }
          final dueA = _dateOnly(states[a]!.due);
          final dueB = _dateOnly(states[b]!.due);
          final cmp = dueA.compareTo(dueB);
          if (cmp != 0) return cmp;
          return states[a]!.reps.compareTo(states[b]!.reps);
        });
        return ordered.take(limit).toList();
      case SrsStrategy.shuffle:
        final picked = <String>[];
        final pool = <String>[...overdue, ...dueToday, ...upcoming];
        while (picked.length < limit && pool.isNotEmpty) {
          final weights = pool.map(weightOf).toList();
          final total = weights.fold<double>(0, (sum, value) => sum + value);
          if (total == 0) {
            picked.add(pool.removeAt(0));
            continue;
          }
          double random =
              (total *
              (DateTime.now().microsecondsSinceEpoch % 1000000) /
              1000000.0);
          int chosen = 0;
          for (int i = 0; i < weights.length; i++) {
            random -= weights[i];
            if (random <= 0) {
              chosen = i;
              break;
            }
          }
          picked.add(pool.removeAt(chosen));
        }
        return picked.take(limit).toList();
    }
  }
}
