import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_kanji_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    final body = switch (uri.path) {
      final path when path.endsWith('/levels') => jsonEncode(['N5', 'N4']),
      _ => jsonEncode(<String, dynamic>{}),
    };
    final bytes = utf8.encode(body);
    final stream = Stream<List<int>>.value(bytes);
    final statusCode = uri.path.endsWith('/levels') ? 200 : 404;
    return http.StreamedResponse(
      stream,
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boots and renders root widget', (tester) async {
    SharedPreferences.setMockInitialValues(const {});

    await http.runWithClient(() async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(MaterialApp), findsAtLeastNWidgets(1));
      expect(find.text('Kanji Study'), findsWidgets);
    }, _FakeHttpClient.new);
  });
}
