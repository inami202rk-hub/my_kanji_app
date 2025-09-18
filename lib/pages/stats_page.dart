// lib/pages/stats_page.dart
import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/srs_service.dart';
import '../services/goal_service.dart';
import '../services/settings_service.dart';
import 'session_history_page.dart';
import '../widget/srs_overview_card.dart';
import '../widget/pwa_install_button.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _xp = 0;
  int _streak = 0;
  int _total = 0;
  int _correct = 0;
  double _acc = 0;

  int _dueToday = 0;
  int _overdue = 0;
  int _upcoming7 = 0;

  int _todaySolved = 0;
  int _weekSolved = 0;
  int _dailyGoal = 20;
  int _weeklyGoal = 100;

  double _avgEase = 0;
  double _avgInterval = 0;
  double _avgReps = 0;
  int _totalLapses = 0;
  int _newCount = 0;
  int _learning = 0;
  int _mature = 0;
  int _tracked = 0;

  // 追加：週間カレンダー
  late List<_DayBin> _week; // 今日含む7日

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _load() async {
    // 基本統計
    final xp = await StatsService.loadXp();
    final st = await StatsService.loadStreak();
    final tot = await StatsService.loadTotal();
    final cor = await StatsService.loadCorrect();
    final acc = await StatsService.loadAccuracy();

    // SRS集計
    final dueToday = await SrsService.countDueToday();
    final overdue = await SrsService.countOverdue();
    final upcoming7 = await SrsService.countUpcoming(days: 7);
    final sum = await SrsService.summarizeAll();

    // 目標進捗
    final ts = await GoalService.todaySolved();
    final ws = await GoalService.thisWeekSolved();
    final dg = await SettingsService.loadDailyGoal();
    final wg = await SettingsService.loadWeeklyGoal();

    // 週間カレンダー
    final allStates = await SrsService.loadAll(); // Map<String, SrsState>
    final today = _dateOnly(DateTime.now());
    final bins = List.generate(7, (i) => _DayBin(date: today.add(Duration(days: i))));
    for (final stt in allStates.values) {
      final d = _dateOnly(stt.due);
      final idx = d.difference(today).inDays;
      if (idx >= 0 && idx < 7) bins[idx].count++;
      if (d.isBefore(today)) {
        // 期限超過は day0 にも足しておく（今日やるべき件数として）
        bins[0].overdue++;
      }
    }

    setState(() {
      _xp = xp;
      _streak = st;
      _total = tot;
      _correct = cor;
      _acc = acc;

      _dueToday = dueToday;
      _overdue = overdue;
      _upcoming7 = upcoming7;

      _avgEase = sum.avgEase;
      _avgInterval = sum.avgInterval;
      _avgReps = sum.avgReps;
      _totalLapses = sum.totalLapses;
      _newCount = sum.newCount;
      _learning = sum.learning;
      _mature = sum.mature;
      _tracked = sum.totalTracked;

      _todaySolved = ts;
      _weekSolved = ws;
      _dailyGoal = dg;
      _weeklyGoal = wg;

      _week = bins;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('学習統計')), body: const Center(child: CircularProgressIndicator()));
    }

    double dailyRatio = _dailyGoal == 0 ? 0 : (_todaySolved / _dailyGoal).clamp(0, 1).toDouble();
    double weeklyRatio = _weeklyGoal == 0 ? 0 : (_weekSolved / _weeklyGoal).clamp(0, 1).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('学習統計')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(

          padding: const EdgeInsets.all(16),
          children: [
            const SrsOverviewCard(), // ← これだけでOK（現在デッキは Settings から自動取得）

            // 履歴導線
            Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('学習履歴を見る'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionHistoryPage())),
              ),
            ),
            const SizedBox(height: 12),

            // 目標
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('学習目標の進捗', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('今日: $_todaySolved / $_dailyGoal'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: dailyRatio),
                    const SizedBox(height: 12),
                    Text('今週: $_weekSolved / $_weeklyGoal'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: weeklyRatio),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _StatCard(title: 'XP', value: _xp.toString(), icon: Icons.flash_on),
            _StatCard(title: 'SRS 今日の復習', value: _dueToday.toString(), icon: Icons.today),
            _StatCard(title: 'SRS 積み残し', value: _overdue.toString(), icon: Icons.pending_actions),
            _StatCard(title: 'SRS 7日以内の予定', value: _upcoming7.toString(), icon: Icons.calendar_view_week),
            _StatCard(title: 'Streak（日）', value: _streak.toString(), icon: Icons.local_fire_department),
            _StatCard(title: '正答率', value: '${(_acc * 100).toStringAsFixed(1)} %', icon: Icons.percent),
            _StatCard(title: '解答数', value: '$_correct / $_total', icon: Icons.rule),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            const Align(alignment: Alignment.centerLeft, child: Text('SRS 進捗の詳細', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),

            _StatCard(title: 'SRS対象カード数', value: _tracked.toString(), icon: Icons.layers),
            _StatCard(title: '平均 Ease', value: _avgEase.toStringAsFixed(2), icon: Icons.tune),
            _StatCard(title: '平均 間隔(日)', value: _avgInterval.toStringAsFixed(1), icon: Icons.av_timer),
            _StatCard(title: '平均 連続正解(回)', value: _avgReps.toStringAsFixed(1), icon: Icons.repeat),
            _StatCard(title: '累計 Lapses', value: _totalLapses.toString(), icon: Icons.restart_alt),
            _StatCard(title: '段階: 新規 / 学習 / 成熟', value: '$_newCount / $_learning / $_mature', icon: Icons.insights),

            const SizedBox(height: 12),
            _WeekCard(bins: _week),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// ==== 週間カレンダー描画 ====
class _DayBin {
  final DateTime date;
  int count = 0;
  int overdue = 0;
  _DayBin({required this.date});
}

class _WeekCard extends StatelessWidget {
  final List<_DayBin> bins;
  const _WeekCard({required this.bins});

  String _label(DateTime d) => '${d.month}/${d.day}';

  @override
  Widget build(BuildContext context) {
    final maxCount = (bins.map((b) => b.count + (b.overdue > 0 && b == bins.first ? b.overdue : 0)).fold<int>(0, (a, b) => a > b ? a : b)).clamp(1, 999);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SRS 週間カレンダー（今日から7日）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Column(
            children: bins.asMap().entries.map((e) {
              final idx = e.key;
              final b = e.value;
              final base = b.count.toDouble();
              final overdue = idx == 0 ? b.overdue.toDouble() : 0.0;
              final total = base + overdue;
              final ratio = total / maxCount;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(width: 64, child: Text(_label(b.date))),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(height: 16, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
                          FractionallySizedBox(
                            widthFactor: total == 0 ? 0.0 : ratio,
                            child: Container(height: 16, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4))),
                          ),
                          if (overdue > 0)
                            FractionallySizedBox(
                              widthFactor: overdue / maxCount,
                              child: Container(height: 16, decoration: BoxDecoration(color: Colors.red.withOpacity(0.6), borderRadius: BorderRadius.circular(4))),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(total.toInt().toString()),
                        const PwaInstallButton(), // ← ここに追加

                  ],
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }
}
