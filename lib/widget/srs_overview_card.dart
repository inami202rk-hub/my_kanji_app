// lib/widgets/srs_overview_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';
import '../services/srs_service.dart';

/// StatsPage に差し込むだけで使える「SRS 概要」カード。
/// - 対象デッキは引数 deck を優先。未指定なら Settings の現在デッキを使用。
/// - 表示内容：
///   - 今日の復習件数（合計/新規/学習中/成熟）
///   - 設定上限（新規/学習中/全体cap）
///   - 積み残し（overdue）
///   - 上限に対する進捗バー（新規/学習中）
class SrsOverviewCard extends StatefulWidget {
  final String? deck; // null の場合は設定から取得
  const SrsOverviewCard({super.key, this.deck});

  @override
  State<SrsOverviewCard> createState() => _SrsOverviewCardState();
}

class _SrsOverviewCardState extends State<SrsOverviewCard> {
  bool _loading = true;

  String _deckLabel = '';
  int _cap = 50;
  int _maxNew = 20;
  int _maxLearn = 50;

  // 今日の due 内訳
  int _dueTotal = 0;
  int _dueNew = 0;
  int _dueLearn = 0;
  int _dueMature = 0;

  int _overdue = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // 1) 対象デッキ名を決める
    final cfgDeck = await SettingsService.loadDeck(); // String?
    final useDeck = widget.deck ?? (cfgDeck?.isNotEmpty == true ? cfgDeck! : '');

    // 2) 設定値
    final capRaw = await SettingsService.loadSrsDailyCap();   // int?
    final maxNew = await SettingsService.loadSrsMaxNew();     // int
    final maxLearn = await SettingsService.loadSrsMaxLearn(); // int

    final cap = (capRaw == null || capRaw <= 0) ? 50 : capRaw;

    // 3) 対象デッキのカード集合
    final keys = <String>{};
    if (useDeck.isEmpty) {
      // 空なら全デッキ横断
      final levels = await ApiService.fetchLevels();
      for (final d in levels) {
        final list = await ApiService.fetchKanjiByDeck(d);
        keys.addAll(list.map((e) => e.kanji));
      }
    } else {
      final list = await ApiService.fetchKanjiByDeck(useDeck);
      keys.addAll(list.map((e) => e.kanji));
    }

    // 4) SRS 状態をロードして「今日の due」内訳を集計
    final all = await SrsService.loadAll();
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);

    int dueTotal = 0, dueNew = 0, dueLearn = 0, dueMature = 0, overdue = 0;
    for (final k in keys) {
      final st = all[k];
      if (st == null) continue;
      final d = DateTime(st.due.year, st.due.month, st.due.day);
      final isOver = d.isBefore(t0);
      final isTodayOrBefore = !d.isAfter(t0);
      if (isOver) overdue++;
      if (!isTodayOrBefore) continue;

      dueTotal++;
      if (st.interval == 0) {
        dueNew++;
      } else if (st.reps > 0 && st.interval < 21) {
        dueLearn++;
      } else {
        dueMature++;
      }
    }

    setState(() {
      _deckLabel = useDeck.isEmpty ? '全デッキ' : useDeck;
      _cap = cap;
      _maxNew = maxNew;
      _maxLearn = maxLearn;

      _dueTotal = dueTotal;
      _dueNew = dueNew;
      _dueLearn = dueLearn;
      _dueMature = dueMature;
      _overdue = overdue;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Card(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('SRS 概要を読み込み中…'),
            ],
          ),
        ),
      );
    }

    // 進捗バー計算
    double ratio(int v, int limit) {
      if (limit <= 0) return 0;
      final r = v / limit;
      return r.isNaN ? 0 : min(r, 1.0);
    }

    Widget kv(String k, String v) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(k), Text(v, style: const TextStyle(fontFeatures: []))],
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SRS 概要（$_deckLabel）', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 今日の復習内訳
            kv('今日の復習（<= 今日）', '$_dueTotal 件（新規 $_dueNew / 学習中 $_dueLearn / 成熟 $_dueMature）'),
            const SizedBox(height: 8),

            // 上限表示
            kv('上限（設定）', '新規 $_maxNew / 学習中 $_maxLearn / 全体Cap $_cap'),
            const SizedBox(height: 8),

            // 新規 進捗
            const Text('新規（今日の due / 上限）'),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: ratio(_dueNew, _maxNew), minHeight: 8),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_dueNew} / $_maxNew', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
            const SizedBox(height: 8),

            // 学習中 進捗
            const Text('学習中（今日の due / 上限）'),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: ratio(_dueLearn, _maxLearn), minHeight: 8),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${_dueLearn} / $_maxLearn', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),

            const SizedBox(height: 12),
            // 積み残し
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Text('積み残し（overdue）: $_overdue 件', style: const TextStyle(color: Colors.orange)),
              ],
            ),

            // 更新ボタン
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('更新'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
