// lib/pages/tag_browser_page.dart
import 'package:flutter/material.dart';
import '../services/tags_service.dart';
import '../services/tag_count_service.dart';
import '../services/api_service.dart';
import '../models/kanji.dart';
import 'quiz_page.dart';

class TagBrowserPage extends StatefulWidget {
  final String deck; // "" なら全デッキ
  const TagBrowserPage({super.key, required this.deck});

  @override
  State<TagBrowserPage> createState() => _TagBrowserPageState();
}

class _TagBrowserPageState extends State<TagBrowserPage> {
  bool _loading = true;
  List<String> _tags = [];
  Map<String, int> _count = {};
  Map<String, int> _colors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final deckKey = widget.deck.isEmpty ? 'ALL' : widget.deck;

    // 1) 色
    final colors = await TagsService.allTagColors();

    // 2) 件数（キャッシュ優先）
    Map<String, int> counts = await TagCountService.getCounts(deck: deckKey);

    // 3) キャッシュが空ならフォールバック集計（初回のみ想定）
    if (counts.isEmpty) {
      counts = {};
      if (widget.deck.isEmpty) {
        final levels = await ApiService.fetchLevels();
        for (final d in levels) {
          final ks = await ApiService.fetchKanjiByDeck(d);
          for (final k in ks) {
            final ts = await TagsService.loadTags(k.kanji);
            for (final t in ts) {
              counts[t] = (counts[t] ?? 0) + 1;
            }
          }
        }
      } else {
        final ks = await ApiService.fetchKanjiByDeck(widget.deck);
        for (final k in ks) {
          final ts = await TagsService.loadTags(k.kanji);
          for (final t in ts) {
            counts[t] = (counts[t] ?? 0) + 1;
          }
        }
      }
      // 計算したのでキャッシュ保存
      await TagCountService.putCounts(deck: deckKey, counts: counts);
    }

    final tags = counts.keys.toList()..sort();

    setState(() {
      _colors = colors;
      _count = counts;
      _tags = tags;
      _loading = false;
    });
  }

  Future<void> _startQuizForTag(String tag, {required bool srs}) async {
    final deck = widget.deck;
    final subset = <Kanji>[];
    if (deck.isEmpty) {
      final levels = await ApiService.fetchLevels();
      for (final d in levels) {
        final ks = await ApiService.fetchKanjiByDeck(d);
        for (final k in ks) {
          final tags = await TagsService.loadTags(k.kanji);
          if (tags.contains(tag)) subset.add(k);
        }
      }
    } else {
      final ks = await ApiService.fetchKanjiByDeck(deck);
      for (final k in ks) {
        final tags = await TagsService.loadTags(k.kanji);
        if (tags.contains(tag)) subset.add(k);
      }
    }

    if (subset.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          deck: deck.isEmpty ? 'Custom' : deck,
          srsMode: srs,
          presetCards: subset,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('タグ（${widget.deck.isEmpty ? "全デッキ" : widget.deck}）'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_tags.isEmpty
                ? const Center(child: Text('タグがありません'))
                : ListView.separated(
                    itemCount: _tags.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = _tags[i];
                      final n = _count[t] ?? 0;
                      final colorValue = _colors[t];
                      final bg = (colorValue == null)
                          ? null
                          : Color(colorValue);
                      final fg = (bg == null)
                          ? null
                          : (ThemeData.estimateBrightnessForColor(bg) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bg,
                          child: Text(
                            t.characters.first,
                            style: TextStyle(color: fg),
                          ),
                        ),
                        title: Text(t),
                        subtitle: Text('$n 件'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _startQuizForTag(t, srs: false),
                              icon: const Icon(Icons.quiz),
                              label: const Text('クイズ'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _startQuizForTag(t, srs: true),
                              icon: const Icon(Icons.schedule),
                              label: const Text('SRS'),
                            ),
                          ],
                        ),
                      );
                    },
                  )),
    );
  }
}
