import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// あなたのパスに合わせて必要なら修正（例: lib/pages/settings_page.dart）
import 'package:my_kanji_app/pages/settings_page.dart';

void main() {
  testWidgets('Settings page shows SRS preview section', (tester) async {
    // const を付けるとコンストラクタが const でない時に落ちるので付けない
    await tester.pumpWidget(MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    // 英語 or 日本語ラベルのどちらかが出ていればOKにする
    final en = find.text('SRS Tuning Preview');
    final jp = find.text('SRSプレビュー');

    final found = en.evaluate().isNotEmpty || jp.evaluate().isNotEmpty;
    expect(found, true, reason: 'Expected SRS preview section to be visible on SettingsPage');
  });
}
