import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// A) pubspec.yaml の name が "my_kanji_app" ならこの import でOK
import 'package:my_kanji_app/pages/settings_page.dart';
// B) 上でエラーになる場合は A をコメントアウトし、相対 import に切替：
// import '../../lib/pages/settings_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// ネットワークを完全に無効化（テストがHttpClientを使っても外に出ないように）
class _NoNetworkOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _NoNetworkClient();
  }
}

class _NoNetworkClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    throw const SocketException('Network disabled in tests');
  }

  // 他メソッドも最低限潰す（必要なら増やす）
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    // SharedPreferences のモック（設定画面が読む想定）
    SharedPreferences.setMockInitialValues({});
    // ネット切断
    HttpOverrides.global = _NoNetworkOverrides();
  });

  testWidgets('SettingsPage renders SRS preview (by Key or header text)', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: SettingsPage()));

    // 非同期初期化があっても待てるように、最大3秒程度待つ
    // pumpAndSettle は条件次第で終わらないことがあるので、段階的に待つ
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    final byKey = find.byKey(const Key('srsPreviewSection'));
    // 見出しテキストが日本語/英語のどちらでも拾えるように
    final byJp = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'SRSプレビュー',
    );
    final byEn = find.byWidgetPredicate(
      (w) => w is Text && w.data == 'SRS Tuning Preview',
    );

    final found =
        byKey.evaluate().isNotEmpty ||
        byJp.evaluate().isNotEmpty ||
        byEn.evaluate().isNotEmpty;

    expect(
      found,
      true,
      reason:
          'SRS preview section not found. Ensure settings_page.dart puts Key("srsPreviewSection") just before the SRS preview header, or the header text equals "SRSプレビュー" / "SRS Tuning Preview".',
    );
  });
}
