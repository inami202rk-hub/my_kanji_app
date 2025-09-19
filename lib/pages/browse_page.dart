// lib/pages/browse_page.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/selection_service.dart';
import '../models/kanji.dart';
import 'quiz_page.dart';

class BrowsePage extends StatefulWidget {
  final String? initialDeck; // null の場合は設定から
  const BrowsePage({super.key, this.initialDeck});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  bool _loading = true;
  List<String> _levels = [];
  String _deck = ''; // 非null String
  List<Kanji> _all = [];
  final _searchCtrl = TextEditingController();

  // ★ フィールド（getter ではなく通常フィールド）
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final levels = await ApiService.fetchLevels();
      String deck =
          widget.initialDeck ?? (await SettingsService.loadDeck() ?? '');
      if (deck.isEmpty && levels.isNotEmpty) deck = levels.first;

      List<Kanji> list = [];
      if (deck.isNotEmpty) {
        list = await ApiService.fetchKanjiByDeck(deck);
      }

      setState(() {
        _levels = levels;
        _deck = deck;
        _all = list;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reloadDeck(String deck) async {
    setState(() {
      _deck = deck;
      _loading = true;
      _all = [];
      _selected.clear();
    });
    final list = await ApiService.fetchKanjiByDeck(deck);
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  List<Kanji> get _filtered {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return _all;
    return _all.where((k) {
      final m = k.meaning ?? '';
      return k.kanji.contains(q) ||
          m.contains(q) ||
          (k.reading ?? '').contains(q);
    }).toList();
  }

  Future<void> _saveCurrentSelection() async {
    final ids = _selected.toList(); // 文字列IDをそのまま保存
    if (ids.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('選択がありません')));
      return;
    }
    // _deck は non-null なので ?? は不要（dead_null_aware_expression 回避）
    await SelectionService.saveSelection(deck: _deck, ids: ids, mode: null);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('選択を保存しました')));
  }

  Future<void> _startFromSaved({required bool srs}) async {
    final stored = await SelectionService.loadSelection();
    if (stored == null || stored.ids.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存された選択はありません')));
      return;
    }

    // stored.deck が空なら現在の _deck を使う（?? は使わない）
    final deck = stored.deck.isNotEmpty ? stored.deck : _deck;

    final all = await ApiService.fetchKanjiByDeck(deck);
    final by = {for (final k in all) k.kanji: k};
    final subset = stored.ids.map((id) => by[id]).whereType<Kanji>().toList();

    if (subset.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('選択カードが見つかりません')));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(deck: deck, srsMode: srs, presetCards: subset),
      ),
    );
  }

  Future<void> _startFromCurrent({required bool srs}) async {
    if (_selected.isEmpty) return;
    final by = {for (final k in _all) k.kanji: k};
    final subset = _selected.map((id) => by[id]).whereType<Kanji>().toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizPage(deck: _deck, srsMode: srs, presetCards: subset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カード一覧（選択→保存/復元）'),
        actions: [
          // ★ ここから実際に _startFromSaved を参照（unused_element を解消）
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: '選択を保存',
            onPressed: _saveCurrentSelection,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: '保存した選択でクイズ',
            onPressed: () => _startFromSaved(srs: false),
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: '保存した選択でSRS',
            onPressed: () => _startFromSaved(srs: true),
          ),
          // ★ ここまで
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // デッキ切替 + 検索
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _deck.isEmpty ? null : _deck,
                          items: _levels
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          hint: const Text('デッキ'),
                          onChanged: (v) {
                            if (v != null) _reloadDeck(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: '漢字 / 意味 / 読み',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final k = _filtered[i];
                      final selected = _selected.contains(k.kanji);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(k.kanji);
                            } else {
                              _selected.remove(k.kanji);
                            }
                          });
                        },
                        title: Text('${k.kanji}  ${k.meaning ?? ''}'),
                        subtitle: Text(
                          '読み: ${(k.reading ?? '').isNotEmpty ? k.reading! : _readingStr(k)}',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
                // 下部アクション
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selected.isEmpty
                                ? null
                                : () => _startFromCurrent(srs: false),
                            icon: const Icon(Icons.quiz),
                            label: const Text('選択でクイズ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selected.isEmpty
                                ? null
                                : () => _startFromCurrent(srs: true),
                            icon: const Icon(Icons.schedule),
                            label: const Text('選択でSRS'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _readingStr(Kanji k) {
    if ((k.reading ?? '').trim().isNotEmpty) return k.reading!.trim();
    final parts = <String>[];
    if (k.onyomi != null && k.onyomi!.isNotEmpty)
      parts.add(k.onyomi!.join('・'));
    if (k.kunyomi != null && k.kunyomi!.isNotEmpty)
      parts.add(k.kunyomi!.join('・'));
    return parts.isEmpty ? '（読み未登録）' : parts.join(' / ');
  }
}
