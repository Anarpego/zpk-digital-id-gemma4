import '../models/kan_case.dart';
import 'kan_reasoner.dart';
import 'routing_policy.dart';

class MockReasoner implements KanReasoner {
  const MockReasoner({this.routingPolicy = const RoutingPolicy()});

  final RoutingPolicy routingPolicy;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    final routing = routingPolicy.decide(result: result, scenario: scenario);

    if (!result.isValidCui) {
      return ReasonedGuidance(
        summary:
            'El CUI debe tener 13 digitos. No se consulto ningun servidor.',
        nextSteps: const [
          'Revise el numero en su DPI.',
          'Intente de nuevo sin espacios ni guiones.',
        ],
        toolTrace: ['validate_cui(local) -> invalid', routing.trace],
        usedLocalOnly: true,
        routingDecision: routing,
      );
    }

    final trace = [
      'load_breach_catalog(${result.catalogSource}) -> ok',
      'verify_dpi_in_local_leaks(local) -> ${result.matches.length} coincidencias',
      routing.trace,
      'select_legal_flow(local, ${scenario.shortCode})',
      'apply_experience_prior(tf-grpo) -> ${ReasonerPromptBuilder.experiencePrior.length} reglas',
      'fill_legal_template(local) -> ready',
    ];

    if (!result.isExposed) {
      return ReasonedGuidance(
        summary:
            'No encontramos este CUI en el catalogo local de brechas sinteticas. Esto no prueba que no exista riesgo, pero hoy no hay coincidencia aqui.',
        nextSteps: const [
          'Active alertas en banco y correo.',
          'No comparta foto de DPI por WhatsApp.',
          'Vuelva a revisar cuando el catalogo se actualice.',
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
          'Coincidencia encontrada. Sus datos pueden incluir: $fields. Kan puede preparar una denuncia inicial sin enviar su CUI al servidor.',
      nextSteps: const [
        'Guarde capturas o mensajes sospechosos.',
        'Lleve DPI fisico y una copia de la denuncia al Ministerio Publico.',
        'Pida bloqueo preventivo si detecta creditos o cuentas no reconocidas.',
      ],
      toolTrace: trace,
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }
}
