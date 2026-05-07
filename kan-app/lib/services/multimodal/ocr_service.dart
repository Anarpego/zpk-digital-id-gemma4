import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wrapper sobre Google ML Kit text recognition para extraer texto de
/// fotos (SMS, recibos, citatorios) sin enviar la imagen a ningun servidor.
class OcrService {
  OcrService({TextRecognizer? recognizer})
    : _recognizer =
          recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  /// Extrae texto de una imagen en disco. La imagen NO se sube a ningun
  /// lado; el modelo ML Kit corre en-device.
  Future<OcrResult> recognize(File image) async {
    final input = InputImage.fromFile(image);
    final RecognizedText recognized = await _recognizer.processImage(input);
    return OcrResult(
      text: recognized.text,
      blocks: recognized.blocks
          .map((b) => OcrBlock(text: b.text, confidence: 1.0))
          .toList(growable: false),
    );
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

class OcrResult {
  const OcrResult({required this.text, required this.blocks});
  final String text;
  final List<OcrBlock> blocks;
}

class OcrBlock {
  const OcrBlock({required this.text, required this.confidence});
  final String text;
  final double confidence;
}
