import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/multimodal/qr_service.dart';
import 'package:kan_app/services/zpk/institution_trust_list.dart';
import 'package:kan_app/services/zpk/packet_envelope.dart';
import 'package:kan_app/services/zpk/signature_verifier.dart';

void main() {
  test('ciudadano firma packet, ventanilla lo verifica via wire', () {
    const citizenKey = 'zpk-citizen-demo-key';
    final citizenSecret = InstitutionTrustList.demoKeys[citizenKey]!;

    final unsigned = PacketEnvelope(
      type: PacketType.intake,
      caseCode: 'igss_sin_dpi',
      issuedAt: DateTime.now(),
      issuer: PacketIssuer(
        kind: PacketIssuerKind.citizen,
        pseudo: 'zpk:test-citizen',
        keyId: citizenKey,
      ),
      audience: const PacketAudience(institution: 'IGSS'),
      fields: const {'titulo': 'Solicitud IGSS', 'caso': 'igss_sin_dpi'},
      redacted: const ['cui', 'telefono', 'direccion_completa'],
    );
    final signed = unsigned.withSig(
      HmacSignatureVerifier.signWithSecret(
        packet: unsigned,
        secret: citizenSecret,
      ),
    );

    final wire = QrService.encode(signed);
    expect(QrService.looksLikeZpk(wire), isTrue);
    expect(wire.length, lessThan(2000));

    final decoded = QrService.decode(wire);
    final result = HmacSignatureVerifier(
      keyResolver: InstitutionTrustList.buildResolver(),
    ).verify(decoded);
    expect(result.isValid, isTrue);
  });

  test('ventanilla firma acuse, ciudadano lo verifica via wire', () {
    const igssKey = 'igss-mesa-demo-key';
    final igssSecret = InstitutionTrustList.demoKeys[igssKey]!;

    final unsigned = PacketEnvelope(
      type: PacketType.acuse,
      caseCode: 'igss_sin_dpi',
      issuedAt: DateTime.now(),
      issuer: const PacketIssuer(
        kind: PacketIssuerKind.institution,
        pseudo: 'zpk:igss-quetzaltenango',
        keyId: igssKey,
      ),
      inResponseTo: 'sha256:0000aaaa',
      decision: 'atendido',
      ticket: 'IGSS-DEMO-001',
      nextStepText: 'Pase a mesa 3 con identificacion alterna.',
    );
    final signed = unsigned.withSig(
      HmacSignatureVerifier.signWithSecret(
        packet: unsigned,
        secret: igssSecret,
      ),
    );

    final wire = QrService.encode(signed);
    final decoded = QrService.decode(wire);
    final result = HmacSignatureVerifier(
      keyResolver: InstitutionTrustList.buildResolver(),
    ).verify(decoded);
    expect(result.isValid, isTrue);
    expect(decoded.type, PacketType.acuse);
    expect(decoded.decision, 'atendido');
    expect(decoded.ticket, 'IGSS-DEMO-001');
  });

  test('alteracion de campo despues del wire invalida la firma', () {
    const k = 'zpk-citizen-demo-key';
    final secret = InstitutionTrustList.demoKeys[k]!;

    final unsigned = PacketEnvelope(
      type: PacketType.intake,
      caseCode: 'caso',
      issuedAt: DateTime.fromMillisecondsSinceEpoch(0),
      issuer: PacketIssuer(
        kind: PacketIssuerKind.citizen,
        pseudo: 'zpk:x',
        keyId: k,
      ),
      fields: const {'a': '1'},
    );
    final signed = unsigned.withSig(
      HmacSignatureVerifier.signWithSecret(packet: unsigned, secret: secret),
    );

    // Reconstruir el packet con un field cambiado pero misma firma
    final tampered = PacketEnvelope(
      type: signed.type,
      caseCode: signed.caseCode,
      issuedAt: signed.issuedAt,
      issuer: signed.issuer,
      fields: const {'a': '999'},
      sig: signed.sig,
    );

    final result = HmacSignatureVerifier(
      keyResolver: InstitutionTrustList.buildResolver(),
    ).verify(tampered);
    expect(result.isValid, isFalse);
    expect(result.findings, contains('signature_mismatch'));
  });
}
