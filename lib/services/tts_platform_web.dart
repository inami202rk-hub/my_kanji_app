// lib/services/tts_platform_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

final bool ttsSupported = true;

Future<void> ttsSpeak(String text) async {
  final s = text.trim();
  if (s.isEmpty) return;
  final synth = html.window.speechSynthesis;
  if (synth == null) return;
  final u = html.SpeechSynthesisUtterance(s)..lang = 'ja-JP';
  synth.cancel();
  synth.speak(u);
}
