import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/zpk/packet_codec.dart';
import 'package:kan_app/services/zpk/packet_envelope.dart';
import 'package:kan_app/services/zpk/signature_verifier.dart';

PacketEnvelope _baseUnsigned() => PacketEnvelope(
  type: PacketType.intake,
  caseCode: 'igss_sin_dpi',
  issuedAt: DateTime.fromMillisecondsSinceEpoch(1714742400 * 1000),
  issuer: const PacketIssuer(
    kind: PacketIssuerKind.citizen,
    pseudo: 'zpk:test',
    keyId: 'citizen-key-A',
  ),
  fields: const {'nombre_pila': 'Ana'},
);

void main() {
  const secretA = 'secret-A-very-strong';
  const secretB = 'secret-B-also-strong';
  final resolver = StaticKeyResolver({'citizen-key-A': secretA});
  final verifier = HmacSignatureVerifier(keyResolver: resolver);

  test('verifica firma valida producida con la misma clave', () {
    final unsigned = _baseUnsigned();
    final sig = HmacSignatureVerifier.signWithSecret(
      packet: unsigned,
      secret: secretA,
    );
    final signed = unsigned.withSig(sig);

    final result = verifier.verify(signed);
    expect(result.signatureValid, isTrue);
    expect(result.algoSupported, isTrue);
    expect(result.findings, isEmpty);
    expect(result.isValid, isTrue);
  });

  test('rechaza firma producida con otra clave', () {
    final unsigned = _baseUnsigned();
    final sig = HmacSignatureVerifier.signWithSecret(
      packet: unsigned,
      secret: secretB,
    );
    final signed = unsigned.withSig(sig);

    final result = verifier.verify(signed);
    expect(result.signatureValid, isFalse);
    expect(result.findings, contains('signature_mismatch'));
  });

  test(
    'rechaza si los campos del packet fueron alterados despues de firmar',
    () {
      final unsigned = _baseUnsigned();
      final sig = HmacSignatureVerifier.signWithSecret(
        packet: unsigned,
        secret: secretA,
      );
      final tampered = PacketEnvelope(
        type: unsigned.type,
        caseCode: unsigned.caseCode,
        issuedAt: unsigned.issuedAt,
        issuer: unsigned.issuer,
        fields: const {'nombre_pila': 'Otra Persona'},
        sig: sig,
      );
      final result = verifier.verify(tampered);
      expect(result.signatureValid, isFalse);
      expect(result.findings, contains('signature_mismatch'));
    },
  );

  test('rechaza si el keyId no existe en el resolver', () {
    final unsigned = PacketEnvelope(
      type: PacketType.intake,
      caseCode: 'x',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(0),
      issuer: const PacketIssuer(
        kind: PacketIssuerKind.citizen,
        pseudo: 'zpk:nope',
        keyId: 'unknown-key',
      ),
    );
    final signed = unsigned.withSig(
      HmacSignatureVerifier.signWithSecret(packet: unsigned, secret: secretA),
    );
    final result = verifier.verify(signed);
    expect(result.signatureValid, isFalse);
    expect(
      result.findings.any((f) => f.startsWith('unknown_issuer_key')),
      isTrue,
    );
  });

  test('rechaza algoritmo no soportado', () {
    final unsigned = _baseUnsigned();
    final p = PacketEnvelope(
      type: unsigned.type,
      caseCode: unsigned.caseCode,
      issuedAt: unsigned.issuedAt,
      issuer: unsigned.issuer,
      fields: unsigned.fields,
      sig: 'whatever',
      sigAlgo: 'Ed25519Signature2030',
    );
    final result = verifier.verify(p);
    expect(result.algoSupported, isFalse);
  });

  test('marca packet expirado', () {
    final unsigned = PacketEnvelope(
      type: PacketType.intake,
      caseCode: 'x',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(0),
      issuer: const PacketIssuer(
        kind: PacketIssuerKind.citizen,
        pseudo: 'zpk:test',
        keyId: 'citizen-key-A',
      ),
      policy: PacketPolicy(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    );
    final signed = unsigned.withSig(
      HmacSignatureVerifier.signWithSecret(packet: unsigned, secret: secretA),
    );
    final result = verifier.verify(signed);
    expect(result.findings, contains('packet_expired'));
    expect(result.isValid, isFalse);
  });

  test('packet ida y vuelta por wire mantiene verificabilidad', () {
    const codec = PacketCodec();
    final unsigned = _baseUnsigned();
    final signed = unsigned.withSig(
      HmacSignatureVerifier.signWithSecret(packet: unsigned, secret: secretA),
    );
    final wire = codec.encode(signed);
    final decoded = codec.decode(wire);

    final result = verifier.verify(decoded);
    expect(
      result.isValid,
      isTrue,
      reason:
          'expected wire roundtrip to preserve canonical hash; findings=${result.findings}',
    );
  });
}
