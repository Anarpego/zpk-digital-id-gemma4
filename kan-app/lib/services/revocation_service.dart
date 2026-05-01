import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';

class LocalRevocationReceipt {
  const LocalRevocationReceipt({
    required this.revocationId,
    required this.createdAt,
    required this.citizenPseudonym,
    required this.did,
    required this.reason,
    required this.receiptHash,
    required this.signature,
    required this.keyStore,
    required this.redactedPayload,
    required this.trace,
  });

  final String revocationId;
  final DateTime createdAt;
  final String citizenPseudonym;
  final String did;
  final String reason;
  final String receiptHash;
  final String signature;
  final String keyStore;
  final Map<String, Object> redactedPayload;
  final List<String> trace;
}

class RevocationService {
  const RevocationService({required this.identityFabric});

  final DigitalIdentityFabric identityFabric;

  Future<LocalRevocationReceipt> revokeLocalCredential({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityTrustReport trustReport,
    required String reason,
  }) async {
    final createdAt = result.checkedAt.toUtc();
    final payload = <String, Object>{
      'type': 'ZpkLocalCredentialRevocation',
      'jurisdiction': 'GT',
      'citizenPseudonym': trustReport.credential.pseudonymousId,
      'did': trustReport.didDocument['id'] as String,
      'scenario': scenario.shortCode,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'redactionPolicy': 'raw_cui_omitted',
    };
    final canonicalPayload = _canonicalJson(payload);
    if (canonicalPayload.contains(result.cui)) {
      throw StateError('Revocation receipt contains raw CUI.');
    }
    final receiptHash = sha256
        .convert(utf8.encode(canonicalPayload))
        .toString();
    final signature = await identityFabric.signCanonicalPayload(
      _canonicalJson({
        'purpose': 'zpk-local-credential-revocation',
        'issuer': identityFabric.issuerKeyId,
        'payload': payload,
      }),
    );
    final revocationId = 'zpk-rev-${receiptHash.substring(0, 16)}';

    return LocalRevocationReceipt(
      revocationId: revocationId,
      createdAt: createdAt,
      citizenPseudonym: trustReport.credential.pseudonymousId,
      did: trustReport.didDocument['id'] as String,
      reason: reason,
      receiptHash: receiptHash,
      signature: signature.proofValue,
      keyStore: signature.keyStore,
      redactedPayload: payload,
      trace: [
        'revocation.reason(local) -> $reason',
        'revocation.redact(raw_cui) -> omitted',
        'revocation.receipt(sha256) -> ${receiptHash.substring(0, 16)}',
        'revocation.sign(${signature.keyStore}) -> ${signature.proofValue.substring(0, 16)}',
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
