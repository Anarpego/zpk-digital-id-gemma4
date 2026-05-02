import 'dart:async';

import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';

abstract interface class KanReasoner {
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  });
}

class FallbackReasoner implements KanReasoner {
  const FallbackReasoner({
    required this.primary,
    required this.fallback,
    required this.primaryLabel,
    this.timeout = const Duration(seconds: 45),
  });

  final KanReasoner primary;
  final KanReasoner fallback;
  final String primaryLabel;
  final Duration timeout;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    try {
      final guidance = await primary
          .explain(result: result, scenario: scenario)
          .timeout(timeout);
      return guidance.copyWith(
        toolTrace: [
          'reasoner_mode($primaryLabel) -> ok',
          ...guidance.toolTrace,
        ],
      );
    } catch (error) {
      final guidance = await fallback.explain(
        result: result,
        scenario: scenario,
      );
      final detail = _describeError(error);
      return guidance.copyWith(
        toolTrace: [
          'reasoner_mode($primaryLabel) -> fallback: $detail',
          'reasoner_timeout -> ${timeout.inSeconds}s',
          ...guidance.toolTrace,
        ],
      );
    }
  }

  String _describeError(Object error) {
    final message = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    final detail = message.isEmpty ? error.runtimeType.toString() : message;
    return detail.length <= 140 ? detail : '${detail.substring(0, 137)}...';
  }
}

class ReasonerPromptBuilder {
  const ReasonerPromptBuilder();

  static const experiencePrior = [
    'Primero confirmar exposicion local antes de pedir datos personales.',
    'Separar explicacion simple de pasos legales para no abrumar al usuario.',
    'Generar documentos con datos personales solo en el dispositivo.',
  ];

  Future<String> build({
    required VerificationResult result,
    required CaseScenario scenario,
    DigitalIdentityFabric identityFabric = const DigitalIdentityFabric(),
  }) async {
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: scenario,
    );
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final matches = result.matches
        .map(
          (match) =>
              '${match.slug}: ${match.name} (${match.exposedFields.join(', ')})',
        )
        .join('\n');
    final selectiveClaims = trustReport.selectiveDisclosureClaims.map((claim) {
      if (claim.startsWith('citizen=')) {
        return 'citizen=local_pseudonym_available';
      }
      return claim;
    });
    final institutionPacket = trustReport.institutionPacket.map((item) {
      if (item.startsWith('Pseudonimo ciudadano:')) {
        return 'Pseudonimo ciudadano: emitido_localmente';
      }
      return item;
    });

    return '''
Eres ZPK Digital ID, un agente ciudadano para registro, autenticacion y
recuperacion segura de identidad en Guatemala.
Tu meta es ayudar a una persona a defender su identidad digital sin filtrar CUI,
DPI, telefono, direccion ni evidencia privada. Piensa como un sistema nacional
que puede repetirse en Guatemala y otros paises de America Latina.

Reglas aprendidas por experiencia:
${experiencePrior.map((rule) => '- $rule').join('\n')}

${assessment.toPromptBlock()}

Infraestructura local de identidad:
- emisor_demo: ${trustReport.credential.issuer}
- pseudonimo_ciudadano: emitido_localmente
- nivel_aseguramiento: ${trustReport.credential.assuranceLevel}
- consentimiento: ${trustReport.consentGrant.scope}
- prueba_local: firmada_en_dispositivo
- did_local: did:zpk:gt:<redacted-local-id>
- credencial_verificable_demo: ${trustReport.verifiableCredential['type']}
- divulgacion_selectiva: ${selectiveClaims.join(', ')}
- recuperacion: ${trustReport.recoveryStatus}
- paquete_institucional:
${institutionPacket.map((item) => '  - $item').join('\n')}

Caso:
- flujo: ${scenario.label}
- cui_valido: ${result.isValidCui}
- coincidencias_locales: ${result.matches.length}
- brechas:
${matches.isEmpty ? 'ninguna' : matches}

Responde solo con JSON valido, sin Markdown, con este esquema exacto:
{
  "summary": "explicacion breve en espanol sin CUI ni identificadores",
  "next_steps": ["paso accionable", "paso accionable"],
  "national_scale_note": "como este flujo escala para Guatemala y America Latina",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
No inventes instituciones. No pidas mas datos personales. Si hay coincidencia,
recomienda evidencia, DPI fisico y denuncia preliminar. Si no hay coincidencia,
explica que no prueba ausencia de riesgo. Incluye solo hechos redactados.
''';
  }
}
