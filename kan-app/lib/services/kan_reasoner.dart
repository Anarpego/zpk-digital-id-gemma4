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
- pseudonimo_ciudadano: ${trustReport.credential.pseudonymousId}
- nivel_aseguramiento: ${trustReport.credential.assuranceLevel}
- consentimiento: ${trustReport.consentGrant.scope}
- prueba_local: ${trustReport.consentGrant.localProof}
- did_local: ${trustReport.didDocument['id']}
- credencial_verificable_demo: ${trustReport.verifiableCredential['type']}
- divulgacion_selectiva: ${trustReport.selectiveDisclosureClaims.join(', ')}
- recuperacion: ${trustReport.recoveryStatus}
- paquete_institucional:
${trustReport.institutionPacket.map((item) => '  - $item').join('\n')}

Caso:
- flujo: ${scenario.label}
- cui_valido: ${result.isValidCui}
- coincidencias_locales: ${result.matches.length}
- brechas:
${matches.isEmpty ? 'ninguna' : matches}

Responde en espanol claro. No inventes instituciones. No pidas mas datos
personales. Si hay coincidencia, recomienda evidencia, DPI fisico y denuncia
preliminar. Si no hay coincidencia, explica que no prueba ausencia de riesgo.
Incluye solo hechos redactados, pasos accionables y una nota de escala nacional.
''';
  }
}
