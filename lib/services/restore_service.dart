import 'dart:convert';

import '../models/srs_config.dart';
import 'favorites_service.dart';
import 'srs_config_store.dart';
import 'srs_service.dart';

class RestoreService {
  const RestoreService();

  Future<void> importJson(String jsonString) async {
    final backup = _parseBackup(jsonString);

    await SharedPrefsSrsConfigStore().save(backup.config);
    await SrsService.restoreAll(backup.states);

    final existing = (await FavoritesService.loadFavorites()).toSet();
    for (final favorite in backup.favorites) {
      if (existing.add(favorite)) {
        await FavoritesService.addFavorite(favorite);
      }
    }
  }

  void validate(String jsonString) {
    _parseBackup(jsonString);
  }
}

class _ParsedBackup {
  final SrsConfig config;
  final Map<String, SrsState> states;
  final List<String> favorites;

  const _ParsedBackup({
    required this.config,
    required this.states,
    required this.favorites,
  });
}

_ParsedBackup _parseBackup(String jsonString) {
  dynamic decoded;
  try {
    decoded = jsonDecode(jsonString);
  } on FormatException catch (e) {
    throw FormatException(
      'JSON\u306e\u5f62\u5f0f\u304c\u4e0d\u6b63\u3067\u3059: ${e.message}',
    );
  }

  if (decoded is! Map<String, dynamic>) {
    throw const FormatException(
      'JSON\u306e\u30eb\u30fc\u30c8\u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u304c\u4e0d\u6b63\u3067\u3059',
    );
  }

  final version = decoded['version'];
  if (version != '1') {
    throw UnsupportedError('Unsupported backup version');
  }

  final settings = decoded['settings'];
  if (settings is! Map<String, dynamic>) {
    throw const FormatException(
      'settings \u304c\u30aa\u30d6\u30b8\u30a7\u30af\u30c8\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
    );
  }
  final config = _parseConfig(settings);

  final srsState = decoded['srsState'];
  if (srsState is! List) {
    throw const FormatException(
      'srsState \u304c\u914d\u5217\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
    );
  }

  final states = <String, SrsState>{};
  for (final item in srsState) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException(
        'srsState \u304c\u914d\u5217\u3067\u306f\u3042\u308a\u307e\u305b\u3093???????',
      );
    }
    final state = _parseSrsItem(item);
    states[state.id] = state;
  }

  final favorites = decoded['favorites'];
  if (favorites is! List) {
    throw const FormatException(
      'favorites \u304c\u914d\u5217\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
    );
  }
  final favoriteKeys = <String>[];
  final seenFavorites = <String>{};
  for (final entry in favorites) {
    if (entry is! String) {
      throw const FormatException(
        'favorites \u304c\u914d\u5217\u3067\u306f\u3042\u308a\u307e\u305b\u3093????',
      );
    }
    if (seenFavorites.add(entry)) {
      favoriteKeys.add(entry);
    }
  }

  return _ParsedBackup(config: config, states: states, favorites: favoriteKeys);
}

SrsConfig _parseConfig(Map<String, dynamic> json) {
  int readNonNegativeInt(String key) {
    final value = json[key];
    if (value is! num) {
      throw FormatException(
        '$key \u304c\u6570\u5024\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
      );
    }
    final intValue = value.toInt();
    if (intValue < 0) {
      throw FormatException(
        '$key \u306f0\u4ee5\u4e0a\u3067\u3042\u308b\u5fc5\u8981\u304c\u3042\u308a\u307e\u3059',
      );
    }
    return intValue;
  }

  final maxNew = readNonNegativeInt('maxNew');
  final maxLearn = readNonNegativeInt('maxLearn');
  final dailyCap = readNonNegativeInt('dailyCap');
  final prioritizeWrong = json['prioritizeWrong'];
  if (prioritizeWrong is! bool) {
    throw const FormatException(
      'prioritizeWrong \u304c\u771f\u507d\u5024\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
    );
  }
  final strategyRaw = json['strategy'];
  if (strategyRaw is! String) {
    throw const FormatException(
      'strategy \u304c\u6587\u5b57\u5217\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
    );
  }
  final strategy = _parseStrategy(strategyRaw);

  return SrsConfig(
    maxNew: maxNew,
    maxLearn: maxLearn,
    dailyCap: dailyCap,
    prioritizeWrong: prioritizeWrong,
    strategy: strategy,
  );
}

SrsStrategy _parseStrategy(String raw) {
  switch (raw) {
    case 'balanced':
      return SrsStrategy.balanced;
    case 'front':
      return SrsStrategy.front;
    case 'shuffle':
      return SrsStrategy.shuffle;
    default:
      throw FormatException(
        'strategy \u306e\u5024\u304c\u4e0d\u6b63\u3067\u3059: $raw',
      );
  }
}

SrsState _parseSrsItem(Map<String, dynamic> json) {
  final key = json['key'];
  if (key is! String || key.isEmpty) {
    throw const FormatException('srsState.key \u304c\u4e0d\u6b63\u3067\u3059');
  }

  double readDouble(String name) {
    final value = json[name];
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException(
      '$name \u304c\u6570\u5024\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
    );
  }

  int readNonNegativeInt(String name) {
    final value = json[name];
    if (value is! num) {
      throw FormatException(
        '$name \u304c\u6570\u5024\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
      );
    }
    final intValue = value.toInt();
    if (intValue < 0) {
      throw FormatException(
        '$name \u306f0\u4ee5\u4e0a\u3067\u3042\u308b\u5fc5\u8981\u304c\u3042\u308a\u307e\u3059',
      );
    }
    return intValue;
  }

  DateTime readDueDate() {
    final raw = json['due'];
    if (raw == null) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    if (raw is! String) {
      throw const FormatException(
        'due \u304c\u6587\u5b57\u5217\u3067\u306f\u3042\u308a\u307e\u305b\u3093',
      );
    }
    final reg = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!reg.hasMatch(raw)) {
      throw FormatException(
        'due \u306e\u5f62\u5f0f\u304c\u4e0d\u6b63\u3067\u3059: $raw',
      );
    }
    final parts = raw.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  return SrsState(
    id: key,
    due: readDueDate(),
    ease: readDouble('ef'),
    interval: readNonNegativeInt('prevIntervalDays'),
    lapses: readNonNegativeInt('lapses'),
    reps: readNonNegativeInt('streak'),
  );
}
