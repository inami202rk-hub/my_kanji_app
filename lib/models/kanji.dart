// lib/models/kanji.dart
import 'dart:convert';

class Kanji {
  final int? id;
  final String? deck; // N3/N4/N5（サーバ側で補完される場合あり）
  final String kanji; // 例: 日
  final String? meaning; // 意味（例: day; sun）
  final String? reading; // ひとまとめの読みがある場合のみ
  final List<String>? kunyomi; // くんよみ
  final List<String>? onyomi; // おんよみ
  final String? visualHint; // 視覚ヒント
  final String? imagePath; // assets/images/...
  final List<String>? audioKunyomi;
  final List<String>? audioOnyomi;
  final String? example; // 例文
  final String? translation; // 例文の翻訳など

  const Kanji({
    this.id,
    this.deck,
    required this.kanji,
    this.meaning,
    this.reading,
    this.kunyomi,
    this.onyomi,
    this.visualHint,
    this.imagePath,
    this.audioKunyomi,
    this.audioOnyomi,
    this.example,
    this.translation,
  });

  /// JSON -> Kanji
  factory Kanji.fromJson(Map<String, dynamic> json) {
    List<String>? optList(dynamic v) {
      if (v == null) return null;
      if (v is List) return v.map((e) => e.toString()).toList();
      // カンマ区切りの文字列で来た場合の救済
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return null;
        return s.split(',').map((e) => e.trim()).toList();
      }
      return null;
    }

    return Kanji(
      id: json['id'] is int
          ? json['id'] as int
          : (json['id'] is num ? (json['id'] as num).toInt() : null),
      deck: json['deck']?.toString(),
      kanji: json['kanji']?.toString() ?? '',
      meaning: json['meaning']?.toString(),
      reading: json['reading']?.toString(),
      kunyomi: optList(json['kunyomi']),
      onyomi: optList(json['onyomi']),
      visualHint: json['visualHint']?.toString() ?? json['hint']?.toString(),
      imagePath: json['imagePath']?.toString(),
      audioKunyomi: optList(json['audioKunyomi']),
      audioOnyomi: optList(json['audioOnyomi']),
      example: json['example']?.toString(),
      translation: json['translation']?.toString(),
    );
  }

  /// Kanji -> JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (deck != null) 'deck': deck,
      'kanji': kanji,
      if (meaning != null) 'meaning': meaning,
      if (reading != null) 'reading': reading,
      if (kunyomi != null) 'kunyomi': kunyomi,
      if (onyomi != null) 'onyomi': onyomi,
      if (visualHint != null) 'visualHint': visualHint,
      if (imagePath != null) 'imagePath': imagePath,
      if (audioKunyomi != null) 'audioKunyomi': audioKunyomi,
      if (audioOnyomi != null) 'audioOnyomi': audioOnyomi,
      if (example != null) 'example': example,
      if (translation != null) 'translation': translation,
    };
  }

  Kanji copyWith({
    int? id,
    String? deck,
    String? kanji,
    String? meaning,
    String? reading,
    List<String>? kunyomi,
    List<String>? onyomi,
    String? visualHint,
    String? imagePath,
    List<String>? audioKunyomi,
    List<String>? audioOnyomi,
    String? example,
    String? translation,
  }) {
    return Kanji(
      id: id ?? this.id,
      deck: deck ?? this.deck,
      kanji: kanji ?? this.kanji,
      meaning: meaning ?? this.meaning,
      reading: reading ?? this.reading,
      kunyomi: kunyomi ?? this.kunyomi,
      onyomi: onyomi ?? this.onyomi,
      visualHint: visualHint ?? this.visualHint,
      imagePath: imagePath ?? this.imagePath,
      audioKunyomi: audioKunyomi ?? this.audioKunyomi,
      audioOnyomi: audioOnyomi ?? this.audioOnyomi,
      example: example ?? this.example,
      translation: translation ?? this.translation,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}

// ==== ここから追記/置換 ====
/// Kanji の null 安全ヘルパー（単数/複数の差を吸収）
extension KanjiX on Kanji {
  /// on/kun が null でも空配列を返す
  List<String> get onyomiList => (onyomi ?? const []);
  List<String> get kunyomiList => (kunyomi ?? const []);

  /// すべての読みを平坦化（単体 reading + on + kun）
  List<String> get readingsList {
    final r = <String>[];
    final base = (reading ?? '').trim();
    if (base.isNotEmpty) r.add(base);
    r.addAll(onyomiList);
    r.addAll(kunyomiList);
    return r;
  }

  /// 意味を配列化。
  /// モデルに meanings(List) が無い前提なので、meaning を分割して配列にする。
  /// ※ 将来 meanings が生えたら下の1行をアンコメントして先頭で addAll してください。
  List<String> get meaningsList {
    final list = <String>[];

    // もし List<String>? meanings が追加されたら:
    // list.addAll(meanings ?? const []);

    final m = (meaning ?? '').trim();
    if (m.isNotEmpty) {
      // 日本語の読点・英カンマ・スラッシュ・セミコロン等で緩く区切る
      final parts = m.split(RegExp(r'[、,/;]|・'));
      list.addAll(parts.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    return list;
  }

  /// タグ（無ければ空）
  List<String> get tagsList => (tags ?? const []);
}
// ==== ここまで ====

// ===== KanjiX extension の末尾あたりに追加 =====

extension KanjiCompatX on Kanji {
  /// 旧コードが使う `k.readings ?? const []` 互換
  /// 空なら null を返すことで `??` に流せる
  List<String>? get readings {
    final list = readingsList; // あなたが定義済み
    return list.isEmpty ? null : list;
  }

  /// 旧コードが使う `k.meanings ?? const []` 互換
  List<String>? get meanings {
    final list = meaningsList; // あなたが定義済み
    return list.isEmpty ? null : list;
  }

  /// 旧コードが `k.tags ?? tagsByKanji[...]` の形で使うため、
  /// デフォルトは null を返して後段にフォールバックさせる
  List<String>? get tags => null;

  /// 旧コードが `k.isFavorite` を読む場合の最小互換。
  /// お使いの FavoritesService に合わせて中身は調整してください。
  bool get isFavorite {
    // 例:
    // return FavoritesService.instance.contains(kanji);
    // サービスがまだ注入できないなら、とりあえず false を返してビルド優先
    return false;
  }
}
