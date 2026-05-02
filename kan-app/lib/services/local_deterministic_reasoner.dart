import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class LocalDeterministicReasoner implements KanReasoner {
  const LocalDeterministicReasoner({
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  });

  final RoutingPolicy routingPolicy;
  final IdentityProtectionAgent agent;
  final DigitalIdentityFabric identityFabric;
  final PrivacyGuard privacyGuard;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final privacyReport = privacyGuard.requireRedactedModelPrompt(
      prompt: assessment.toPromptBlock(),
      result: result,
    );
    final routing = assessment.route;
    Future<List<String>> ledgerTrace({required bool usedLocalOnly}) async {
      final ledger =
          await AgentExecutionLedgerService(
            identityFabric: identityFabric,
          ).build(
            assessment: assessment,
            trustReport: trustReport,
            result: result,
            scenario: scenario,
            reasonerLabel: 'local-deterministic',
            usedLocalOnly: usedLocalOnly,
          );
      return ledger.trace;
    }

    if (!result.isValidCui) {
      return ReasonedGuidance(
        summary:
            'El agente bloqueo el caso porque el CUI debe tener 13 digitos. No se consulto ningun servidor.',
        nextSteps: const [
          'Revise el numero en su DPI.',
          'Intente de nuevo sin espacios ni guiones.',
        ],
        toolTrace: [
          ...assessment.toolTrace,
          ...trustReport.trace,
          ...privacyReport.trace,
          ...await ledgerTrace(usedLocalOnly: true),
        ],
        usedLocalOnly: true,
        routingDecision: routing,
      );
    }

    final trace = [
      ...assessment.toolTrace,
      ...trustReport.trace,
      ...privacyReport.trace,
      'select_legal_flow(local, ${scenario.shortCode})',
      'apply_experience_prior(tf-grpo) -> ${ReasonerPromptBuilder.experiencePrior.length} reglas',
      'gemma_agent_context(redacted) -> national_identity_playbook',
      'fill_legal_template(local) -> ready',
    ];
    final signedLedgerTrace = await ledgerTrace(usedLocalOnly: true);

    if (!result.isExposed) {
      return ReasonedGuidance(
        summary:
            'No encontramos este CUI en el catalogo local de brechas sinteticas. Esto no prueba ausencia de riesgo: el agente deja un plan preventivo que puede operar por municipio, institucion o pais sin centralizar CUI.',
        nextSteps: const [
          'Active alertas en banco y correo.',
          'No comparta foto de DPI por WhatsApp.',
          'Reporte nuevos indicios para actualizar catalogos comunitarios sin guardar identificadores completos.',
        ],
        toolTrace: [...trace, ...signedLedgerTrace],
        usedLocalOnly: true,
        routingDecision: routing,
      );
    }

    final fields = result.matches
        .expand((record) => record.exposedFields)
        .toSet()
        .join(', ');

    return ReasonedGuidance(
      summary:
          'Coincidencia encontrada. Sus datos pueden incluir: $fields. ZPK Digital ID actua como agente de registro y recuperacion: verifica localmente, emite una credencial pseudonima, bloquea PII remota y prepara una denuncia inicial para escalar el caso en Guatemala sin enviar el CUI al servidor.',
      nextSteps: const [
        'Guarde capturas o mensajes sospechosos.',
        'Lleve DPI fisico y una copia de la denuncia al Ministerio Publico.',
        'Pida bloqueo preventivo si detecta creditos o cuentas no reconocidas.',
        'Comparta solo hechos redactados si una institucion nacional o aliado regional necesita apoyar.',
      ],
      toolTrace: [...trace, ...signedLedgerTrace],
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }
}
