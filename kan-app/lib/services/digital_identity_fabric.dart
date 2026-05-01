import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/kan_case.dart';
import 'identity_protection_agent.dart';

class LocalCredential {
  const LocalCredential({
    required this.pseudonymousId,
    required this.issuer,
    required this.assuranceLevel,
  });

  final String pseudonymousId;
  final String issuer;
  final String assuranceLevel;
}

class ConsentGrant {
  const ConsentGrant({
    required this.relyingParty,
    required this.scope,
    required this.expiresInMinutes,
    required this.localProof,
  });

  final String relyingParty;
  final String scope;
  final int expiresInMinutes;
  final String localProof;
}

class IdentityTrustReport {
  const IdentityTrustReport({
    required this.credential,
    required this.consentGrant,
    required this.didDocument,
    required this.verifiableCredential,
    required this.selectiveDisclosureClaims,
    required this.recoveryStatus,
    required this.institutionPacket,
    required this.interoperabilityNotes,
    required this.trace,
  });

  final LocalCredential credential;
  final ConsentGrant consentGrant;
  final Map<String, Object> didDocument;
  final Map<String, Object> verifiableCredential;
  final List<String> selectiveDisclosureClaims;
  final String recoveryStatus;
  final List<String> institutionPacket;
  final List<String> interoperabilityNotes;
  final List<String> trace;
}

class DigitalIdentityFabric {
  const DigitalIdentityFabric({
    this.issuerKeyId = 'zpk-local-issuer-key-2026-05',
    this.issuerSecret = _demoIssuerSecret,
  });

  static const _demoIssuerSecret =
      'zpk-local-demo-issuer-secret-replace-before-production';

  final String issuerKeyId;
  final String issuerSecret;

  IdentityTrustReport evaluate({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityAgentAssessment assessment,
  }) {
    final pseudonym = _stablePseudonym(result.cui);
    final risk = assessment.riskLevel.label;
    final registryState = result.isValidCui ? 'format_verified' : 'blocked';
    final did = 'did:zpk:gt:$pseudonym';
    final issuedAt = result.checkedAt.toUtc().toIso8601String();
    final recoveryStatus = switch (assessment.riskLevel) {
      IdentityRiskLevel.blocked => 'No se emite credencial hasta corregir CUI.',
      IdentityRiskLevel.low =>
        'Identidad preventiva: credencial local lista, sin alerta activa.',
      IdentityRiskLevel.medium =>
        'Revision recomendada: emitir consentimiento limitado para orientacion.',
      IdentityRiskLevel.high || IdentityRiskLevel.critical =>
        'Recuperacion prioritaria: preparar prueba local y paquete institucional.',
    };

    final credentialSubject = {
      'id': did,
      'risk': risk,
      'matches': result.matches.length,
      'scenario': scenario.shortCode,
      'catalog': result.catalogSource,
      'issuedAt': issuedAt,
    };
    final proofValue = _sign({
      'credentialSubject': credentialSubject,
      'issuer': 'did:zpk:gt:local-trust-fabric',
      'type': ['VerifiableCredential', 'ZpkIdentityRecoveryCredential'],
    });
    final verifiableCredential = {
      'type': ['VerifiableCredential', 'ZpkIdentityRecoveryCredential'],
      'issuer': 'did:zpk:gt:local-trust-fabric',
      'credentialSubject': credentialSubject,
      'proof': {
        'type': 'HmacSha256Signature2026',
        'cryptosuite': 'HMAC-SHA-256',
        'created': issuedAt,
        'verificationMethod': 'did:zpk:gt:local-trust-fabric#$issuerKeyId',
        'proofPurpose': 'assertionMethod',
        'proofValue': proofValue,
      },
    };

    return IdentityTrustReport(
      credential: LocalCredential(
        pseudonymousId: pseudonym,
        issuer: 'ZPK Digital ID Local Trust Fabric',
        assuranceLevel: result.isExposed
            ? 'alto_riesgo_verificado'
            : 'basico_local',
      ),
      consentGrant: ConsentGrant(
        relyingParty: 'institucion_autorizada_demo',
        scope: 'identity_recovery:$risk:${scenario.shortCode}',
        expiresInMinutes: 15,
        localProof: proofValue,
      ),
      didDocument: {
        'id': did,
        'controller': did,
        'verificationMethod': [
          {
            'id': '$did#device-key',
            'type': 'LocalDemoKey2026',
            'controller': did,
          },
        ],
      },
      verifiableCredential: verifiableCredential,
      selectiveDisclosureClaims: [
        'risk=$risk',
        'matches=${result.matches.length}',
        'scenario=${scenario.shortCode}',
        'citizen=$pseudonym',
      ],
      recoveryStatus: recoveryStatus,
      institutionPacket: [
        'CUI completo: retenido en dispositivo',
        'Pseudonimo ciudadano: $pseudonym',
        'Riesgo: $risk',
        'Coincidencias locales: ${result.matches.length}',
        'Flujo: ${scenario.label}',
      ],
      interoperabilityNotes: const [
        'Guatemala: DPI/CUI se trata como identificador sensible local.',
        'LatAm: cambiar validador nacional y plantillas, mantener consentimiento y pseudonimo.',
        'Instituciones: recibir hechos minimos, no base centralizada de CUI.',
      ],
      trace: [
        'trust_fabric.registry_check(local) -> $registryState',
        'trust_fabric.pseudonymize(local) -> $pseudonym',
        'trust_fabric.did_document(local) -> $did',
        'trust_fabric.vc_selective_disclosure(local) -> ${result.matches.length}_matches',
        'trust_fabric.sign_credential(hmac-sha256) -> ok',
        'trust_fabric.verify_credential_signature(local) -> ${verifyCredential(verifiableCredential: verifiableCredential) ? 'ok' : 'failed'}',
        'trust_fabric.issue_consent(local, 15m) -> signed',
        'trust_fabric.revocation_recovery(local) -> ${assessment.riskLevel.label}',
        'trust_fabric.institution_packet(redacted) -> ${result.matches.length}_matches',
      ],
    );
  }

  bool verifyCredential({required Map<String, Object> verifiableCredential}) {
    final proof = verifiableCredential['proof'] as Map<String, Object>?;
    final proofValue = proof?['proofValue'] as String?;
    if (proofValue == null || proofValue.isEmpty) {
      return false;
    }
    return proofValue ==
        _sign({
          'credentialSubject': verifiableCredential['credentialSubject'],
          'issuer': verifiableCredential['issuer'],
          'type': verifiableCredential['type'],
        });
  }

  String _stablePseudonym(String cui) {
    if (cui.length != 13) {
      return 'zpk-gt-invalid';
    }
    return 'zpk-gt-${_stableToken(cui).substring(0, 16)}';
  }

  String _stableToken(String input) {
    return _sign({'purpose': 'zpk-local-pseudonym', 'value': input});
  }

  String _sign(Map<String, Object?> payload) {
    final hmac = Hmac(sha256, utf8.encode(issuerSecret));
    return hmac.convert(utf8.encode(_canonicalJson(payload))).toString();
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
