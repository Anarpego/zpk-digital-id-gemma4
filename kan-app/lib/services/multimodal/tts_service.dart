import 'package:flutter_tts/flutter_tts.dart';

/// Wrapper sobre flutter_tts para leer en voz alta los artifacts y los
/// pasos del agente.
class TtsService {
  TtsService({FlutterTts? engine}) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    await _engine.setLanguage('es-GT').catchError((_) async {
      await _engine.setLanguage('es-MX').catchError((_) async {
        await _engine.setLanguage('es-ES');
      });
    });
    await _engine.setSpeechRate(0.5);
    await _engine.setVolume(1.0);
    await _engine.setPitch(1.0);
    await _engine.awaitSpeakCompletion(true);
    _configured = true;
  }

  Future<void> speak(String text) async {
    await _configure();
    await _engine.stop();
    await _engine.speak(text);
  }

  Future<void> stop() async {
    await _engine.stop();
  }
}
