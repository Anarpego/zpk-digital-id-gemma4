import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';
import 'revocation_service.dart';

class LocalAuthenticationProof {
  const LocalAuthenticationProof({
    required this.relyingParty,
    required this.challenge,
    required this.pseudonymousId,
    required this.requestedClaims,
    required this.issuedAt,
    required this.expiresAt,
    required this.expiresInMinutes,
    required this.payloadHash,
    required this.signature,
    required this.keyStore,
    required this.sharePacket,
    required this.trace,
  });

  final String relyingParty;
  final String challenge;
  final String pseudonymousId;
  final List<String> requestedClaims;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final int expiresInMinutes;
  final String payloadHash;
  final String signature;
  final String keyStore;
  final Map<String, Object> sharePacket;
  final List<String> trace;
}

class RelyingPartyPolicy {
  const RelyingPartyPolicy({this.allowedParties = defaultAllowedParties});

  static const defaultAllowedParties = {
    'municipalidad-guatemala-demo': ['identity_recovery', 'citizen_support'],
    'registro-civil-gt-demo': ['identity_recovery'],
  };

  final Map<String, List<String>> allowedParties;

  List<String> scopesFor(String relyingParty) =>
      allowedParties[relyingParty] ?? const [];

  bool isAllowed(String relyingParty) => scopesFor(relyingParty).isNotEmpty;
}

class LocalAuthenticationService {
  const LocalAuthenticationService({
    this.identityFabric = const DigitalIdentityFabric(),
    this.relyingPartyPolicy = const RelyingPartyPolicy(),
    this.fixedNow,
  });

  final DigitalIdentityFabric identityFabric;
  final RelyingPartyPolicy relyingPartyPolicy;
  final DateTime? fixedNow;

  Future<LocalAuthenticationProof> buildProof({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityTrustReport trustReport,
    LocalRevocationReceipt? revocationReceipt,
    String relyingParty = 'municipalidad-guatemala-demo',
  }) async {
    if (revocationReceipt != null) {
      throw StateError(
        'Local credential ${revocationReceipt.revocationId} is revoked.',
      );
    }
    final allowedScopes = relyingPartyPolicy.scopesFor(relyingParty);
    if (allowedScopes.isEmpty) {
      throw StateError('Relying party $relyingParty is not allowed.');
    }

    final issuedAt = _now();
    final expiresAt = issuedAt.add(const Duration(minutes: 5));
    final challenge = _challengeFor(
      relyingParty: relyingParty,
      result: result,
      scenario: scenario,
      issuedAt: issuedAt,
    );
    final requestedClaims = [
      'citizen=${trustReport.credential.pseudonymousId}',
      'risk=${trustReport.credential.assuranceLevel}',
      'scenario=${scenario.shortCode}',
      'matches=${result.matches.length}',
    ];
    final sharePacket = <String, Object>{
      'type': 'ZpkLocalAuthenticationProof',
      'relyingParty': relyingParty,
      'challenge': challenge,
      'citizenPseudonym': trustReport.credential.pseudonymousId,
      'did': trustReport.didDocument['id']!,
      'allowedScopes': allowedScopes,
      'requestedClaims': requestedClaims,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'expiresInMinutes': 5,
    };
    final canonicalPayload = _canonicalJson(sharePacket);
    final payloadHash = sha256
        .convert(utf8.encode(canonicalPayload))
        .toString();
    final signature = await identityFabric.signCanonicalPayload(
      canonicalPayload,
    );
    final signedSharePacket = {
      ...sharePacket,
      'proof': {
        'type': signature.proofSuite,
        'cryptosuite': 'HMAC-SHA-256',
        'verificationMethod':
            '${trustReport.didDocument['id']}#${identityFabric.issuerKeyId}',
        'proofPurpose': 'authentication',
        'keyStore': signature.keyStore,
        'proofValue': signature.proofValue,
      },
    };
    final verification = await verifySharePacket(signedSharePacket);

    return LocalAuthenticationProof(
      relyingParty: relyingParty,
      challenge: challenge,
      pseudonymousId: trustReport.credential.pseudonymousId,
      requestedClaims: requestedClaims,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      expiresInMinutes: 5,
      payloadHash: payloadHash,
      signature: signature.proofValue,
      keyStore: signature.keyStore,
      sharePacket: signedSharePacket,
      trace: [
        'auth.relying_party(local_allowlist) -> approved',
        'auth.scopes(local_policy) -> ${allowedScopes.join('+')}',
        'auth.challenge(local) -> ${payloadHash.substring(0, 16)}',
        'auth.selective_disclosure(local) -> ${requestedClaims.length}_claims',
        'auth.raw_cui -> omitted',
        'auth.sign(${signature.keyStore}) -> ${signature.proofValue.substring(0, 16)}',
        'auth.verify(local) -> ${verification ? 'ok' : 'failed'}',
        'auth.valid_until(local) -> ${expiresAt.toIso8601String()}',
        'auth.expires(local) -> 5m',
      ],
    );
  }

  Future<bool> verifySharePacket(Map<String, Object> sharePacket) async {
    final proof = sharePacket['proof'] as Map<String, Object>?;
    final proofValue = proof?['proofValue'] as String?;
    final proofPurpose = proof?['proofPurpose'] as String?;
    if (proofValue == null ||
        proofValue.isEmpty ||
        proofPurpose != 'authentication') {
      return false;
    }

    final unsignedPacket = Map<String, Object>.from(sharePacket)
      ..remove('proof');
    if (unsignedPacket['type'] != 'ZpkLocalAuthenticationProof') {
      return false;
    }
    final relyingParty = unsignedPacket['relyingParty'] as String?;
    if (relyingParty == null || relyingParty.isEmpty) {
      return false;
    }
    final allowedScopes = relyingPartyPolicy.scopesFor(relyingParty);
    if (allowedScopes.isEmpty) {
      return false;
    }
    final packetScopes = unsignedPacket['allowedScopes'];
    if (packetScopes is! Iterable ||
        !_sameStringList(packetScopes, allowedScopes)) {
      return false;
    }
    final expiresAt = DateTime.tryParse(
      unsignedPacket['expiresAt']?.toString() ?? '',
    );
    if (expiresAt == null || _now().isAfter(expiresAt)) {
      return false;
    }
    final expected = await identityFabric.signCanonicalPayload(
      _canonicalJson(unsignedPacket),
    );
    return expected.proofValue == proofValue;
  }

  bool _sameStringList(Iterable<Object?> first, List<String> second) {
    final firstList = first.map((item) => item.toString()).toList();
    if (firstList.length != second.length) {
      return false;
    }
    for (var index = 0; index < firstList.length; index += 1) {
      if (firstList[index] != second[index]) {
        return false;
      }
    }
    return true;
  }

  String _challengeFor({
    required String relyingParty,
    required VerificationResult result,
    required CaseScenario scenario,
    required DateTime issuedAt,
  }) {
    final seed = _canonicalJson({
      'checkedAt': result.checkedAt.toUtc().toIso8601String(),
      'issuedAt': issuedAt.toIso8601String(),
      'matches': result.matches.length,
      'relyingParty': relyingParty,
      'scenario': scenario.shortCode,
    });
    return 'zpk-auth-${sha256.convert(utf8.encode(seed)).toString().substring(0, 24)}';
  }

  DateTime _now() => (fixedNow ?? DateTime.now()).toUtc();

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
