import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Documento concreto que el agent produce al final del loop.
///
/// Es lo que el ciudadano puede leer en voz alta, copiar, compartir o
/// transformar en QR firmado para una ventanilla institucional.
class GeneratedArtifact {
  GeneratedArtifact({
    required this.type,
    required this.titulo,
    required this.contenidoMd,
    required this.camposClave,
    String? sigEd25519,
  }) : hashSha256 = _hashOf(contenidoMd),
       sigEd25519 = sigEd25519 ?? '';

  final String type;
  final String titulo;
  final String contenidoMd;
  final Map<String, String> camposClave;
  final String hashSha256;
  final String sigEd25519;

  GeneratedArtifact copyWith({String? sigEd25519}) {
    return GeneratedArtifact(
      type: type,
      titulo: titulo,
      contenidoMd: contenidoMd,
      camposClave: camposClave,
      sigEd25519: sigEd25519 ?? this.sigEd25519,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'titulo': titulo,
    'contenidoMd': contenidoMd,
    'camposClave': camposClave,
    'hashSha256': hashSha256,
    'sigEd25519': sigEd25519,
  };

  static String _hashOf(String content) {
    return 'sha256:${sha256.convert(utf8.encode(content)).toString()}';
  }
}
