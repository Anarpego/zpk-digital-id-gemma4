import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Roles validos del emisor de un packet.
enum PacketIssuerKind { citizen, institution }

extension PacketIssuerKindCode on PacketIssuerKind {
  String get code => switch (this) {
    PacketIssuerKind.citizen => 'citizen',
    PacketIssuerKind.institution => 'institution',
  };
  static PacketIssuerKind fromCode(String code) => switch (code) {
    'citizen' => PacketIssuerKind.citizen,
    'institution' => PacketIssuerKind.institution,
    _ => throw FormatException('Unknown issuer kind: $code'),
  };
}

/// Tipos de packet del protocolo ZPK.
enum PacketType { intake, credential, revocation, acuse }

extension PacketTypeCode on PacketType {
  String get code => switch (this) {
    PacketType.intake => 'intake',
    PacketType.credential => 'credential',
    PacketType.revocation => 'revocation',
    PacketType.acuse => 'acuse',
  };
  static PacketType fromCode(String code) => switch (code) {
    'intake' => PacketType.intake,
    'credential' => PacketType.credential,
    'revocation' => PacketType.revocation,
    'acuse' => PacketType.acuse,
    _ => throw FormatException('Unknown packet type: $code'),
  };
}

class PacketIssuer {
  const PacketIssuer({
    required this.kind,
    required this.pseudo,
    required this.keyId,
    this.label,
  });

  final PacketIssuerKind kind;
  final String pseudo;
  final String keyId;
  final String? label;

  Map<String, dynamic> toJson() => {
    'key_id': keyId,
    'kind': kind.code,
    if (label != null) 'label': label,
    'pseudo': pseudo,
  };

  factory PacketIssuer.fromJson(Map<String, dynamic> j) => PacketIssuer(
    kind: PacketIssuerKindCode.fromCode(j['kind'] as String),
    pseudo: j['pseudo'] as String,
    keyId: j['key_id'] as String,
    label: j['label'] as String?,
  );
}

class PacketAudience {
  const PacketAudience({required this.institution, this.mesa});
  final String institution;
  final String? mesa;
  Map<String, dynamic> toJson() => {
    'institution': institution,
    if (mesa != null) 'mesa': mesa,
  };
  factory PacketAudience.fromJson(Map<String, dynamic> j) => PacketAudience(
    institution: j['institution'] as String,
    mesa: j['mesa'] as String?,
  );
}

class PacketArtifactRef {
  const PacketArtifactRef({required this.type, required this.hash});
  final String type;
  final String hash;
  Map<String, dynamic> toJson() => {'hash': hash, 'type': type};
  factory PacketArtifactRef.fromJson(Map<String, dynamic> j) =>
      PacketArtifactRef(type: j['type'] as String, hash: j['hash'] as String);
}

class PacketPolicy {
  const PacketPolicy({this.expiresAt, this.singleUse = true});
  final DateTime? expiresAt;
  final bool singleUse;
  Map<String, dynamic> toJson() => {
    if (expiresAt != null)
      'expires_at': expiresAt!.millisecondsSinceEpoch ~/ 1000,
    'single_use': singleUse,
  };
  factory PacketPolicy.fromJson(Map<String, dynamic> j) => PacketPolicy(
    expiresAt: j['expires_at'] is int
        ? DateTime.fromMillisecondsSinceEpoch((j['expires_at'] as int) * 1000)
        : null,
    singleUse: (j['single_use'] as bool?) ?? true,
  );
}

/// Envelope canonico de un packet ZPK.
///
/// La firma se calcula sobre [canonicalForSigning] (JSON con keys ordenadas
/// alfabeticamente, sin espacios, sin el campo `sig`). Esto hace que la
/// verificacion sea reproducible cross-device.
class PacketEnvelope {
  const PacketEnvelope({
    this.version = 1,
    required this.type,
    required this.caseCode,
    required this.issuedAt,
    required this.issuer,
    this.audience,
    this.fields = const {},
    this.redacted = const [],
    this.artifactRef,
    this.policy,
    this.inResponseTo,
    this.revokes,
    this.decision,
    this.ticket,
    this.nextStepText,
    this.reason,
    this.sig = '',
    this.sigAlgo = 'HmacSha256Signature2026',
  });

  final int version;
  final PacketType type;
  final String caseCode;
  final DateTime issuedAt;
  final PacketIssuer issuer;
  final PacketAudience? audience;
  final Map<String, dynamic> fields;
  final List<String> redacted;
  final PacketArtifactRef? artifactRef;
  final PacketPolicy? policy;

  // Para acuse:
  final String? inResponseTo;
  final String? decision;
  final String? ticket;
  final String? nextStepText;

  // Para revocation:
  final String? revokes;
  final String? reason;

  final String sig;
  final String sigAlgo;

  Map<String, dynamic> toJson() => {
    if (artifactRef != null) 'artifact_ref': artifactRef!.toJson(),
    if (audience != null) 'audience': audience!.toJson(),
    'case': caseCode,
    if (decision != null) 'decision': decision,
    if (inResponseTo != null) 'in_response_to': inResponseTo,
    'issued_at': issuedAt.millisecondsSinceEpoch ~/ 1000,
    'issuer': issuer.toJson(),
    if (fields.isNotEmpty) 'fields': fields,
    if (nextStepText != null) 'next_step_text': nextStepText,
    if (policy != null) 'policy': policy!.toJson(),
    if (reason != null) 'reason': reason,
    if (redacted.isNotEmpty) 'redacted': redacted,
    if (revokes != null) 'revokes': revokes,
    'sig': sig,
    'sig_algo': sigAlgo,
    if (ticket != null) 'ticket': ticket,
    'type': type.code,
    'v': version,
  };

  factory PacketEnvelope.fromJson(Map<String, dynamic> j) => PacketEnvelope(
    version: (j['v'] as int?) ?? 1,
    type: PacketTypeCode.fromCode(j['type'] as String),
    caseCode: j['case'] as String,
    issuedAt: DateTime.fromMillisecondsSinceEpoch(
      (j['issued_at'] as int) * 1000,
    ),
    issuer: PacketIssuer.fromJson(j['issuer'] as Map<String, dynamic>),
    audience: j['audience'] is Map<String, dynamic>
        ? PacketAudience.fromJson(j['audience'] as Map<String, dynamic>)
        : null,
    fields: (j['fields'] as Map<String, dynamic>?) ?? const {},
    redacted: ((j['redacted'] as List?) ?? const [])
        .map((e) => e as String)
        .toList(),
    artifactRef: j['artifact_ref'] is Map<String, dynamic>
        ? PacketArtifactRef.fromJson(j['artifact_ref'] as Map<String, dynamic>)
        : null,
    policy: j['policy'] is Map<String, dynamic>
        ? PacketPolicy.fromJson(j['policy'] as Map<String, dynamic>)
        : null,
    inResponseTo: j['in_response_to'] as String?,
    revokes: j['revokes'] as String?,
    decision: j['decision'] as String?,
    ticket: j['ticket'] as String?,
    nextStepText: j['next_step_text'] as String?,
    reason: j['reason'] as String?,
    sig: (j['sig'] as String?) ?? '',
    sigAlgo: (j['sig_algo'] as String?) ?? 'HmacSha256Signature2026',
  );

  /// Bytes que se firman: JSON con keys ordenadas y sin el campo `sig`.
  String canonicalForSigning() {
    final j = Map<String, dynamic>.from(toJson())..remove('sig');
    return canonicalJsonEncode(j);
  }

  PacketEnvelope withSig(String newSig) => PacketEnvelope(
    version: version,
    type: type,
    caseCode: caseCode,
    issuedAt: issuedAt,
    issuer: issuer,
    audience: audience,
    fields: fields,
    redacted: redacted,
    artifactRef: artifactRef,
    policy: policy,
    inResponseTo: inResponseTo,
    revokes: revokes,
    decision: decision,
    ticket: ticket,
    nextStepText: nextStepText,
    reason: reason,
    sig: newSig,
    sigAlgo: sigAlgo,
  );

  /// Hash sha256 sobre la forma canonica (con sig). Util para identificar
  /// el packet en el ledger y como referencia en acuses/revocaciones.
  String hash() {
    final canonical = canonicalJsonEncode(toJson());
    return 'sha256:${sha256.convert(utf8.encode(canonical)).toString()}';
  }
}

/// Encoder JSON canonico: keys ordenadas alfabeticamente recursivamente,
/// sin espacios. Necesario para que firma y hash sean reproducibles entre
/// dispositivos y entre lados (ciudadano y ventanilla).
String canonicalJsonEncode(Object? value) {
  final buffer = StringBuffer();
  _writeCanonical(value, buffer);
  return buffer.toString();
}

void _writeCanonical(Object? value, StringBuffer out) {
  if (value == null) {
    out.write('null');
    return;
  }
  if (value is bool || value is num) {
    out.write(jsonEncode(value));
    return;
  }
  if (value is String) {
    out.write(jsonEncode(value));
    return;
  }
  if (value is List) {
    out.write('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) out.write(',');
      _writeCanonical(value[i], out);
    }
    out.write(']');
    return;
  }
  if (value is Map) {
    final keys = value.keys.map((e) => e.toString()).toList()..sort();
    out.write('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) out.write(',');
      out.write(jsonEncode(keys[i]));
      out.write(':');
      _writeCanonical(value[keys[i]], out);
    }
    out.write('}');
    return;
  }
  throw FormatException('Cannot canonicalize ${value.runtimeType}');
}
