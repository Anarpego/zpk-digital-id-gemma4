import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';

class RecoveryPacket {
  const RecoveryPacket({
    required this.privateLocalComplaint,
    required this.redactedSharePacket,
    required this.redactedPacketHash,
    required this.signature,
    required this.keyStore,
    required this.trace,
  });

  final String privateLocalComplaint;
  final Map<String, Object> redactedSharePacket;
  final String redactedPacketHash;
  final String signature;
  final String keyStore;
  final List<String> trace;
}

class RecoveryPacketService {
  const RecoveryPacketService({required this.identityFabric});

  final DigitalIdentityFabric identityFabric;

  Future<RecoveryPacket> build({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityTrustReport trustReport,
    required String privateLocalComplaint,
  }) async {
    final redactedSharePacket = <String, Object>{
      'packetType': 'ZpkIdentityRecoverySharePacket',
      'jurisdiction': 'GT',
      'citizenPseudonym': trustReport.credential.pseudonymousId,
      'did': trustReport.didDocument['id'] as String,
      'scenario': scenario.shortCode,
      'localMatches': result.matches.length,
      'catalogSource': result.catalogSource,
      'selectiveDisclosureClaims': trustReport.selectiveDisclosureClaims,
      'recoveryStatus': trustReport.recoveryStatus,
      'consentScope': trustReport.consentGrant.scope,
      'consentExpiresInMinutes': trustReport.consentGrant.expiresInMinutes,
      'redactionPolicy': 'raw_cui_retained_on_device',
      'institutionFacts': [
        for (final match in result.matches)
          {
            'source': match.name,
            'exposedFields': match.exposedFields,
            'reportedOn': match.reportedOn.toUtc().toIso8601String(),
          },
      ],
    };
    final canonicalPacket = _canonicalJson(redactedSharePacket);
    final packetHash = sha256.convert(utf8.encode(canonicalPacket)).toString();
    final signature = await identityFabric.signCanonicalPayload(
      _canonicalJson({
        'purpose': 'zpk-redacted-recovery-packet',
        'issuer': identityFabric.issuerKeyId,
        'packet': redactedSharePacket,
      }),
    );

    return RecoveryPacket(
      privateLocalComplaint: privateLocalComplaint,
      redactedSharePacket: redactedSharePacket,
      redactedPacketHash: packetHash,
      signature: signature.proofValue,
      keyStore: signature.keyStore,
      trace: [
        'recovery_packet.private_complaint(local_only) -> ready',
        'recovery_packet.redact(raw_cui) -> retained_on_device',
        'recovery_packet.hash(sha256) -> ${packetHash.substring(0, 16)}',
        'recovery_packet.sign(${signature.keyStore}) -> ${signature.proofValue.substring(0, 16)}',
      ],
    );
  }

  String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }
}
