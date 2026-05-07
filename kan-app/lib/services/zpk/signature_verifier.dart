import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'packet_envelope.dart';

/// Resultado de verificar un packet recibido por la ventanilla (o por el
/// ciudadano cuando recibe un acuse de vuelta).
class VerifyResult {
  const VerifyResult({
    required this.signatureValid,
    required this.algoSupported,
    required this.findings,
  });

  final bool signatureValid;
  final bool algoSupported;
  final List<String> findings;

  bool get isValid => signatureValid && algoSupported && findings.isEmpty;
}

/// Provee la clave compartida (HMAC) para un keyId dado. En la app:
/// - Modo Ciudadano conoce su propia clave (escribe firmas).
/// - Modo Ventanilla carga claves del piloto desde la trust list local.
abstract class KeyResolver {
  String? secretFor(String keyId);
}

class StaticKeyResolver implements KeyResolver {
  StaticKeyResolver(this.keys);
  final Map<String, String> keys;
  @override
  String? secretFor(String keyId) => keys[keyId];
}

/// Verificador HMAC-SHA256 sobre la forma canonica del packet sin `sig`.
///
/// Honesto: HMAC es simetrico. La ventanilla y el ciudadano comparten la
/// misma clave por keyId. Esto sirve para el piloto offline verificable; para
/// produccion nacional debe migrarse a firmas asimetricas/certificados.
class HmacSignatureVerifier {
  const HmacSignatureVerifier({required this.keyResolver});

  final KeyResolver keyResolver;

  VerifyResult verify(PacketEnvelope packet) {
    final findings = <String>[];

    if (packet.sigAlgo != 'HmacSha256Signature2026') {
      return VerifyResult(
        signatureValid: false,
        algoSupported: false,
        findings: ['unsupported_sig_algo:${packet.sigAlgo}'],
      );
    }

    if (packet.sig.isEmpty) {
      findings.add('missing_signature');
      return VerifyResult(
        signatureValid: false,
        algoSupported: true,
        findings: findings,
      );
    }

    final secret = keyResolver.secretFor(packet.issuer.keyId);
    if (secret == null) {
      findings.add('unknown_issuer_key:${packet.issuer.keyId}');
      return VerifyResult(
        signatureValid: false,
        algoSupported: true,
        findings: findings,
      );
    }

    final canonical = packet.canonicalForSigning();
    final hmac = Hmac(sha256, utf8.encode(secret));
    final expected = hmac.convert(utf8.encode(canonical)).toString();

    if (!_constantTimeEquals(expected, packet.sig)) {
      findings.add('signature_mismatch');
    }

    if (packet.policy?.expiresAt != null &&
        DateTime.now().isAfter(packet.policy!.expiresAt!)) {
      findings.add('packet_expired');
    }

    return VerifyResult(
      signatureValid: findings.isEmpty,
      algoSupported: true,
      findings: findings,
    );
  }

  /// Firma reproducible para un secret dado. Util para que el lado emisor
  /// produzca packets que despues la ventanilla pueda verificar.
  static String signWithSecret({
    required PacketEnvelope packet,
    required String secret,
  }) {
    final canonical = packet.canonicalForSigning();
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(canonical)).toString();
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
