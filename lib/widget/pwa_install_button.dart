// lib/widgets/pwa_install_button.dart
// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html;                // Web専用
import 'package:js/js_util.dart' as jsutil; // JSのPromise/メソッド呼び出し

/// Webでのみ表示される「アプリをインストール」ボタン。
/// - beforeinstallprompt をフックして手動でプロンプトを出す
/// - すでにインストール済み or 非Webでは非表示
class PwaInstallButton extends StatefulWidget {
  final ButtonStyle? style;
  const PwaInstallButton({super.key, this.style});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  dynamic _deferred; // beforeinstallprompt のイベントを保持（型は dynamic で扱う）
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    // インストール完了イベント
    html.window.addEventListener('appinstalled', (event) {
      if (mounted) setState(() => _installed = true);
    });

    // beforeinstallprompt を横取りして保存
    html.window.addEventListener('beforeinstallprompt', (event) {
      // 既定のミニバー表示を止める
      (event as html.Event).preventDefault();
      _deferred = event; // dynamic で保持
      if (mounted) setState(() {}); // ボタンを表示
    });
  }

  Future<void> _install() async {
    final ev = _deferred;
    if (ev == null) return;

    try {
      // prompt() を呼ぶ（JSメソッド呼び出し）
      await jsutil.promiseToFuture(jsutil.callMethod(ev, 'prompt', const []));

      // userChoice を待つ（Promise）
      final choice = await jsutil.promiseToFuture(jsutil.getProperty(ev, 'userChoice'));
      final outcome = (jsutil.getProperty(choice, 'outcome') as String?) ?? '';

      if (outcome == 'accepted') {
        if (mounted) {
          setState(() {
            _installed = true;
            _deferred = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('インストールが開始されました')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('インストールはキャンセルされました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('インストールに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web以外では何も表示しない
    if (!kIsWeb) return const SizedBox.shrink();

    // すでにインストール済み、またはプロンプト不可なら非表示
    if (_installed || _deferred == null) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: _install,
      style: widget.style,
      icon: const Icon(Icons.download),
      label: const Text('インストール'),
    );
  }
}
