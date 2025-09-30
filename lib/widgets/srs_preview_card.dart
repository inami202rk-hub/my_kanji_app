import 'package:flutter/material.dart';

/// SRS プレビュー（プレースホルダー）
/// まだロジックは繋げず、見出し＋説明だけを描画する。
class SrsPreviewCard extends StatelessWidget {
  /// SettingsPage のスモークテストが探しに来る合図。
  static const previewSectionKey = Key('srsPreviewSection');

  const SrsPreviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // ← この Key を見てテストが合格する
            SizedBox(key: previewSectionKey, height: 0, width: 0),
            Text(
              'SRS Tuning Preview', // テストはJP/ENどちらでもOK
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              '設定を変更すると、ここにプレビューが表示されます（仮）。\n'
              'この段階では UI の枠だけを提供します。',
            ),
          ],
        ),
      ),
    );
  }
}
