// lib/pages/session_history_page.dart
import 'package:flutter/material.dart';
import '../services/session_log_service.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});
  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
  bool _loading = true;
  List<SessionLog> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await SessionLogService.list();
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  String _fmt(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _modeJp(String m) => switch (m) {
    'kanjiToMeaning' => '漢字→意味',
    'kanjiToReading' => '漢字→読み',
    _ => '意味→漢字',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学習履歴'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: '全削除',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('確認'),
                  content: const Text('履歴をすべて削除しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await SessionLogService.clear();
                await _load();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_items.isEmpty
                ? const Center(child: Text('履歴はありません'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final it = _items[i];
                      final ratio = it.total == 0 ? 0.0 : it.correct / it.total;
                      return ListTile(
                        leading: Icon(it.srsMode ? Icons.schedule : Icons.quiz),
                        title: Text(
                          '${it.deck} / ${it.srsMode ? "SRS" : "通常"} / ${_modeJp(it.quizMode)}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_fmt(it.at)}'),
                            Text(
                              '成績: ${it.correct} / ${it.total}  (${(ratio * 100).toStringAsFixed(1)}%)',
                            ),
                          ],
                        ),
                      );
                    },
                  )),
    );
  }
}
