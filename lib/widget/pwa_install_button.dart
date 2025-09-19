// lib/widget/pwa_install_button.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html; // Web専用
import 'dart:js_util' as js_util; // 標準：JS呼び出し（Promise/プロパティ）

class PwaInstallButton extends StatefulWidget {
  final ButtonStyle? style;
  const PwaInstallButton({super.key, this.style});

  @override
  State<PwaInstallButton> createState() => _PwaInstallButtonState();
}

class _PwaInstallButtonState extends State<PwaInstallButton> {
  dynamic _deferred; // beforeinstallprompt の Event（型はないので dynamic）
  bool _installed = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    // インストール済みになったら非表示
    html.window.addEventListener('appinstalled', (_) {
      if (mounted) setState(() => _installed = true);
    });

    // beforeinstallprompt を保持（ユーザー操作で出す）
    html.window.addEventListener('beforeinstallprompt', (event) {
      try {
        (event as html.Event).preventDefault();
      } catch (_) {}
      _deferred = event; // dynamic で保持
      if (mounted) setState(() {}); // ボタン表示
    });
  }

  Future<void> _install() async {
    final ev = _deferred;
    if (ev == null) return;
    try {
      // prompt() を呼ぶ
      js_util.callMethod(ev, 'prompt', const []);
      // userChoice(Promise) を待つ
      final choice = await js_util.promiseToFuture(
        js_util.getProperty(ev, 'userChoice'),
      );
      final outcome = (js_util.getProperty(choice, 'outcome') as String?) ?? '';
      if (outcome == 'accepted') {
        if (mounted) {
          setState(() {
            _installed = true;
            _deferred = null;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('インストールが開始されました')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('インストールはキャンセルされました')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('インストールに失敗しました: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web以外 / 既にインストール / まだプロンプト不可 の場合は非表示
    if (!kIsWeb || _installed || _deferred == null) {
      return const SizedBox.shrink();
    }
    return ElevatedButton.icon(
      onPressed: _install,
      style: widget.style,
      icon: const Icon(Icons.download),
      label: const Text('インストール'),
    );
  }
}
