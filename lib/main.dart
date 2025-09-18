// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/quiz_page.dart';
import 'pages/stats_page.dart';
import 'pages/settings_page.dart';
import 'pages/browse_page.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'pages/main_quick_start.dart';
import 'pages/wrong_page.dart';
import 'pages/tag_browser_page.dart';
import 'widget/pwa_install_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kanji Study',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _levels = [];
  String? _selectedDeck;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final lv = await ApiService.fetchLevels();
    setState(() {
      _levels = lv;
      if (_levels.isNotEmpty) {
        _selectedDeck ??= _levels.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kanji Study')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedDeck,
            hint: const Text('デッキを選択'),
            items: _levels
                .map((lv) => DropdownMenuItem(value: lv, child: Text(lv)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDeck = v),
          ),
          Expanded(
            child: Center(
              child: _selectedDeck == null
                  ? const Text('デッキを選択してください')
                  : Text('選択中: $_selectedDeck'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_arrow),
        label: const Text('クイックスタート'),
        onPressed: _selectedDeck == null
            ? null
            : () async {
                // 既定値を読んで初期化
                final initSize =
                    await SettingsService.loadQuizSize() ?? 10;
                final initMode =
                    await SettingsService.loadQuizMode() ?? 'meaningToKanji';

                final res = await showQuickStartDialog(
                  context,
                  initialSrs: false,
                  initialSize: initSize,
                  initialMode: initMode,
                );
                if (res == null) return;

                // 一時的に設定を上書き
                await SettingsService.saveQuizMode(res.quizMode);
                await SettingsService.saveQuizSize(res.quizSize);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        QuizPage(deck: _selectedDeck!, srsMode: res.srsMode),
                  ),
                );

                await _bootstrap();
              },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('メニュー',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('カード一覧'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BrowsePage(initialDeck: _selectedDeck ?? ''),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('統計'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsPage()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sentiment_dissatisfied),
              title: const Text('間違いノート'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WrongPage(deck: _selectedDeck ?? '')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.label),
              title: const Text('タグ'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TagBrowserPage(deck: _selectedDeck ?? '')),
              ),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(12),
              child: PwaInstallButton(), // ← Drawer の一番下に
            ),
          ],
        ),
      ),
    );
  }
}
