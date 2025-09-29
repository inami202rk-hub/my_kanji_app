import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// A) pubspec.yaml の name が "my_kanji_app" ならこれでOK
import 'package:my_kanji_app/pages/settings_page.dart';
// B) Aでコケたら相対 import に切替：
// import '../../lib/pages/settings_page.dart';

void main() {
  testWidgets('SettingsPage renders SRS preview section (by Key)', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('srsPreviewSection')), findsOneWidget);
  });
}
