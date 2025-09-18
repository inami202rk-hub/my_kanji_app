// lib/pages/wrong_page.dart
import 'package:flutter/material.dart';
import '../services/wrong_service.dart';
import '../services/api_service.dart';
import '../models/kanji.dart';
import 'quiz_page.dart';

class WrongPage extends StatefulWidget {
  final String deck; // "" なら全デッキ横断
  const WrongPage({super.key, required this.deck});

  @override
  State<WrongPage> createState() => _WrongPageState();
}

class _WrongPageState extends State<WrongPage> {
  bool _loading = true;
  List<WrongEntry> _items = [];
  Map<String, Kanji> _byKanji = {};

  // 追加：検索・並び替え
  final _searchCtrl = TextEditingController();
  String _order = 'recent'; // 'recent' | 'countDesc' | 'kanji'
  List<WrongEntry> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Wrong一覧（降順：ts）
    final items = await WrongService.listAll();

    // デッキで引けるカードだけ
    Map<String, Kanji> by = {};
    if (widget.deck.isEmpty) {
      final levels = await ApiService.fetchLevels();
      for (final d in levels) {
        final ks = await ApiService.fetchKanjiByDeck(d);
        by.addAll({for (final k in ks) k.kanji: k});
      }
    } else {
      final ks = await ApiService.fetchKanjiByDeck(widget.deck);
      by = {for (final k in ks) k.kanji: k};
    }
    final filtered = items.where((w) => by.containsKey(w.kanji)).toList();

    setState(() {
      _items = filtered;
      _byKanji = by;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim();
    var list = List<WrongEntry>.from(_items);
    if (q.isNotEmpty) {
      list = list.where((e) {
        final k = _byKanji[e.kanji];
        final meaning = k?.meaning ?? '';
        return e.kanji.contains(q) || meaning.contains(q);
      }).toList();
    }
    switch (_order) {
      case 'countDesc':
        list.sort((a, b) => b.count.compareTo(a.count));
        break;
      case 'kanji':
        list.sort((a, b) => a.kanji.compareTo(b.kanji));
        break;
      case 'recent':
      default:
        list.sort((a, b) {
          final at = a.ts?.millisecondsSinceEpoch ?? 0;
          final bt = b.ts?.millisecondsSinceEpoch ?? 0;
          return bt.compareTo(at);
        });
    }
    _filtered = list;
  }

  Future<void> _startQuiz({required bool srs}) async {
    if (_filtered.isEmpty) return;
    final subset = _filtered.map((w) => _byKanji[w.kanji]).whereType<Kanji>().toList();
    if (subset.isEmpty) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(
          deck: widget.deck.isEmpty ? 'Custom' : widget.deck,
          srsMode: srs,
          presetCards: subset,
        ),
      ),
    );
    await _load();
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('確認'),
        content: const Text('間違いノートをすべて削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (ok == true) {
      await WrongService.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
      await _load();
    }
  }

  String _dateStr(DateTime? dt) {
    if (dt == null) return '（記録なし）';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('間違いノート（${widget.deck.isEmpty ? "全デッキ" : widget.deck}）'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: _items.isEmpty ? null : _clearAll),
        ],
      ),
      body: Column(
        children: [
          // ←← AppBar 下の「検索＆並び替え」UI（これが 3) の回答です）
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: '漢字 or 意味で検索',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setState(_applyFilter),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _order,
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('最新順')),
                    DropdownMenuItem(value: 'countDesc', child: Text('ミス多い順')),
                    DropdownMenuItem(value: 'kanji', child: Text('漢字順')),
                  ],
                  onChanged: (v) => setState(() { _order = v ?? 'recent'; _applyFilter(); }),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_filtered.isEmpty
                    ? const Center(child: Text('該当なし'))
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final it = _filtered[i];
                          final k = _byKanji[it.kanji];
                          final title = k?.meaning?.isNotEmpty == true ? k!.meaning! : it.kanji;
                          final subtitle = 'ミス回数: ${it.count} / 最終: ${_dateStr(it.ts)}';
                          return ListTile(
                            leading: CircleAvatar(child: Text(it.kanji)),
                            title: Text(title),
                            subtitle: Text(subtitle),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'この漢字をノートから削除',
                              onPressed: () async {
                                await WrongService.removeWrong(it.kanji);
                                await _load();
                              },
                            ),
                          );
                        },
                      )),
          ),
        ],
      ),
      bottomNavigationBar: _filtered.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startQuiz(srs: false),
                        icon: const Icon(Icons.quiz),
                        label: const Text('表示中をクイズ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _startQuiz(srs: true),
                        icon: const Icon(Icons.schedule),
                        label: const Text('表示中をSRS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
