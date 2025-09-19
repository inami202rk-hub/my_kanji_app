// lib/pages/kanji_detail_page.dart
import 'package:flutter/material.dart';
import '../models/kanji.dart';
import '../services/tts_service.dart';
import '../services/notes_service.dart';
import '../services/tags_service.dart';

class KanjiDetailPage extends StatefulWidget {
  final Kanji kanji;
  const KanjiDetailPage({super.key, required this.kanji});

  @override
  State<KanjiDetailPage> createState() => _KanjiDetailPageState();
}

class _KanjiDetailPageState extends State<KanjiDetailPage> {
  final _noteCtrl = TextEditingController();
  List<String> _tags = [];
  Map<String, int> _tagColors = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final note = await NotesService.loadNote(widget.kanji.kanji) ?? '';
    final tags = await TagsService.loadTags(widget.kanji.kanji);
    final colors = await TagsService.allTagColors();
    setState(() {
      _noteCtrl.text = note;
      _tags = tags;
      _tagColors = colors;
    });
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

  Future<void> _addTagDialog() async {
    final ctrl = TextEditingController();
    final t = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('タグを追加'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'タグ名を入力'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('追加'),
          ),
        ],
      ),
    );
    if (t != null && t.trim().isNotEmpty) {
      await TagsService.addTag(widget.kanji.kanji, t.trim());
      await _load();
    }
  }

  Future<void> _editColorDialog(String tag) async {
    // 簡易カラーパレット（必要ならColorPickerに変更可）
    final preset = <Color>[
      Colors.red,
      Colors.pink,
      Colors.orange,
      Colors.amber,
      Colors.yellow,
      Colors.lime,
      Colors.lightGreen,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.lightBlue,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.black,
    ];
    final selected = await showDialog<Color?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('色を選択: $tag'),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preset
                .map(
                  (c) => GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, Colors.transparent);
            },
            child: const Text('色なし'),
          ),
        ],
      ),
    );
    if (selected == null) return;
    if (selected == Colors.transparent) {
      await TagsService.removeTagColor(tag);
    } else {
      await TagsService.saveTagColor(tag, selected.value);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.kanji;
    final reading = _readingStr(k);
    final meaning = k.meaning ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('詳細：${k.kanji}'),
        actions: [
          IconButton(
            tooltip: '読み上げ（読み）',
            onPressed: TtsService.supported
                ? () => TtsService.speak(reading)
                : null,
            icon: const Icon(Icons.volume_up),
          ),
          IconButton(
            tooltip: '保存',
            onPressed: () async {
              await NotesService.saveNote(k.kanji, _noteCtrl.text);
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('保存しました')));
            },
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Text(k.kanji, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 12),
          ListTile(title: const Text('意味'), subtitle: Text(meaning)),
          ListTile(title: const Text('読み'), subtitle: Text(reading)),
          if ((k.example ?? '').isNotEmpty)
            ListTile(
              title: const Text('例文'),
              subtitle: Text(k.example!),
              trailing: IconButton(
                tooltip: '読み上げ（例文）',
                onPressed: TtsService.supported
                    ? () => TtsService.speak(k.example!)
                    : null,
                icon: const Icon(Icons.volume_up),
              ),
            ),
          const SizedBox(height: 12),
          const Text('メモ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '自由メモ（例：覚え方、由来など）',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('タグ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _addTagDialog,
                icon: const Icon(Icons.add),
                label: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tags.isEmpty
                ? [const Text('（なし）')]
                : _tags.map((t) {
                    final colorValue = _tagColors[t];
                    final bg = (colorValue == null) ? null : Color(colorValue);
                    final fg = (bg == null)
                        ? null
                        : (ThemeData.estimateBrightnessForColor(bg) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87);
                    return InputChip(
                      label: Text(t, style: TextStyle(color: fg)),
                      backgroundColor: bg,
                      onDeleted: () async {
                        await TagsService.removeTag(k.kanji, t);
                        await _load();
                      },
                      onPressed: () => _editColorDialog(t), // タップで色変更
                    );
                  }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
