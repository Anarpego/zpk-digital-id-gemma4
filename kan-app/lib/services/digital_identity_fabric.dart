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
  const DigitalIdentityFabric();

  IdentityTrustReport evaluate({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityAgentAssessment assessment,
  }) {
    final pseudonym = _stablePseudonym(result.cui);
    final risk = assessment.riskLevel.label;
    final registryState = result.isValidCui ? 'format_verified' : 'blocked';
    final did = 'did:zpk:gt:$pseudonym';
    final proof =
        'proof-${_stableToken('$pseudonym:$risk:${scenario.shortCode}')}';
    final recoveryStatus = switch (assessment.riskLevel) {
      IdentityRiskLevel.blocked => 'No se emite credencial hasta corregir CUI.',
      IdentityRiskLevel.low =>
        'Identidad preventiva: credencial local lista, sin alerta activa.',
      IdentityRiskLevel.medium =>
        'Revision recomendada: emitir consentimiento limitado para orientacion.',
      IdentityRiskLevel.high || IdentityRiskLevel.critical =>
        'Recuperacion prioritaria: preparar prueba local y paquete institucional.',
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
        localProof: proof,
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
      verifiableCredential: {
        'type': ['VerifiableCredential', 'ZpkIdentityRecoveryCredential'],
        'issuer': 'did:zpk:gt:local-trust-fabric',
        'credentialSubject': {
          'id': did,
          'risk': risk,
          'matches': result.matches.length,
          'scenario': scenario.shortCode,
        },
        'proof': {
          'type': 'LocalDeterministicProof',
          'proofPurpose': 'selective_disclosure_demo',
          'proofValue': proof,
        },
      },
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
        'trust_fabric.issue_consent(local, 15m) -> ok',
        'trust_fabric.revocation_recovery(local) -> ${assessment.riskLevel.label}',
        'trust_fabric.institution_packet(redacted) -> ${result.matches.length}_matches',
      ],
    );
  }

  String _stablePseudonym(String cui) {
    if (cui.length != 13) {
      return 'zpk-gt-invalid';
    }
    return 'zpk-gt-${_stableToken(cui).substring(0, 10)}';
  }

  String _stableToken(String input) {
    final first = _fnv32(input, 0x811c9dc5);
    final second = _fnv32('zpk:$input', 0x811c9dc5);
    return '$first$second';
  }

  String _fnv32(String input, int seed) {
    var hash = seed;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
