import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'routing_policy.dart';

class MockReasoner implements KanReasoner {
  const MockReasoner({
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
  });

  final RoutingPolicy routingPolicy;
  final IdentityProtectionAgent agent;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = const DigitalIdentityFabric().evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final routing = assessment.route;

    if (!result.isValidCui) {
      return ReasonedGuidance(
        summary:
            'El agente bloqueo el caso porque el CUI debe tener 13 digitos. No se consulto ningun servidor.',
        nextSteps: const [
          'Revise el numero en su DPI.',
          'Intente de nuevo sin espacios ni guiones.',
        ],
        toolTrace: [...assessment.toolTrace, ...trustReport.trace],
        usedLocalOnly: true,
        routingDecision: routing,
      );
    }

    final trace = [
      ...assessment.toolTrace,
      ...trustReport.trace,
      'select_legal_flow(local, ${scenario.shortCode})',
      'apply_experience_prior(tf-grpo) -> ${ReasonerPromptBuilder.experiencePrior.length} reglas',
      'gemma_agent_context(redacted) -> national_identity_playbook',
      'fill_legal_template(local) -> ready',
    ];

    if (!result.isExposed) {
      return ReasonedGuidance(
        summary:
            'No encontramos este CUI en el catalogo local de brechas sinteticas. Esto no prueba ausencia de riesgo: el agente deja un plan preventivo que puede operar por municipio, institucion o pais sin centralizar CUI.',
        nextSteps: const [
          'Active alertas en banco y correo.',
          'No comparta foto de DPI por WhatsApp.',
          'Reporte nuevos indicios para actualizar catalogos comunitarios sin guardar identificadores completos.',
        ],
        toolTrace: trace,
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
      toolTrace: trace,
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }
}
