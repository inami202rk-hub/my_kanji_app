// lib/pages/main_quick_start.dart
import 'package:flutter/material.dart';

class QuickStartResult {
  final bool srsMode;
  final int quizSize;
  final String quizMode; // meaningToKanji | kanjiToMeaning | kanjiToReading
  const QuickStartResult({required this.srsMode, required this.quizSize, required this.quizMode});
}

Future<QuickStartResult?> showQuickStartDialog(BuildContext context, {
  required bool initialSrs,
  required int initialSize,
  required String initialMode,
}) {
  bool srs = initialSrs;
  int size = initialSize;
  String mode = initialMode;

  return showDialog<QuickStartResult>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('クイックスタート'),
      content: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('SRS 復習モード'),
              value: srs,
              onChanged: (v) => setState(() => srs = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('出題数'),
                Expanded(
                  child: Slider(
                    value: size.toDouble(),
                    min: 5, max: 30, divisions: 25, label: '$size',
                    onChanged: (v) => setState(() => size = v.toInt()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('出題タイプ'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: mode,
              items: const [
                DropdownMenuItem(value: 'meaningToKanji', child: Text('意味 → 漢字')),
                DropdownMenuItem(value: 'kanjiToMeaning', child: Text('漢字 → 意味')),
                DropdownMenuItem(value: 'kanjiToReading', child: Text('漢字 → 読み')),
              ],
              onChanged: (v) => setState(() => mode = v ?? 'meaningToKanji'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, QuickStartResult(srsMode: srs, quizSize: size, quizMode: mode)),
          child: const Text('開始'),
        ),
      ],
    ),
  );
}
