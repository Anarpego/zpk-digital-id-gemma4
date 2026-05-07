import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../identity_signer.dart';
import '../agent_tool.dart';

/// Firma localmente el contenido del artifact final producido por el loop.
///
/// Toma el hash sha256 del contenido y lo firma con el [IdentitySigner]
/// configurado (HMAC local en tests, Android Keystore en produccion).
class SignPacketTool extends AgentTool {
  SignPacketTool({required this.signer});

  final IdentitySigner signer;

  @override
  String get name => 'sign_packet';
  @override
  String get description =>
      'Firma localmente el hash de un documento. Devuelve hash, firma y key id. Cero red.';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'contenido': {'type': 'string'},
    },
    'required': ['contenido'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final contenido = (input['contenido'] ?? '').toString();
    final hash = 'sha256:${sha256.convert(utf8.encode(contenido)).toString()}';
    final sig = await signer.signCanonical(contenido);

    return ToolResult(
      data: {
        'hash': hash,
        'sig': sig.proofValue,
        'key_id': signer.issuerKeyId,
        'key_store': sig.keyStore,
        'algo': sig.proofSuite,
      },
      summary: 'Firmado con ${signer.issuerKeyId}',
    );
  }
}
