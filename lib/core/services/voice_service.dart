import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Распознавание речи на русском.
class VoiceService {
  VoiceService._();

  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _initialized = false;

  static Future<bool> init() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onStatus: (_) {},
        onError: (_) {},
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  static bool get isAvailable => _initialized;
  static bool get isListening => _speech.isListening;

  static Future<void> startListening({
    required Function(String partial, bool finalResult) onResult,
    String localeId = 'ru_RU',
  }) async {
    if (!_initialized) {
      final ok = await init();
      if (!ok) throw StateError('Распознавание недоступно на этом устройстве');
    }
    await _speech.listen(
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
    );
  }

  static Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  static Future<void> cancel() async {
    await _speech.cancel();
  }
}
