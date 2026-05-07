import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Wrapper minimo sobre speech_to_text. Toda la logica vive on-device cuando
/// el dispositivo lo soporta; si no, [start] falla con [SttUnavailable].
class SttService {
  SttService({stt.SpeechToText? engine})
    : _engine = engine ?? stt.SpeechToText();

  final stt.SpeechToText _engine;
  bool _initialized = false;
  String _localeId = 'es_GT';

  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    final ok = await _engine.initialize(onError: (_) {}, onStatus: (_) {});
    _initialized = ok;
    if (ok) {
      // Buscar es_GT si existe, sino fallback es_MX, sino primer es_*.
      final locales = await _engine.locales();
      final preferred = locales.firstWhere(
        (l) => l.localeId == 'es_GT',
        orElse: () => locales.firstWhere(
          (l) => l.localeId == 'es_MX',
          orElse: () => locales.firstWhere(
            (l) => l.localeId.startsWith('es'),
            orElse: () => locales.isEmpty
                ? stt.LocaleName(_localeId, 'es-GT')
                : locales.first,
          ),
        ),
      );
      _localeId = preferred.localeId;
    }
    return ok;
  }

  bool get isListening => _engine.isListening;

  Future<void> startListening({required void Function(String) onResult}) async {
    if (!_initialized) {
      throw SttUnavailable('STT not initialized; call ensureInitialized first');
    }
    await _engine.listen(
      localeId: _localeId,
      onResult: (r) => onResult(r.recognizedWords),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_engine.isListening) {
      await _engine.stop();
    }
  }

  Future<void> cancel() async {
    if (_engine.isListening) {
      await _engine.cancel();
    }
  }
}

class SttUnavailable implements Exception {
  SttUnavailable(this.message);
  final String message;
  @override
  String toString() => 'SttUnavailable: $message';
}
