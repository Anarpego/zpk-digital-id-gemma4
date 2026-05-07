import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/zpk/packet_codec.dart';
import 'package:kan_app/services/zpk/packet_envelope.dart';

PacketEnvelope _samplePacket() => PacketEnvelope(
  type: PacketType.intake,
  caseCode: 'igss_sin_dpi',
  issuedAt: DateTime.fromMillisecondsSinceEpoch(1714742400 * 1000),
  issuer: const PacketIssuer(
    kind: PacketIssuerKind.citizen,
    pseudo: 'zpk:abc123',
    keyId: 'citizen-2026-05-key-1',
  ),
  audience: const PacketAudience(institution: 'IGSS', mesa: 'Quetzaltenango'),
  fields: const {
    'nombre_pila': 'Ana',
    'edad': 67,
    'departamento': 'Quetzaltenango',
    'necesidad': 'atencion presencial sin DPI',
  },
  redacted: const ['cui', 'telefono', 'direccion_completa'],
  artifactRef: const PacketArtifactRef(
    type: 'solicitud_igss',
    hash: 'sha256:deadbeef',
  ),
);

void main() {
  const codec = PacketCodec();

  test('encode/decode roundtrip preserva todos los campos', () {
    final original = _samplePacket();
    final wire = codec.encode(original);
    expect(wire, startsWith('zpk1:'));

    final decoded = codec.decode(wire);
    expect(decoded.type, PacketType.intake);
    expect(decoded.caseCode, 'igss_sin_dpi');
    expect(decoded.issuer.pseudo, 'zpk:abc123');
    expect(decoded.audience?.institution, 'IGSS');
    expect(decoded.fields['nombre_pila'], 'Ana');
    expect(decoded.fields['edad'], 67);
    expect(decoded.redacted, contains('cui'));
    expect(decoded.artifactRef?.hash, 'sha256:deadbeef');
  });

  test('rechaza payload sin prefijo zpk1', () {
    expect(() => codec.decode('xyz:abc'), throwsFormatException);
  });

  test('rechaza base64 corrupto', () {
    expect(
      () => codec.decode('zpk1:!!!not-valid-base64!!!'),
      throwsFormatException,
    );
  });

  test('rechaza gzip corrupto pero base64 valido', () {
    expect(() => codec.decode('zpk1:aGVsbG8gd29ybGQ'), throwsFormatException);
  });

  test('canonical json es estable: mismas keys, distinto orden de input', () {
    final a = canonicalJsonEncode({'b': 1, 'a': 2, 'c': 3});
    final b = canonicalJsonEncode({'c': 3, 'a': 2, 'b': 1});
    expect(a, equals(b));
    expect(a, '{"a":2,"b":1,"c":3}');
  });

  test('canonical json ordena keys recursivamente', () {
    final s = canonicalJsonEncode({
      'outer_b': {'z': 1, 'a': 2},
      'outer_a': [
        {'q': 1, 'p': 2},
      ],
    });
    expect(s, '{"outer_a":[{"p":2,"q":1}],"outer_b":{"a":2,"z":1}}');
  });

  test('hash() del envelope es estable y empieza con sha256:', () {
    final a = _samplePacket().hash();
    final b = _samplePacket().hash();
    expect(a, equals(b));
    expect(a, startsWith('sha256:'));
  });

  test('payload comprimido tipico cabe en un QR estandar (<2KB)', () {
    final wire = codec.encode(_samplePacket());
    expect(wire.length, lessThan(2000), reason: 'wire len = ${wire.length}');
  });
}
