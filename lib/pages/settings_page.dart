// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/api_service.dart';
import '../services/backup_service.dart';
import '../services/restore_service.dart';
import 'package:flutter/services.dart';
import '../models/srs_config.dart';
import '../services/srs_config_store.dart';
import '../services/srs_service.dart';
import '../widget/pwa_install_button.dart';
import '../widgets/srs_preview_card.dart';
import '../utils/debounce.dart';
import '../features/settings/services/settings_service.dart'
    as feature_settings;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SrsConfigStore _srsConfigStore = SharedPrefsSrsConfigStore();
  late final feature_settings.SettingsService _settings;
  String? _deck;
  int _quizSize = 10;
  String _quizMode = 'meaningToKanji';
  int _srsDailyCap = SrsConfig.defaults.dailyCap;
  int _srsMaxNew = SrsConfig.defaults.maxNew;
  int _srsMaxLearn = SrsConfig.defaults.maxLearn;
  SrsStrategy _srsStrategy = SrsConfig.defaults.strategy;

  bool _timerEnabled = false;
  int _timerSeconds = 15;

  bool _weighted = true;
  bool _prioritizeWrong = SrsConfig.defaults.prioritizeWrong;
  bool _backupBusy = false;
  bool _restoreBusy = false;

  String _browseSort = 'kanji';
  String _browseSrsFilter = 'all';
  bool _browseFavOnly = false;

  int _dailyGoal = 20;
  int _weeklyGoal = 100;

  late final Debouncer _previewDebouncer = Debouncer(milliseconds: 400);
  Duration _previewAgain = const Duration(minutes: 1);
  Duration _previewGood = const Duration(minutes: 10);
  Duration _previewEasy = const Duration(days: 1);

  String _srsPreset = 'standard'; // light | standard | heavy

  bool _loading = true;
  List<String> _levels = [];

  @override
  void initState() {
    super.initState();
    _settings = feature_settings.SettingsService.instance;
    _settings.load(); // 非同期ロード（ValueNotifier を更新）
    _load();
  }

  SrsConfig _currentSrsConfig() {
    return SrsConfig(
      maxNew: _srsMaxNew.clamp(0, 500),
      maxLearn: _srsMaxLearn.clamp(0, 500),
      dailyCap: _srsDailyCap.clamp(0, 1000),
      prioritizeWrong: _prioritizeWrong,
      strategy: _srsStrategy,
    );
  }

  Future<void> _saveSrsConfig() async {
    await _srsConfigStore.save(_currentSrsConfig());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final levels = await ApiService.fetchLevels();
      final deck = await SettingsService.loadDeck();
      final size = await SettingsService.loadQuizSize();
      final mode = await SettingsService.loadQuizMode();

      final ten = await SettingsService.loadTimerEnabled();
      final tsecs = await SettingsService.loadTimerSeconds();

      final weighted = await SettingsService.loadWeightedEnabled();

      final bsort = await SettingsService.loadBrowseSort();
      final bfilter = await SettingsService.loadBrowseSrsFilter();
      final bfav = await SettingsService.loadBrowseFavoritesOnly();

      final dGoal = await SettingsService.loadDailyGoal();
      final wGoal = await SettingsService.loadWeeklyGoal();

      final preset = await SettingsService.loadSrsPreset();
      final srsConfig = await _srsConfigStore.load();
      setState(() {
        _levels = levels;
        _deck = deck ?? (levels.isNotEmpty ? levels.first : null);
        _quizSize = size ?? 10;
        _quizMode = mode ?? 'meaningToKanji';
        _srsMaxNew = srsConfig.maxNew;
        _srsMaxLearn = srsConfig.maxLearn;
        _srsDailyCap = srsConfig.dailyCap;
        _srsStrategy = srsConfig.strategy;
        _timerEnabled = ten;
        _timerSeconds = tsecs;

        _weighted = weighted;
        _prioritizeWrong = srsConfig.prioritizeWrong;

        _browseSort = bsort;
        _browseSrsFilter = bfilter;
        _browseFavOnly = bfav;

        _dailyGoal = dGoal;
        _weeklyGoal = wGoal;

        _srsPreset = preset;

        _loading = false;
      });
      if (mounted) {
        _schedulePreviewUpdate(immediate: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _previewAgain = const Duration(minutes: 1);
        _previewGood = const Duration(minutes: 10);
        _previewEasy = const Duration(days: 1);
      });
    }
  }

  @override
  void dispose() {
    _previewDebouncer.dispose();
    super.dispose();
  }

  void _schedulePreviewUpdate({bool immediate = false}) {
    void run() {
      try {
        final result = SrsService.simulatePreview(
          SrsPreviewDurationsInput(config: _currentSrsConfig()),
        );
        if (!mounted) return;
        setState(() {
          _previewAgain = result.again;
          _previewGood = result.good;
          _previewEasy = result.easy;
        });
      } catch (_) {
        // Leave previous preview values untouched on failure
      }
    }

    if (immediate) {
      run();
    } else {
      _previewDebouncer.run(run);
    }
  }

  void _updateAndPreview(VoidCallback mutate) {
    setState(mutate);
    _schedulePreviewUpdate();
  }

  Future<void> _copySrsBackup() async {
    if (_backupBusy) return;
    setState(() => _backupBusy = true);
    try {
      final json = await const BackupService().exportJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('バックアップをコピーしました')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('バックアップに失敗: $e')));
    } finally {
      if (mounted) {
        setState(() => _backupBusy = false);
      }
    }
  }

  Future<void> _showRestoreDialog() async {
    if (_restoreBusy) return;
    final controller = TextEditingController();
    String? errorText;
    bool validated = false;
    bool validating = false;
    bool dialogRestoreBusy = false;

    final service = const RestoreService();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> handleValidate() async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                setDialogState(() {
                  errorText = 'JSONを入力してください';
                  validated = false;
                });
                return;
              }
              setDialogState(() {
                validating = true;
                errorText = null;
              });
              try {
                service.validate(text);
                setDialogState(() {
                  validated = true;
                });
              } catch (e) {
                setDialogState(() {
                  errorText = e.toString();
                  validated = false;
                });
              } finally {
                setDialogState(() {
                  validating = false;
                });
              }
            }

            Future<void> handleRestore() async {
              final text = controller.text.trim();
              if (text.isEmpty) {
                setDialogState(() {
                  errorText = 'JSONを入力してください';
                  validated = false;
                });
                return;
              }
              setDialogState(() {
                dialogRestoreBusy = true;
                errorText = null;
              });
              if (mounted) {
                setState(() => _restoreBusy = true);
              }
              var shouldClose = false;
              try {
                await service.importJson(text);
                shouldClose = true;
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('復元が完了しました')));
              } catch (e) {
                if (!mounted) return;
                setDialogState(() {
                  dialogRestoreBusy = false;
                  errorText = e.toString();
                  validated = false;
                });
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('復元に失敗: $e')));
              } finally {
                if (mounted) {
                  setState(() => _restoreBusy = false);
                }
                if (!shouldClose) {
                  setDialogState(() {
                    dialogRestoreBusy = false;
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('バックアップから復元'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 12,
                      decoration: InputDecoration(
                        hintText: 'バックアップJSONを貼り付けてください',
                        errorText: errorText,
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          validated = false;
                          errorText = null;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '「検証」でフォーマットを確認してから「復元する」を押してください。',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogRestoreBusy
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('閉じる'),
                ),
                TextButton(
                  onPressed: (validating || dialogRestoreBusy)
                      ? null
                      : handleValidate,
                  child: validating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('検証'),
                ),
                TextButton(
                  onPressed: (!validated || dialogRestoreBusy)
                      ? null
                      : handleRestore,
                  child: dialogRestoreBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('復元する'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _save() async {
    if (_deck != null) await SettingsService.saveDeck(_deck!);
    await _saveSrsConfig();

    await SettingsService.saveQuizSize(_quizSize);
    await SettingsService.saveQuizMode(_quizMode);

    await SettingsService.saveTimerEnabled(_timerEnabled);
    await SettingsService.saveTimerSeconds(_timerSeconds);

    await SettingsService.saveWeightedEnabled(_weighted);

    await SettingsService.saveBrowseSort(_browseSort);
    await SettingsService.saveBrowseSrsFilter(_browseSrsFilter);
    await SettingsService.saveBrowseFavoritesOnly(_browseFavOnly);

    await SettingsService.saveDailyGoal(_dailyGoal);
    await SettingsService.saveWeeklyGoal(_weeklyGoal);

    await SettingsService.saveSrsPreset(_srsPreset);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: _settings.srsPreviewEnabled,
                builder: (context, enabled, _) {
                  if (!enabled) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SrsPreviewCard(
                      again: _previewAgain,
                      good: _previewGood,
                      easy: _previewEasy,
                    ),
                  );
                },
              ),
              const Text(
                '設定',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // SRS Preview Toggle
              ValueListenableBuilder<bool>(
                valueListenable: _settings.srsPreviewEnabled,
                builder: (context, enabled, _) {
                  return SwitchListTile(
                    title: const Text('SRS Preview'),
                    subtitle: const Text(
                      'Show a preview card for the spaced repetition schedule',
                    ),
                    value: enabled,
                    onChanged: (v) => _settings.setSrsPreviewEnabled(v),
                  );
                },
              ),
              const SizedBox(height: 20),

              // デッキ
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('デッキ（N5/N4/N3）')),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _deck,
                      items: _levels
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _deck = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 出題数
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('クイズ出題数')),
                  Expanded(
                    child: Slider(
                      value: _quizSize.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_quizSize',
                      onChanged: (v) => setState(() => _quizSize = v.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 出題タイプ
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('出題タイプ')),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _quizMode,
                      items: const [
                        DropdownMenuItem(
                          value: 'meaningToKanji',
                          child: Text('意味 → 漢字'),
                        ),
                        DropdownMenuItem(
                          value: 'kanjiToMeaning',
                          child: Text('漢字 → 意味'),
                        ),
                        DropdownMenuItem(
                          value: 'kanjiToReading',
                          child: Text('漢字 → 読み'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _quizMode = v ?? 'meaningToKanji'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // タイマー
              const Text(
                'タイマー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('タイマーを有効にする'),
                value: _timerEnabled,
                onChanged: (v) => setState(() => _timerEnabled = v),
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('制限時間（秒）')),
                  Expanded(
                    child: Slider(
                      value: _timerSeconds.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 55,
                      label: '$_timerSeconds 秒',
                      onChanged: _timerEnabled
                          ? (v) => setState(() => _timerSeconds = v.toInt())
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // 出題の重み付け
              const Text(
                '出題の重み付け',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('ミス・超過・学習中を優先'),
                value: _weighted,
                onChanged: (v) => setState(() => _weighted = v),
              ),

              // ★ 新セクション：詳細チューニング
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '出題の重み付け（詳細）',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('間違いノートを強く優先する'),
                subtitle: const Text('通常の重み付けに加え、Wrong記録のあるカードをさらに優先'),
                value: _prioritizeWrong,
                onChanged: (v) {
                  setState(() => _prioritizeWrong = v);
                  _saveSrsConfig();
                },
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // 一覧の既定
              const Text(
                '一覧の既定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('並び順')),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _browseSort,
                      items: const [
                        DropdownMenuItem(value: 'kanji', child: Text('漢字順')),
                        DropdownMenuItem(value: 'meaning', child: Text('意味順')),
                        DropdownMenuItem(
                          value: 'dueAsc',
                          child: Text('期日（早い順）'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _browseSort = v ?? 'kanji'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('SRSフィルタ')),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _browseSrsFilter,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('すべて')),
                        DropdownMenuItem(value: 'newOnly', child: Text('新規')),
                        DropdownMenuItem(value: 'learning', child: Text('学習')),
                        DropdownMenuItem(value: 'mature', child: Text('成熟')),
                      ],
                      onChanged: (v) =>
                          setState(() => _browseSrsFilter = v ?? 'all'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('お気に入りのみ'),
                value: _browseFavOnly,
                onChanged: (v) => setState(() => _browseFavOnly = v),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // 学習目標
              const Text(
                '学習目標',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('デイリー')),
                  Expanded(
                    child: Slider(
                      value: _dailyGoal.toDouble(),
                      min: 5,
                      max: 200,
                      divisions: 195,
                      label: '$_dailyGoal',
                      onChanged: (v) => setState(() => _dailyGoal = v.toInt()),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 120, child: Text('ウィークリー')),
                  Expanded(
                    child: Slider(
                      value: _weeklyGoal.toDouble(),
                      min: 20,
                      max: 1000,
                      divisions: 98,
                      label: '$_weeklyGoal',
                      onChanged: (v) => setState(() => _weeklyGoal = v.toInt()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'SRS復習 選定設定',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  const SizedBox(width: 140, child: Text('1回あたりの上限')),
                  Expanded(
                    child: Slider(
                      value: _srsDailyCap.toDouble(),
                      min: 5,
                      max: 200,
                      divisions: 195,
                      label: '$_srsDailyCap 件',
                      onChanged: (v) =>
                          _updateAndPreview(() => _srsDailyCap = v.toInt()),
                      onChangeEnd: (_) => _saveSrsConfig(),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 140, child: Text('シャッフル方式')),
                  Expanded(
                    child: DropdownButtonFormField<SrsStrategy>(
                      value: _srsStrategy,
                      items: const [
                        DropdownMenuItem(
                          value: SrsStrategy.balanced,
                          child: Text('バランス（推奨）'),
                        ),
                        DropdownMenuItem(
                          value: SrsStrategy.front,
                          child: Text('フロント（期日順）'),
                        ),
                        DropdownMenuItem(
                          value: SrsStrategy.shuffle,
                          child: Text('シャッフル'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        _updateAndPreview(() => _srsStrategy = v);
                        _saveSrsConfig();
                      },
                    ),
                  ),
                ],
              ),

              Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SRS：1日の上限',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 130, child: Text('新規カード上限')),
                          Expanded(
                            child: Slider(
                              value: _srsMaxNew.toDouble(),
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '$_srsMaxNew 件',
                              onChanged: (v) => _updateAndPreview(
                                () => _srsMaxNew = v.toInt(),
                              ),
                              onChangeEnd: (_) => _saveSrsConfig(),
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text(
                              '$_srsMaxNew',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const SizedBox(width: 130, child: Text('学習中カード上限')),
                          Expanded(
                            child: Slider(
                              value: _srsMaxLearn.toDouble(),
                              min: 0,
                              max: 200,
                              divisions: 200,
                              label: '$_srsMaxLearn 件',
                              onChanged: (v) => _updateAndPreview(
                                () => _srsMaxLearn = v.toInt(),
                              ),
                              onChangeEnd: (_) => _saveSrsConfig(),
                            ),
                          ),
                          SizedBox(
                            width: 56,
                            child: Text(
                              '$_srsMaxLearn',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '※「新規」は interval==0 のカード、「学習中」は reps>0 かつ interval<21 のカードを指します。',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text(
                    '\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3092\u30b3\u30d4\u30fc',
                  ),
                  subtitle: const Text(
                    'SRS\u9032\u632f\u3068\u8a2d\u5b9a\u3092JSON\u3067\u30af\u30ea\u30c3\u30d7\u30dc\u30fc\u30c9\u306b\u30b3\u30d4\u30fc\u3057\u307e\u3059',
                  ),
                  onTap: _backupBusy ? null : _copySrsBackup,
                  enabled: !_backupBusy,
                  trailing: _backupBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.content_copy),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text(
                    '\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u304b\u3089\u5fa9\u5143',
                  ),
                  subtitle: const Text(
                    '\u30d0\u30c3\u30af\u30a2\u30c3\u30d7JSON\u3092\u8cbc\u308a\u4ed8\u3051\u3001\u691c\u8a3c\u2192\u5fa9\u5143\u306e\u9806\u306b\u5b9f\u884c\u3057\u307e\u3059\u3002',
                  ),
                  onTap: _restoreBusy ? null : _showRestoreDialog,
                  enabled: !_restoreBusy,
                  trailing: _restoreBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_download),
                ),
              ),

              const PwaInstallButton(), // ← この1行追加
              // SRSプリセット
              const Text(
                'SRSプリセット',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                value: _srsPreset,
                items: const [
                  DropdownMenuItem(value: 'light', child: Text('Light（やさしめ）')),
                  DropdownMenuItem(
                    value: 'standard',
                    child: Text('Standard（標準）'),
                  ),
                  DropdownMenuItem(value: 'heavy', child: Text('Heavy（きびしめ）')),
                ],
                onChanged: (v) => setState(() => _srsPreset = v ?? 'standard'),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),

              // バックアップ
              const Text(
                'バックアップ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('すべてをクリップボードへ'),
                      onPressed: () async {
                        final json = await BackupService.exportAll();
                        await BackupService.copyToClipboard(json);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('エクスポートJSONをコピーしました')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.paste),
                      label: const Text('クリップボードから復元'),
                      onPressed: () async {
                        final text = await BackupService.pasteFromClipboard();
                        if (text == null || text.trim().isEmpty) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('テキストがありません')),
                          );
                          return;
                        }
                        await BackupService.importAll(text);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('復元しました（再起動推奨）')),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // === SRS PREVIEW (placeholder) ==============================================

              // ===========================================================================
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('保存して戻る'),
                ),
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: body,
    );
  }
}
