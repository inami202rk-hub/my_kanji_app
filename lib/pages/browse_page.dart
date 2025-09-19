import 'package:flutter/material.dart';

import '../models/kanji.dart';
import '../services/api_service.dart';
import '../services/selection_service.dart';
import '../services/settings_service.dart';
import '../utils/debounce.dart';
import 'quiz_page.dart';

class BrowsePage extends StatefulWidget {
  final String? initialDeck;
  const BrowsePage({super.key, this.initialDeck});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  final Set<String> _selected = <String>{};
  final Map<String, Kanji> _knownKanji = {};

  bool _loading = true;
  List<String> _levels = [];
  String _level = 'All';
  String _readingType = 'All';
  bool _favoriteOnly = false;
  String _query = '';
  String _tag = '';
  int _page = 0;
  final int _size = 20;
  int _total = 0;
  List<Kanji> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tagCtrl.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final levels = await ApiService.fetchLevels();
      final stored = widget.initialDeck ?? await SettingsService.loadDeck();
      final initial =
          (stored != null && stored.isNotEmpty && levels.contains(stored))
          ? stored
          : (levels.isNotEmpty ? levels.first : 'All');
      setState(() {
        _levels = levels;
        _level = initial;
        _searchCtrl.text = _query;
        _tagCtrl.text = _tag;
      });
      await _runSearch(resetPage: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runSearch({bool resetPage = false}) async {
    final nextPage = resetPage ? 0 : _page;
    setState(() {
      if (resetPage) {
        _page = 0;
        _items = const [];
        _total = 0;
      }
      _loading = true;
    });
    try {
      final service = const ApiService();
      final result = await service.searchKanji(
        query: _query,
        page: nextPage,
        size: _size,
        favoriteOnly: _favoriteOnly,
        level: _level,
        readingType: _readingType == 'All' ? null : _readingType,
        tag: _tag.isEmpty ? null : _tag,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _total = result.total;
        _page = result.page;
        for (final k in result.items) {
          _knownKanji[k.kanji] = k;
        }
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _total = 0;
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('検索に失敗しました: $err')));
    }
  }

  int _maxPage() => _total == 0 ? 0 : ((_total - 1) ~/ _size);

  void _nextPage() {
    if (_page >= _maxPage()) return;
    setState(() => _page += 1);
    _runSearch();
  }

  void _prevPage() {
    if (_page == 0) return;
    setState(() => _page -= 1);
    _runSearch();
  }

  Future<void> _saveCurrentSelection() async {
    if (_level == 'All') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('レベルを選択してから保存してください')));
      return;
    }
    final ids = _selected.toList();
    if (ids.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('選択がありません')));
      return;
    }
    await SelectionService.saveSelection(deck: _level, ids: ids, mode: null);
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
      ).showSnackBar(const SnackBar(content: Text('保存された選択がありません')));
      return;
    }
    final deck = stored.deck.isNotEmpty
        ? stored.deck
        : (_level != 'All'
              ? _level
              : (_levels.isNotEmpty ? _levels.first : ''));
    if (deck.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('デッキを特定できませんでした')));
      return;
    }
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
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(deck: deck, srsMode: srs, presetCards: subset),
      ),
    );
  }

  Future<void> _startFromCurrent({required bool srs}) async {
    if (_selected.isEmpty) return;
    if (_level == 'All') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('レベルを選択してから開始してください')));
      return;
    }
    final subset = _selected
        .map((id) => _knownKanji[id])
        .whereType<Kanji>()
        .toList();
    if (subset.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('選択カードの情報が見つかりません')));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            QuizPage(deck: _level, srsMode: srs, presetCards: subset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _maxPage() + 1;
    final currentPageLabel = _total == 0 ? 0 : _page + 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('カード一覧（検索/保存）'),
        actions: [
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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                Row(
                  children: [
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
                        onChanged: (value) {
                          setState(() => _query = value);
                          _debouncer.run(() => _runSearch(resetPage: true));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _tagCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.label),
                          hintText: 'タグ / 部首',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _tag = value);
                          _debouncer.run(() => _runSearch(resetPage: true));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _level,
                        items: ['All', ..._levels]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        decoration: const InputDecoration(
                          labelText: 'レベル',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _level = value;
                            _selected.clear();
                          });
                          _runSearch(resetPage: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _readingType,
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('読み種別: すべて'),
                          ),
                          DropdownMenuItem(value: 'on', child: Text('音読み')),
                          DropdownMenuItem(value: 'kun', child: Text('訓読み')),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _readingType = value);
                          _runSearch(resetPage: true);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('お気に入りのみ'),
                        Switch(
                          value: _favoriteOnly,
                          onChanged: (value) {
                            setState(() => _favoriteOnly = value);
                            _runSearch(resetPage: true);
                          },
                        ),
                      ],
                    ),
                    Text('合計 $_total 件'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Page $currentPageLabel / $totalPages'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _loading || _page == 0 ? null : _prevPage,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _loading || _page >= _maxPage()
                              ? null
                              : _nextPage,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                ? const Center(child: Text('該当するカードがありません'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final k = _items[index];
                      final selected = _selected.contains(k.kanji);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (_level == 'All')
                            ? null
                            : (v) {
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
    if (k.onyomi != null && k.onyomi!.isNotEmpty) {
      parts.add(k.onyomi!.join('・'));
    }
    if (k.kunyomi != null && k.kunyomi!.isNotEmpty) {
      parts.add(k.kunyomi!.join('・'));
    }
    return parts.isEmpty ? '読み未登録' : parts.join(' / ');
  }
}
