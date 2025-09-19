import 'dart:convert';

class Kanji {
  final int? id;
  final String? deck; // N3/N4/N5 等。サーバー側で補完されることもある
  final String kanji; // 本体
  final String? meaning; // 単一意味（後方互換）
  final List<String>? meanings; // 複数意味
  final String? reading; // 単一読み（後方互換）
  final List<String>? readings; // 複数読み
  final List<String>? kunyomi; // くんよみ
  final List<String>? onyomi; // おんよみ
  final String? visualHint; // 視覚ヒント
  final String? imagePath; // assets/images/...
  final List<String>? audioKunyomi;
  final List<String>? audioOnyomi;
  final String? example; // 例文
  final String? translation; // 例文の翻訳
  final List<String>? tags;
  final bool? isFavorite;

  const Kanji({
    this.id,
    this.deck,
    required this.kanji,
    this.meaning,
    this.meanings,
    this.reading,
    this.readings,
    this.kunyomi,
    this.onyomi,
    this.visualHint,
    this.imagePath,
    this.audioKunyomi,
    this.audioOnyomi,
    this.example,
    this.translation,
    this.tags,
    this.isFavorite,
  });

  /// JSON -> Kanji
  factory Kanji.fromJson(Map<String, dynamic> json) {
    List<String>? _optList(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.map((e) => e.toString()).toList();
      // カンマ区切りの文字列で来た場合も吸収
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return null;
        return s.split(',').map((e) => e.trim()).toList();
      }
      return null;
    }

    bool? _optBool(dynamic v) {
      if (v is bool) return v;
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true') return true;
        if (lower == 'false') return false;
      }
      if (v is num) return v != 0;
      return null;
    }

    return Kanji(
      id: json['id'] is int
          ? json['id'] as int
          : (json['id'] is num ? (json['id'] as num).toInt() : null),
      deck: (json['deck'] ?? json['level'])?.toString(),
      kanji: json['kanji']?.toString() ?? '',
      meaning: json['meaning']?.toString(),
      meanings: _optList(json['meanings']),
      reading: json['reading']?.toString(),
      readings: _optList(json['readings']),
      kunyomi: _optList(json['kunyomi']),
      onyomi: _optList(json['onyomi']),
      visualHint: json['visualHint']?.toString() ?? json['hint']?.toString(),
      imagePath: json['imagePath']?.toString(),
      audioKunyomi: _optList(json['audioKunyomi']),
      audioOnyomi: _optList(json['audioOnyomi']),
      example: json['example']?.toString(),
      translation: json['translation']?.toString(),
      tags: _optList(json['tags']),
      isFavorite: _optBool(json['favorite']),
    );
  }

  /// Kanji -> JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (deck != null) 'deck': deck,
      'kanji': kanji,
      if (meaning != null) 'meaning': meaning,
      if (meanings != null) 'meanings': meanings,
      if (reading != null) 'reading': reading,
      if (readings != null) 'readings': readings,
      if (kunyomi != null) 'kunyomi': kunyomi,
      if (onyomi != null) 'onyomi': onyomi,
      if (visualHint != null) 'visualHint': visualHint,
      if (imagePath != null) 'imagePath': imagePath,
      if (audioKunyomi != null) 'audioKunyomi': audioKunyomi,
      if (audioOnyomi != null) 'audioOnyomi': audioOnyomi,
      if (example != null) 'example': example,
      if (translation != null) 'translation': translation,
      if (tags != null) 'tags': tags,
      if (isFavorite != null) 'favorite': isFavorite,
    };
  }

  Kanji copyWith({
    int? id,
    String? deck,
    String? kanji,
    String? meaning,
    List<String>? meanings,
    String? reading,
    List<String>? readings,
    List<String>? kunyomi,
    List<String>? onyomi,
    String? visualHint,
    String? imagePath,
    List<String>? audioKunyomi,
    List<String>? audioOnyomi,
    String? example,
    String? translation,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return Kanji(
      id: id ?? this.id,
      deck: deck ?? this.deck,
      kanji: kanji ?? this.kanji,
      meaning: meaning ?? this.meaning,
      meanings: meanings ?? this.meanings,
      reading: reading ?? this.reading,
      readings: readings ?? this.readings,
      kunyomi: kunyomi ?? this.kunyomi,
      onyomi: onyomi ?? this.onyomi,
      visualHint: visualHint ?? this.visualHint,
      imagePath: imagePath ?? this.imagePath,
      audioKunyomi: audioKunyomi ?? this.audioKunyomi,
      audioOnyomi: audioOnyomi ?? this.audioOnyomi,
      example: example ?? this.example,
      translation: translation ?? this.translation,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}
