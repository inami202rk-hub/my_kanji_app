// lib/services/tts_service.dart
import 'tts_platform_stub.dart' if (dart.library.html) 'tts_platform_web.dart';

class TtsService {
  static bool get supported => ttsSupported;
  static Future<void> speak(String text) => ttsSpeak(text);
}
