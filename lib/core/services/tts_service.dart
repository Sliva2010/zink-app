import 'package:flutter_tts/flutter_tts.dart';

/// Сервис озвучивания ответов ИИ.
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static bool _isSpeaking = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('ru-RU');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((_) => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  static bool get isSpeaking => _isSpeaking;

  static Future<void> speak(String text) async {
    if (!_initialized) await init();
    if (_isSpeaking) await stop();
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}
