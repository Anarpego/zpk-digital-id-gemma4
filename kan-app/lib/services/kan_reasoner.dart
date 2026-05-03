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

abstract interface class ReasonerRuntimeProbe {
  Future<ReasonerRuntimeStatus> runtimeStatus();
}

abstract interface class ReasonerRuntimeInstaller {
  Future<ReasonerRuntimeInstallResult> installRuntimeAssets();
}

abstract interface class ReasonerRuntimeSelfTester {
  Future<ReasonerRuntimeSelfTestResult> runRuntimeSelfTest();
}

class ReasonerRuntimeStatus {
  const ReasonerRuntimeStatus({
    required this.label,
    required this.state,
    required this.summary,
    required this.isOfflineCapable,
    required this.isModelBacked,
    required this.trace,
    this.downloadedBytes,
    this.totalBytes,
  });

  final String label;
  final String state;
  final String summary;
  final bool isOfflineCapable;
  final bool isModelBacked;
  final List<String> trace;
  final int? downloadedBytes;
  final int? totalBytes;
}

class ReasonerRuntimeSelfTestResult {
  const ReasonerRuntimeSelfTestResult({
    required this.label,
    required this.status,
    required this.summary,
    required this.trace,
  });

  final String label;
  final String status;
  final String summary;
  final List<String> trace;
}

class ReasonerRuntimeInstallResult {
  const ReasonerRuntimeInstallResult({
    required this.label,
    required this.status,
    required this.summary,
    required this.trace,
    this.downloadedBytes,
    this.totalBytes,
  });

  final String label;
  final String status;
  final String summary;
  final List<String> trace;
  final int? downloadedBytes;
  final int? totalBytes;
}

class FallbackReasoner
    implements
        KanReasoner,
        ReasonerRuntimeProbe,
        ReasonerRuntimeInstaller,
        ReasonerRuntimeSelfTester {
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

  @override
  Future<ReasonerRuntimeStatus> runtimeStatus() async {
    if (primary case final ReasonerRuntimeProbe probe) {
      try {
        final status = await probe.runtimeStatus().timeout(
          const Duration(seconds: 6),
        );
        final fallbackStatus = await _fallbackRuntimeStatus();
        final fallbackReady =
            fallbackStatus != null && fallbackStatus.isOfflineCapable;
        final primaryReady = status.isOfflineCapable;
        final includeFallback = !primaryReady && fallbackStatus != null;
        return ReasonerRuntimeStatus(
          label: status.label,
          state: status.state,
          summary: includeFallback && fallbackReady
              ? '${status.summary} Respaldo offline disponible: ${fallbackStatus.summary}'
              : status.summary,
          isOfflineCapable: primaryReady || fallbackReady,
          isModelBacked: status.isModelBacked,
          trace: [
            'reasoner_runtime($primaryLabel) -> ${status.state}',
            ...status.trace,
            if (includeFallback) ...fallbackStatus.trace,
          ],
          downloadedBytes: status.downloadedBytes,
          totalBytes: status.totalBytes,
        );
      } catch (error) {
        final fallbackStatus =
            await _fallbackRuntimeStatus() ??
            const ReasonerRuntimeStatus(
              label: 'Local fallback',
              state: 'READY',
              summary: 'Agente local disponible como respaldo.',
              isOfflineCapable: true,
              isModelBacked: false,
              trace: ['reasoner_runtime(fallback) -> ready'],
            );
        final detail = _describeError(error);
        return ReasonerRuntimeStatus(
          label: primaryLabel,
          state: 'PRIMARY_NOT_READY',
          summary:
              'Gemma 4 todavia no esta listo: $detail. Respaldo disponible: ${fallbackStatus.summary}',
          isOfflineCapable: fallbackStatus.isOfflineCapable,
          isModelBacked: true,
          trace: [
            'reasoner_runtime($primaryLabel) -> primary_not_ready: $detail',
            ...fallbackStatus.trace,
          ],
        );
      }
    }
    if (fallback case final ReasonerRuntimeProbe probe) {
      return probe.runtimeStatus();
    }
    return const ReasonerRuntimeStatus(
      label: 'Agente local',
      state: 'READY',
      summary: 'Agente local disponible.',
      isOfflineCapable: true,
      isModelBacked: false,
      trace: ['reasoner_runtime(local) -> ready'],
    );
  }

  Future<ReasonerRuntimeStatus?> _fallbackRuntimeStatus() async {
    if (fallback case final ReasonerRuntimeProbe probe) {
      return probe.runtimeStatus();
    }
    return null;
  }

  @override
  Future<ReasonerRuntimeInstallResult> installRuntimeAssets() async {
    if (primary case final ReasonerRuntimeInstaller installer) {
      return installer.installRuntimeAssets();
    }
    return const ReasonerRuntimeInstallResult(
      label: 'Agente local ZPK',
      status: 'NOT_REQUIRED',
      summary: 'El motor local deterministico no necesita instalar modelo.',
      trace: ['reasoner_install(local) -> not_required'],
    );
  }

  @override
  Future<ReasonerRuntimeSelfTestResult> runRuntimeSelfTest() async {
    if (primary case final ReasonerRuntimeSelfTester selfTester) {
      return selfTester.runRuntimeSelfTest().timeout(timeout);
    }
    return const ReasonerRuntimeSelfTestResult(
      label: 'Agente local ZPK',
      status: 'NOT_SUPPORTED',
      summary: 'El motor actual no expone una prueba nativa de modelo.',
      trace: ['reasoner_self_test(local) -> not_supported'],
    );
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
El producto no es un chatbot general: decide rutas y ejecuta herramientas
locales para recuperacion de identidad, extorsion, fraude economico,
registro IGSS, acceso SAT, inscripcion educativa, autenticacion, revocacion y
auditoria cifrada.

Reglas aprendidas por experiencia:
${experiencePrior.map((rule) => '- $rule').join('\n')}

${assessment.toPromptBlock()}

Infraestructura local de identidad:
- emisor_local: ${trustReport.credential.issuer}
- pseudonimo_ciudadano: emitido_localmente
- nivel_aseguramiento: ${trustReport.credential.assuranceLevel}
- consentimiento: ${trustReport.consentGrant.scope}
- prueba_local: firmada_en_dispositivo
- did_local: did:zpk:gt:<redacted-local-id>
- credencial_verificable_local: ${trustReport.verifiableCredential['type']}
- divulgacion_selectiva: ${selectiveClaims.join(', ')}
- recuperacion: ${trustReport.recoveryStatus}
- paquete_institucional:
${institutionPacket.map((item) => '  - $item').join('\n')}

Caso:
- flujo: ${scenario.label}
- mision: ${scenario.mission}
- institucion_objetivo: ${scenario.institutionName}
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
