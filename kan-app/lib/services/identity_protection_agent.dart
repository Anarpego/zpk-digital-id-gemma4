import '../models/kan_case.dart';
import 'local_threat_bulletin_catalog.dart';
import 'routing_policy.dart';

enum IdentityRiskLevel { blocked, low, medium, high, critical }

extension IdentityRiskLevelLabel on IdentityRiskLevel {
  String get label => switch (this) {
    IdentityRiskLevel.blocked => 'Bloqueado',
    IdentityRiskLevel.low => 'Bajo',
    IdentityRiskLevel.medium => 'Medio',
    IdentityRiskLevel.high => 'Alto',
    IdentityRiskLevel.critical => 'Critico',
  };
}

class AgentToolCall {
  const AgentToolCall({
    required this.name,
    required this.input,
    required this.output,
  });

  final String name;
  final String input;
  final String output;

  String get trace => '$name($input) -> $output';
}

class IdentityAgentAssessment {
  const IdentityAgentAssessment({
    required this.riskLevel,
    required this.route,
    required this.toolCalls,
    required this.redactedFacts,
    required this.nationalPlaybook,
    required this.regionalPlaybook,
    required this.matchedBulletins,
  });

  final IdentityRiskLevel riskLevel;
  final RoutingDecision route;
  final List<AgentToolCall> toolCalls;
  final List<String> redactedFacts;
  final List<String> nationalPlaybook;
  final List<String> regionalPlaybook;
  final List<ThreatBulletinMatch> matchedBulletins;

  List<String> get toolTrace => [
    for (final call in toolCalls) call.trace,
    'agent.risk_level -> ${riskLevel.label}',
    route.trace,
  ];

  String toPromptBlock() {
    return '''
Agente ZPK de proteccion de identidad:
- nivel_riesgo: ${riskLevel.label}
- ruta_privacidad: ${route.route.traceCode}
- envia_datos_personales: ${route.sendsPersonalData}
- hechos_redactados:
${redactedFacts.map((fact) => '  - $fact').join('\n')}
- plan_guatemala:
${nationalPlaybook.map((step) => '  - $step').join('\n')}
- patron_latam:
${regionalPlaybook.map((step) => '  - $step').join('\n')}
- boletines_publicos_verificados:
${matchedBulletins.isEmpty ? '  - ninguno' : matchedBulletins.map((match) => '  - ${match.bulletin.id}: ${match.bulletin.riskPattern}, campos=${match.overlappingFields.join('+')}, accion=${match.bulletin.recommendedAction}').join('\n')}

Herramientas ejecutadas:
${toolCalls.map((call) => '- ${call.trace}').join('\n')}
''';
  }
}

class IdentityProtectionAgent {
  const IdentityProtectionAgent({
    this.routingPolicy = const RoutingPolicy(),
    this.threatCatalog = const LocalThreatBulletinCatalog(),
  });

  final RoutingPolicy routingPolicy;
  final LocalThreatBulletinCatalog threatCatalog;

  IdentityAgentAssessment assess({
    required VerificationResult result,
    required CaseScenario scenario,
  }) {
    final route = routingPolicy.decide(result: result, scenario: scenario);
    final risk = _riskLevel(result: result, scenario: scenario);
    final bulletinMatches = threatCatalog.match(
      result: result,
      scenario: scenario,
    );
    final exposedFields =
        result.matches.expand((match) => match.exposedFields).toSet().toList()
          ..sort();
    final matchNames = result.matches.map((match) => match.name).toList();
    final bulletinIds = bulletinMatches
        .map((match) => match.bulletin.id)
        .join(',');

    return IdentityAgentAssessment(
      riskLevel: risk,
      route: route,
      toolCalls: [
        AgentToolCall(
          name: 'agent.plan',
          input: scenario.shortCode,
          output:
              'validate_cui, local_breach_lookup, classify_identity_risk, preserve_evidence, select_privacy_route, prepare_action_packet',
        ),
        AgentToolCall(
          name: 'validate_cui',
          input: 'local_only',
          output: result.isValidCui
              ? 'valid_13_digits'
              : scenario.allowsNoCui
              ? 'not_available_checklist_only'
              : 'invalid_format',
        ),
        AgentToolCall(
          name: 'local_breach_lookup',
          input: result.catalogSource,
          output: '${result.matches.length}_matches',
        ),
        AgentToolCall(
          name: 'classify_identity_risk',
          input: exposedFields.isEmpty
              ? 'no_local_fields'
              : exposedFields.join('+'),
          output: risk.label,
        ),
        AgentToolCall(
          name: 'select_privacy_route',
          input: route.route.traceCode,
          output: route.sendsPersonalData ? 'pii_block_failed' : 'pii_block_ok',
        ),
        if (scenario == CaseScenario.extortionThreat)
          const AgentToolCall(
            name: 'preserve_evidence',
            input: 'threat_or_extortion',
            output: 'sealed_local_timeline+redacted_report',
          ),
        if (scenario == CaseScenario.remittanceFraud)
          const AgentToolCall(
            name: 'economic_fraud_triage',
            input: 'loan_remittance_employment_scam',
            output: 'freeze_checklist+institution_packet',
          ),
        if (scenario == CaseScenario.publicServiceBreach)
          const AgentToolCall(
            name: 'institution_recovery_packet',
            input: 'public_service_or_registry_breach',
            output: 'redacted_claim+presence_proof+review_request',
          ),
        if (scenario == CaseScenario.igssRegistration)
          const AgentToolCall(
            name: 'igss_registration_agent',
            input: 'social_security_registration_or_recovery',
            output: 'eligibility_checklist+presence_proof+institution_intake',
          ),
        if (scenario == CaseScenario.satTaxAccess)
          const AgentToolCall(
            name: 'sat_access_agent',
            input: 'tax_portal_access_or_update',
            output: 'portal_safety_check+redacted_update_packet',
          ),
        if (scenario == CaseScenario.schoolEnrollment)
          const AgentToolCall(
            name: 'education_enrollment_agent',
            input: 'school_or_university_registration',
            output: 'guardian_consent+limited_student_claim+institution_intake',
          ),
        if (scenario == CaseScenario.fieldAccess)
          const AgentToolCall(
            name: 'field_access_voucher',
            input: 'school_clinic_aid_without_connectivity',
            output: 'limited_claim+offline_qr+no_document_copy',
          ),
        if (scenario == CaseScenario.violenceCoercion)
          const AgentToolCall(
            name: 'coercion_safety_plan',
            input: 'identity_threat_with_personal_safety_risk',
            output: 'sealed_timeline+safe_contact_summary',
          ),
        AgentToolCall(
          name: 'threat_bulletin.verify',
          input: 'offline_hash_pack',
          output:
              '${threatCatalog.verifiedCount}/${threatCatalog.bulletins.length}_hash_ok',
        ),
        AgentToolCall(
          name: 'threat_bulletin.match',
          input: exposedFields.isEmpty
              ? scenario.shortCode
              : exposedFields.join('+'),
          output: bulletinIds.isEmpty ? 'no_public_context' : bulletinIds,
        ),
        for (final match in bulletinMatches)
          AgentToolCall(
            name: 'threat_bulletin.action',
            input: match.bulletin.riskPattern,
            output: match.bulletin.recommendedAction,
          ),
        AgentToolCall(
          name: 'prepare_action_packet',
          input: _actionPacketInput(scenario),
          output: result.isValidCui || scenario.allowsNoCui
              ? _actionPacketOutput(scenario)
              : 'format_help_only',
        ),
      ],
      redactedFacts: [
        'CUI completo nunca se envia al modelo remoto.',
        'coincidencias_locales=${result.matches.length}',
        if (matchNames.isNotEmpty) 'fuentes=${matchNames.join(', ')}',
        if (exposedFields.isNotEmpty) 'campos=${exposedFields.join(', ')}',
        if (bulletinMatches.isNotEmpty)
          'boletines=${bulletinMatches.map((match) => match.bulletin.id).join(',')}',
        'escenario=${scenario.label}',
        'mision=${scenario.mission}',
      ],
      nationalPlaybook: _nationalPlaybook(risk, bulletinMatches),
      regionalPlaybook: _regionalPlaybook(bulletinMatches),
      matchedBulletins: bulletinMatches,
    );
  }

  IdentityRiskLevel _riskLevel({
    required VerificationResult result,
    required CaseScenario scenario,
  }) {
    if (!result.isValidCui) {
      if (scenario.allowsNoCui) {
        return IdentityRiskLevel.medium;
      }
      return IdentityRiskLevel.blocked;
    }
    if (result.isExposed) {
      final fields = result.matches
          .expand((match) => match.exposedFields)
          .map((field) => field.toLowerCase())
          .toSet();
      final hasCredentialRisk = fields.any(
        (field) =>
            field.contains('dpi') ||
            field.contains('cui') ||
            field.contains('telefono') ||
            field.contains('direccion') ||
            field.contains('correo'),
      );
      return hasCredentialRisk
          ? IdentityRiskLevel.critical
          : IdentityRiskLevel.high;
    }
    if (scenario == CaseScenario.extortionThreat) {
      return IdentityRiskLevel.critical;
    }
    if (scenario == CaseScenario.remittanceFraud) {
      return result.isExposed
          ? IdentityRiskLevel.critical
          : IdentityRiskLevel.high;
    }
    if (scenario == CaseScenario.publicServiceBreach ||
        scenario == CaseScenario.igssRegistration ||
        scenario == CaseScenario.satTaxAccess ||
        scenario == CaseScenario.schoolEnrollment ||
        scenario == CaseScenario.fieldAccess) {
      return IdentityRiskLevel.high;
    }
    if (scenario == CaseScenario.violenceCoercion) {
      return IdentityRiskLevel.critical;
    }
    if (scenario == CaseScenario.suspicion) {
      return IdentityRiskLevel.medium;
    }
    return IdentityRiskLevel.low;
  }

  List<String> _nationalPlaybook(
    IdentityRiskLevel risk,
    List<ThreatBulletinMatch> bulletinMatches,
  ) {
    final baseline = switch (risk) {
      IdentityRiskLevel.blocked => const [
        'Corregir formato antes de cualquier consulta.',
        'No guardar ni transmitir identificadores incompletos.',
      ],
      IdentityRiskLevel.low => const [
        'Mantener verificacion preventiva local.',
        'Actualizar catalogo comunitario de alertas sin recolectar CUI.',
      ],
      IdentityRiskLevel.medium => const [
        'Recopilar evidencia del intento de fraude.',
        'Generar guia sin enviar CUI y sugerir denuncia si aparecen cargos o contratos.',
      ],
      IdentityRiskLevel.high || IdentityRiskLevel.critical => const [
        'Preparar paquete de denuncia con evidencia y DPI fisico.',
        'Recomendar alertas en banco, telefonia y servicios publicos.',
        'Escalar solo hechos redactados para orientacion nacional o regional.',
      ],
    };
    if (bulletinMatches.isEmpty) {
      return baseline;
    }
    return [
      ...baseline,
      for (final match in bulletinMatches)
        'Aplicar boletin ${match.bulletin.id}: ${match.bulletin.recommendedAction}',
    ];
  }

  String _actionPacketInput(CaseScenario scenario) => switch (scenario) {
    CaseScenario.extortionThreat => 'guatemala_extortion_evidence',
    CaseScenario.remittanceFraud => 'guatemala_economic_fraud_recovery',
    CaseScenario.publicServiceBreach => 'guatemala_public_service_recovery',
    CaseScenario.igssRegistration => 'guatemala_igss_registration',
    CaseScenario.satTaxAccess => 'guatemala_sat_access_update',
    CaseScenario.schoolEnrollment => 'guatemala_education_enrollment',
    CaseScenario.fieldAccess => 'guatemala_field_access_identity',
    CaseScenario.violenceCoercion => 'guatemala_coercion_safety_identity',
    _ => 'guatemala_identity_recovery',
  };

  String _actionPacketOutput(CaseScenario scenario) => switch (scenario) {
    CaseScenario.extortionThreat =>
      'safety_steps+sealed_evidence+redacted_complaint',
    CaseScenario.remittanceFraud =>
      'bank_telco_alerts+recovery_steps+institution_packet',
    CaseScenario.publicServiceBreach =>
      'registry_review_request+redacted_claim+presence_proof',
    CaseScenario.igssRegistration =>
      'igss_checklist+redacted_intake+appointment_packet',
    CaseScenario.satTaxAccess =>
      'sat_portal_safety+redacted_update_packet+counter_script',
    CaseScenario.schoolEnrollment =>
      'education_enrollment_checklist+guardian_consent+limited_claim',
    CaseScenario.fieldAccess =>
      'limited_offline_claim+service_counter_packet+audit_receipt',
    CaseScenario.violenceCoercion =>
      'safe_contact_summary+sealed_evidence+support_packet',
    _ => 'citizen_steps+complaint_template',
  };

  List<String> _regionalPlaybook(List<ThreatBulletinMatch> bulletinMatches) {
    return [
      'Reutilizar catalogos locales por pais sin centralizar identificadores.',
      'Cambiar plantillas legales por jurisdiccion manteniendo la misma politica de privacidad.',
      'Reportar solo metricas agregadas para instituciones publicas y organizaciones civiles.',
      if (bulletinMatches.any((match) => match.bulletin.region != 'Guatemala'))
        'Mantener boletines regionales hash-verificados para patrones que cruzan fronteras.',
    ];
  }
}
