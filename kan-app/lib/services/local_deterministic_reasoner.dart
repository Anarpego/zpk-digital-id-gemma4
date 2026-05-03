import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class LocalDeterministicReasoner implements KanReasoner, ReasonerRuntimeProbe {
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
  Future<ReasonerRuntimeStatus>
  runtimeStatus() async => const ReasonerRuntimeStatus(
    label: 'Agente local ZPK',
    state: 'READY',
    summary:
        'Motor offline listo: validacion CUI, catalogo local, trust fabric, denuncia y auditoria sin red.',
    isOfflineCapable: true,
    isModelBacked: false,
    trace: [
      'runtime.local_deterministic -> ready',
      'runtime.network_required -> false',
      'runtime.model_backed -> false',
    ],
  );

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

    if (!result.isValidCui && !scenario.allowsNoCui) {
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
      'local_agent_context(redacted) -> national_identity_playbook',
      'fill_legal_template(local) -> ready',
    ];
    final signedLedgerTrace = await ledgerTrace(usedLocalOnly: true);

    if (!result.isExposed) {
      return ReasonedGuidance(
        summary: _noExposureSummary(scenario),
        nextSteps: _noExposureSteps(scenario),
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
          'Coincidencia encontrada. Sus datos pueden incluir: $fields. ZPK Digital ID actua como agente de registro y recuperacion: verifica localmente, emite una credencial pseudonima, bloquea PII remota y prepara el paquete correcto para ${scenario.mission.toLowerCase()}',
      nextSteps: _exposedSteps(scenario),
      toolTrace: [...trace, ...signedLedgerTrace],
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }

  List<String> _noExposureSteps(CaseScenario scenario) => switch (scenario) {
    CaseScenario.extortionThreat => const [
      'Guarde capturas, audios, numeros y hora sin responder ni confrontar.',
      'Use el paquete redactado para pedir apoyo presencial o institucional sin exponer CUI completo.',
      'Si hay peligro inmediato, priorice seguridad fisica y contacto con autoridades locales.',
    ],
    CaseScenario.remittanceFraud => const [
      'Conserve comprobantes, numeros de cuenta, chats y recibos.',
      'Avise a banco, remesadora o telefonia para bloquear movimientos no reconocidos.',
      'Comparta solo el paquete firmado y redactado con la institucion que revisara el caso.',
    ],
    CaseScenario.publicServiceBreach => const [
      'Guarde el numero de tramite, fecha y pantalla de error o registro no reconocido.',
      'Pida revision con el paquete redactado y lleve DPI fisico solo si la institucion lo requiere en persona.',
      'No envie fotos completas de documentos por chat o correo informal.',
    ],
    CaseScenario.igssRegistration => const [
      'Prepare DPI fisico, constancia laboral o referencia de patrono solo para ventanilla oficial.',
      'Use el paquete de intake para explicar el caso sin enviar foto completa de documentos por chat.',
      'Pida numero de seguimiento y guarde el recibo local firmado.',
    ],
    CaseScenario.satTaxAccess => const [
      'Entre solo por portal o ventanilla oficial; no entregue codigos ni foto de DPI por mensajeria.',
      'Use el paquete redactado para pedir recuperacion, actualizacion o bloqueo preventivo.',
      'Cambie correo y claves desde un dispositivo confiable cuando vuelva la conectividad.',
    ],
    CaseScenario.schoolEnrollment => const [
      'Prepare constancia de estudiante o responsable sin subir documentos completos.',
      'Use la prueba limitada para que el centro educativo revise presencia y consentimiento.',
      'Pida que no quede copia completa del DPI en telefonos personales del personal.',
    ],
    CaseScenario.fieldAccess => const [
      'Genere una prueba limitada para escuela, salud o ayuda sin copiar el DPI completo.',
      'Use el recibo offline para que la institucion verifique presencia y consentimiento.',
      'Actualice la prueba cuando vuelva la conectividad, sin subir identificadores crudos.',
    ],
    CaseScenario.violenceCoercion => const [
      'Priorice seguridad fisica y no confronte a la persona agresora desde la app.',
      'Preserve evidencia local y comparta solo un resumen seguro con apoyo presencial de confianza.',
      'Evite publicar ubicacion, documentos o capturas con datos completos.',
    ],
    CaseScenario.suspicion => const [
      'Guarde indicios y repita la revision si aparecen nuevos mensajes o cargos.',
      'No envie foto de DPI ni codigos por chat.',
      'Use la prueba local para autenticarte sin entregar CUI completo.',
    ],
    CaseScenario.preventive => const [
      'Active alertas en banco y correo.',
      'No comparta foto de DPI por WhatsApp.',
      'Use credenciales pseudonimas para tramites que no necesitan CUI completo.',
    ],
    CaseScenario.discoveredVictim => const [
      'Prepare evidencia redactada aunque no haya coincidencia local.',
      'Revise banco, telefonia y correo por movimientos no reconocidos.',
      'Actualice catalogos comunitarios sin guardar identificadores completos.',
    ],
  };

  String _noExposureSummary(CaseScenario scenario) {
    if (scenario.allowsNoCui) {
      return 'Modo ciudadano sin CUI a mano. El agente ejecuta "${scenario.label}" para preparar checklist, paquete redactado e instrucciones de ventanilla para ${scenario.institutionName}, sin emitir una credencial de identidad ni consultar servidores.';
    }
    return 'No encontramos este CUI en el catalogo local de brechas sinteticas. Esto no prueba ausencia de riesgo: el agente ejecuta el flujo "${scenario.label}" para ${scenario.mission.toLowerCase()} sin consultar servidores.';
  }

  List<String> _exposedSteps(CaseScenario scenario) => switch (scenario) {
    CaseScenario.extortionThreat => const [
      'Preserve evidencia en el archivo cifrado local.',
      'No confronte al agresor ni comparta ubicacion o documentos por chat.',
      'Use la denuncia redactada y el DPI fisico para apoyo institucional.',
      'Revoque la credencial local si sospecha control de cuenta o telefono.',
    ],
    CaseScenario.remittanceFraud => const [
      'Pida bloqueo preventivo de creditos, cuentas o SIM asociados.',
      'Prepare comprobantes de remesa, empleo o prestamo sospechoso.',
      'Comparta solo hechos redactados con banco, telefonia o institucion financiera.',
      'Emita una prueba local nueva despues de revocar la anterior.',
    ],
    CaseScenario.publicServiceBreach => const [
      'Prepare solicitud de revision para la institucion con CUI redactado.',
      'Use la prueba de presencia local para demostrar control del dispositivo sin enviar documentos completos.',
      'Pida bloqueo o correccion del tramite no reconocido.',
      'Conserve el recibo de auditoria local para seguimiento.',
    ],
    CaseScenario.igssRegistration => const [
      'Lleve DPI fisico y documentos laborales solo a canal oficial IGSS.',
      'Entregue el resumen redactado para abrir o recuperar el expediente sin copiar todo el documento.',
      'Pida numero de gestion y registre el seguimiento en el archivo local.',
      'Revoque la prueba local si el telefono queda en manos de otra persona.',
    ],
    CaseScenario.satTaxAccess => const [
      'Use canal oficial SAT para recuperar acceso, actualizar correo o bloquear actividad sospechosa.',
      'Comparta solo el paquete redactado y el hash firmado, no codigos ni documento completo.',
      'Revise NIT, correo y movimientos recientes desde una conexion confiable.',
      'Guarde el recibo local para auditoria y seguimiento.',
    ],
    CaseScenario.schoolEnrollment => const [
      'Presente el paquete limitado al colegio o universidad para revision de inscripcion.',
      'Mantenga documentos completos solo en ventanilla formal o con el encargado autorizado.',
      'Pida que el centro registre consentimiento y no replique fotos de documentos.',
      'Actualice o revoque la prueba cuando cierre el tramite.',
    ],
    CaseScenario.fieldAccess => const [
      'Emita credencial local limitada para el servicio solicitado.',
      'Comparta solo el QR o paquete redactado con la escuela, clinica o brigada.',
      'Revise que no quede copia completa del DPI en el dispositivo de la institucion.',
      'Registre auditoria local de consentimiento.',
    ],
    CaseScenario.violenceCoercion => const [
      'Cierre cualquier sesion o cuenta que la otra persona controle.',
      'Preserve evidencia en el archivo cifrado local.',
      'Comparta solo resumen seguro con apoyo presencial de confianza.',
      'Use revocacion local si sospecha que el telefono o la cuenta fueron comprometidos.',
    ],
    _ => const [
      'Guarde capturas o mensajes sospechosos.',
      'Lleve DPI fisico y una copia de la denuncia al Ministerio Publico.',
      'Pida bloqueo preventivo si detecta creditos o cuentas no reconocidas.',
      'Comparta solo hechos redactados si una institucion nacional o aliado regional necesita apoyar.',
    ],
  };
}
