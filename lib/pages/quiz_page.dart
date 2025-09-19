// lib/pages/quiz_page.dart
// 直近版（重み付け・セッション復元・TTS 等を含むもの）をベースに、下記差分を適用済みの“丸ごと置換版”
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/kanji.dart';
import '../services/api_service.dart';
import '../services/stats_service.dart';
import '../services/settings_service.dart';
import '../services/srs_service.dart';
import '../services/wrong_service.dart';
import '../services/session_service.dart';
import '../services/goal_service.dart';
import '../services/session_log_service.dart';
import '../services/tts_service.dart';

class QuizPage extends StatefulWidget {
  final String deck;
  final bool srsMode;
  final List<Kanji>? presetCards;

  const QuizPage({
    super.key,
    required this.deck,
    this.srsMode = false,
    this.presetCards,
  });

  const QuizPage.resumeSession({
    super.key,
    required String deck,
    required bool srsMode,
    required this.presetCards,
  }) : deck = deck,
       srsMode = srsMode;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

enum QuizMode { meaningToKanji, kanjiToMeaning, kanjiToReading }

class _QuizPageState extends State<QuizPage> {
  List<Kanji> _cards = [];
  int _index = 0;
  int _correct = 0;
  bool _loading = true;
  int _quizSize = 10;
  QuizMode _mode = QuizMode.meaningToKanji;
  bool _showAnswer = false;

  bool _timerEnabled = false;
  int _timerSeconds = 15;
  int _remaining = 0;
  Timer? _timer;

  bool _prioritizeWrong = false;

  String _srsPreset = 'standard'; // 追加

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _saveSession() async {
    final s = QuizSession(
      deck: widget.deck,
      srsMode: widget.srsMode,
      kanjiList: _cards.map((k) => k.kanji).toList(),
      index: _index,
      correct: _correct,
    );
    await SessionService.save(s);
  }

  Future<void> _clearSession() => SessionService.clear();

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimerForQuestion() {
    if (!_timerEnabled) {
      _remaining = 0;
      return;
    }
    _cancelTimer();
    _remaining = _timerSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _cancelTimer();
          widget.srsMode ? _applySrsAndNext(grade: 0) : _onAnswer(false);
        }
      });
    });
  }

  // ===== 重み付け（通常出題時） =====
  double _weightFor(
    String kanji,
    Map<String, SrsState> srsMap,
    Map<String, int> wrongs,
  ) {
    final st = srsMap[kanji] ?? SrsState.initial(); // ← 引数省略可でOK
    final wrongCount = (wrongs[kanji] ?? 0).toDouble();
    final now = DateTime.now();
    final overdue = st.due.isBefore(DateTime(now.year, now.month, now.day))
        ? 1.0
        : 0.0;
    final learning = (st.reps > 0 && st.interval < 21) ? 1.0 : 0.0;

    double w =
        1.0 +
        wrongCount * 2.0 +
        overdue * 1.5 +
        learning * 1.2 +
        st.lapses * 0.5;

    if (_prioritizeWrong && wrongCount > 0) {
      w *= 2.5; // 強化倍率（調整可）
    }
    return w;
  }

  List<Kanji> _sampleWeighted(
    List<Kanji> all,
    int n,
    Map<String, SrsState> srsMap,
    Map<String, int> wrongs,
  ) {
    if (all.length <= n) return List<Kanji>.from(all);
    final rng = Random();
    final pool = List<Kanji>.from(all);
    final picked = <Kanji>[];
    while (picked.length < n && pool.isNotEmpty) {
      final weights = pool
          .map((k) => _weightFor(k.kanji, srsMap, wrongs))
          .toList();
      final sum = weights.fold<double>(0, (a, b) => a + b);
      double r = rng.nextDouble() * sum;
      int chosen = 0;
      for (int i = 0; i < weights.length; i++) {
        r -= weights[i];
        if (r <= 0) {
          chosen = i;
          break;
        }
      }
      picked.add(pool.removeAt(chosen));
    }
    return picked;
  }

  // ===== プリセットに応じて grade を変換 =====
  int _mapGrade(int grade) {
    switch (_srsPreset) {
      case 'light': // やさしめ
        return switch (grade) {
          0 => 0,
          1 => 2,
          2 => 3,
          3 => 3,
          _ => grade,
        };
      case 'heavy': // きびしめ
        return switch (grade) {
          0 => 0,
          1 => 0,
          2 => 1,
          3 => 2,
          _ => grade,
        };
      default: // standard
        return grade;
    }
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    _quizSize = await SettingsService.loadQuizSize() ?? 10;

    _prioritizeWrong = await SettingsService.loadPrioritizeWrong();

    final mm = await SettingsService.loadQuizMode();
    _mode = switch (mm) {
      'kanjiToMeaning' => QuizMode.kanjiToMeaning,
      'kanjiToReading' => QuizMode.kanjiToReading,
      _ => QuizMode.meaningToKanji,
    };
    _timerEnabled = await SettingsService.loadTimerEnabled();
    _timerSeconds = await SettingsService.loadTimerSeconds();
    final weighted = await SettingsService.loadWeightedEnabled();
    _srsPreset = await SettingsService.loadSrsPreset(); // 追加

    if (widget.presetCards != null && widget.presetCards!.isNotEmpty) {
      _cards = List<Kanji>.from(widget.presetCards!);
    } else {
      final sess = await SessionService.load();
      if (sess != null &&
          sess.deck == widget.deck &&
          sess.srsMode == widget.srsMode) {
        final all = await ApiService.fetchKanjiByDeck(widget.deck);
        final by = {for (final k in all) k.kanji: k};
        _cards = sess.kanjiList
            .map((key) => by[key])
            .whereType<Kanji>()
            .toList();
        _index = sess.index.clamp(0, _cards.length - 1);
        _correct = sess.correct.clamp(0, _cards.length);
      } else {
        final all = await ApiService.fetchKanjiByDeck(widget.deck);
        if (widget.srsMode) {
          final dueKeys = await SrsService.dueKeysFromDeck(
            all.map((k) => k.kanji),
            limit: _quizSize,
          );
          _cards = all.where((k) => dueKeys.contains(k.kanji)).toList();
          if (weighted) {
            final srsMap = await SrsService.loadAll();
            final wrongList = await WrongService.listAll();
            final wrongs = {for (final w in wrongList) w.kanji: w.count};
            _cards.sort(
              (a, b) => _weightFor(
                b.kanji,
                srsMap,
                wrongs,
              ).compareTo(_weightFor(a.kanji, srsMap, wrongs)),
            );
          }
        } else {
          if (weighted) {
            final srsMap = await SrsService.loadAll();
            final wrongList = await WrongService.listAll();
            final wrongs = {for (final w in wrongList) w.kanji: w.count};
            _cards = _sampleWeighted(all, _quizSize, srsMap, wrongs);
          } else {
            _cards = all.length > _quizSize ? all.sublist(0, _quizSize) : all;
          }
        }
        _index = 0;
        _correct = 0;
      }
    }

    setState(() {
      _showAnswer = false;
      _loading = false;
    });
    await _saveSession();
    _startTimerForQuestion();
  }

  // ===== 共有ヘルパ =====
  String _readingStr(Kanji k) {
    if ((k.reading ?? '').trim().isNotEmpty) return k.reading!.trim();
    final parts = <String>[];
    if (k.onyomi != null && k.onyomi!.isNotEmpty)
      parts.add(k.onyomi!.join('・'));
    if (k.kunyomi != null && k.kunyomi!.isNotEmpty)
      parts.add(k.kunyomi!.join('・'));
    return parts.isEmpty ? '（読み未登録）' : parts.join(' / ');
  }

  (String prompt, String answer) _qa(Kanji k) {
    switch (_mode) {
      case QuizMode.meaningToKanji:
        return (k.meaning ?? '意味未登録', k.kanji);
      case QuizMode.kanjiToMeaning:
        return (k.kanji, k.meaning ?? '意味未登録');
      case QuizMode.kanjiToReading:
        return (k.kanji, _readingStr(k));
    }
  }

  List<String> _buildOptionsForMode(Kanji correct, List<Kanji> pool) {
    final opts = <String>{};
    switch (_mode) {
      case QuizMode.meaningToKanji:
        opts.add(correct.kanji);
        for (final c in pool) {
          if (opts.length >= 4) break;
          if (c.kanji != correct.kanji) opts.add(c.kanji);
        }
        break;
      case QuizMode.kanjiToMeaning:
        final corr = correct.meaning ?? '意味未登録';
        opts.add(corr);
        for (final c in pool) {
          if (opts.length >= 4) break;
          final m = c.meaning ?? '意味未登録';
          if (m != corr) opts.add(m);
        }
        break;
      case QuizMode.kanjiToReading:
        final corr = _readingStr(correct);
        opts.add(corr);
        for (final c in pool) {
          if (opts.length >= 4) break;
          final r = _readingStr(c);
          if (r != corr) opts.add(r);
        }
        break;
    }
    final list = opts.toList()..shuffle();
    return list;
  }

  Future<void> _advance() async {
    if (_index + 1 < _cards.length) {
      setState(() {
        _index++;
        _showAnswer = false;
      });
      await _saveSession();
      _startTimerForQuestion();
    } else {
      await _clearSession();
      final modeStr = switch (_mode) {
        QuizMode.kanjiToMeaning => 'kanjiToMeaning',
        QuizMode.kanjiToReading => 'kanjiToReading',
        _ => 'meaningToKanji',
      };
      await SessionLogService.add(
        SessionLog(
          at: DateTime.now(),
          deck: widget.deck,
          srsMode: widget.srsMode,
          quizMode: modeStr,
          total: _cards.length,
          correct: _correct,
        ),
      );
      _finishDialog();
    }
  }

  Future<void> _onAnswer(bool isCorrect) async {
    _cancelTimer();
    final current = _cards[_index];

    if (!isCorrect && !widget.srsMode) {
      await WrongService.addWrong(current.kanji);
    }
    if (widget.srsMode) {
      final mapped = _mapGrade(isCorrect ? 2 : 0); // int(0..3)
      await SrsService.applyReview(current.kanji, mapped); // ★ named→位置引数
      if (!isCorrect) await WrongService.addWrong(current.kanji);
    }

    await StatsService.recordQuiz(total: 1, correct: isCorrect ? 1 : 0);
    await GoalService.addSolved(1);
    if (isCorrect) _correct++;
    await _advance();
  }

  Future<void> _applySrsAndNext({required int grade}) async {
    _cancelTimer();
    final current = _cards[_index];
    final mapped = _mapGrade(grade); // int(0..3)
    await SrsService.applyReview(current.kanji, mapped); // ★ named→位置引数
    if (grade == 0) await WrongService.addWrong(current.kanji);

    await StatsService.recordQuiz(total: 1, correct: mapped >= 2 ? 1 : 0);
    await GoalService.addSolved(1);
    if (mapped >= 2) _correct++;
    await _advance();
  }

  Widget _buildTimerBar() {
    if (!_timerEnabled) return const SizedBox.shrink();
    final progress = _remaining <= 0 ? 0.0 : _remaining / _timerSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('残り: $_remaining 秒', style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSrsBody() {
    final k = _cards[_index];
    final qa = _qa(k);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_index + 1}/${_cards.length}',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildTimerBar(),
          Text(qa.$1, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 16),
          if (_showAnswer)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  qa.$2,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAnswer = true),
              icon: const Icon(Icons.visibility),
              label: const Text('答えを表示'),
            ),
          const Spacer(),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _gradeButton('Again', 0, Icons.close),
              _gradeButton('Hard', 1, Icons.flag),
              _gradeButton('Good', 2, Icons.check),
              _gradeButton('Easy', 3, Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gradeButton(String label, int grade, IconData icon) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => _applySrsAndNext(grade: grade),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  void _finishDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.srsMode ? 'SRS復習 完了' : 'クイズ完了'),
        content: Text('正解: $_correct / ${_cards.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
          if (widget.srsMode)
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _clearSession();
                _init();
              },
              child: const Text('続けて復習'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.srsMode ? 'SRS 復習' : 'クイズ'),
          actions: [
            IconButton(
              tooltip: '読み上げ',
              onPressed: null,
              icon: const Icon(Icons.volume_up),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.srsMode ? 'SRS 復習' : 'クイズ')),
        body: const Center(child: Text('カードが見つかりません。')),
      );
    }

    if (widget.srsMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('SRS 復習'),
          actions: [
            IconButton(
              tooltip: '読み上げ',
              onPressed: TtsService.supported
                  ? () {
                      final k = _cards[_index];
                      final qa = _qa(k);
                      TtsService.speak(qa.$1);
                    }
                  : null,
              icon: const Icon(Icons.volume_up),
            ),
          ],
        ),
        body: _buildSrsBody(),
      );
    }

    final k = _cards[_index];
    final qa = _qa(k);
    final options = _buildOptionsForMode(k, _cards);
    final answer = qa.$2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('クイズ'),
        actions: [
          IconButton(
            tooltip: '読み上げ',
            onPressed: TtsService.supported
                ? () {
                    final text = (_mode == QuizMode.kanjiToReading)
                        ? answer
                        : qa.$1.toString();
                    TtsService.speak(text);
                  }
                : null,
            icon: const Icon(Icons.volume_up),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '${_index + 1}/${_cards.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildTimerBar(),
            Text(qa.$1, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final text = options[i];
                  return ElevatedButton(
                    onPressed: () => _onAnswer(text == answer),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(text, textAlign: TextAlign.center),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
