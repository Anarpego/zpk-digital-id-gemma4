enum CaseScenario {
  discoveredVictim,
  extortionThreat,
  remittanceFraud,
  publicServiceBreach,
  igssRegistration,
  satTaxAccess,
  schoolEnrollment,
  fieldAccess,
  violenceCoercion,
  suspicion,
  preventive,
}

extension CaseScenarioLabel on CaseScenario {
  String get label => switch (this) {
    CaseScenario.discoveredVictim => 'Ya fui afectado',
    CaseScenario.extortionThreat => 'Amenaza/extorsion',
    CaseScenario.remittanceFraud => 'Estafa economica',
    CaseScenario.publicServiceBreach => 'Tramite publico',
    CaseScenario.igssRegistration => 'Registro IGSS',
    CaseScenario.satTaxAccess => 'Acceso SAT',
    CaseScenario.schoolEnrollment => 'Colegio/universidad',
    CaseScenario.fieldAccess => 'Salud/escuela',
    CaseScenario.violenceCoercion => 'Riesgo violencia',
    CaseScenario.suspicion => 'Tengo sospechas',
    CaseScenario.preventive => 'Preventivo',
  };

  String get shortCode => switch (this) {
    CaseScenario.discoveredVictim => 'victim',
    CaseScenario.extortionThreat => 'extortion',
    CaseScenario.remittanceFraud => 'economic_fraud',
    CaseScenario.publicServiceBreach => 'public_service_recovery',
    CaseScenario.igssRegistration => 'igss_registration',
    CaseScenario.satTaxAccess => 'sat_tax_access',
    CaseScenario.schoolEnrollment => 'school_enrollment',
    CaseScenario.fieldAccess => 'field_access',
    CaseScenario.violenceCoercion => 'violence_coercion',
    CaseScenario.suspicion => 'suspicion',
    CaseScenario.preventive => 'preventive',
  };

  String get mission => switch (this) {
    CaseScenario.discoveredVictim =>
      'Recuperar identidad despues de una filtracion o tramite no reconocido.',
    CaseScenario.extortionThreat =>
      'Preservar evidencia y separar identidad real de un paquete de denuncia.',
    CaseScenario.remittanceFraud =>
      'Reducir dano economico por prestamos, empleo, remesas o SIM swap.',
    CaseScenario.publicServiceBreach =>
      'Recuperar acceso a un tramite publico despues de brecha, caida o registro no reconocido.',
    CaseScenario.igssRegistration =>
      'Preparar registro, recuperacion o validacion ante IGSS con prueba minima y checklist presencial.',
    CaseScenario.satTaxAccess =>
      'Preparar acceso, actualizacion o bloqueo preventivo SAT sin compartir documentos completos por canales inseguros.',
    CaseScenario.schoolEnrollment =>
      'Preparar inscripcion educativa o validacion de estudiante con prueba limitada y consentimiento local.',
    CaseScenario.fieldAccess =>
      'Emitir prueba limitada para salud, escuela o ayuda en campo sin internet estable.',
    CaseScenario.violenceCoercion =>
      'Proteger a una persona bajo coercion, preservar evidencia y pedir apoyo sin exponer ubicacion o documentos.',
    CaseScenario.suspicion =>
      'Triar indicios sin enviar CUI ni documentos a la nube.',
    CaseScenario.preventive =>
      'Crear una credencial local y revisar riesgo antes de compartir DPI.',
  };

  bool get allowsNoCui => switch (this) {
    CaseScenario.igssRegistration ||
    CaseScenario.satTaxAccess ||
    CaseScenario.schoolEnrollment => true,
    _ => false,
  };

  String get institutionName => switch (this) {
    CaseScenario.igssRegistration => 'IGSS',
    CaseScenario.satTaxAccess => 'SAT',
    CaseScenario.schoolEnrollment => 'colegio o universidad',
    CaseScenario.publicServiceBreach => 'institucion publica',
    CaseScenario.fieldAccess => 'escuela, clinica o brigada',
    CaseScenario.remittanceFraud => 'banco, telefonia o remesadora',
    CaseScenario.extortionThreat => 'institucion de apoyo',
    CaseScenario.violenceCoercion => 'red de apoyo presencial',
    _ => 'institucion autorizada',
  };
}

class BreachRecord {
  const BreachRecord({
    required this.slug,
    required this.name,
    required this.exposedFields,
    required this.reportedOn,
  });

  final String slug;
  final String name;
  final List<String> exposedFields;
  final DateTime reportedOn;
}

class VerificationResult {
  const VerificationResult({
    required this.cui,
    required this.matches,
    required this.checkedAt,
    this.catalogSource = 'memory',
  });

  final String cui;
  final List<BreachRecord> matches;
  final DateTime checkedAt;
  final String catalogSource;

  bool get isValidCui => cui.length == 13;
  bool get isExposed => matches.isNotEmpty;
}

class ReasonedGuidance {
  const ReasonedGuidance({
    required this.summary,
    required this.nextSteps,
    required this.toolTrace,
    required this.usedLocalOnly,
    required this.routingDecision,
  });

  final String summary;
  final List<String> nextSteps;
  final List<String> toolTrace;
  final bool usedLocalOnly;
  final RoutingDecision routingDecision;

  ReasonedGuidance copyWith({
    String? summary,
    List<String>? nextSteps,
    List<String>? toolTrace,
    bool? usedLocalOnly,
    RoutingDecision? routingDecision,
  }) {
    return ReasonedGuidance(
      summary: summary ?? this.summary,
      nextSteps: nextSteps ?? this.nextSteps,
      toolTrace: toolTrace ?? this.toolTrace,
      usedLocalOnly: usedLocalOnly ?? this.usedLocalOnly,
      routingDecision: routingDecision ?? this.routingDecision,
    );
  }
}

enum InferenceRoute { localTools, localGemma, abstractServer }

extension InferenceRouteLabel on InferenceRoute {
  String get label => switch (this) {
    InferenceRoute.localTools => 'Herramientas locales',
    InferenceRoute.localGemma => 'Modelo local',
    InferenceRoute.abstractServer => 'Servidor sin PII',
  };

  String get traceCode => switch (this) {
    InferenceRoute.localTools => 'local_tools',
    InferenceRoute.localGemma => 'local_model',
    InferenceRoute.abstractServer => 'abstract_server',
  };
}

class RoutingDecision {
  const RoutingDecision({
    required this.route,
    required this.confidence,
    required this.reason,
    required this.sendsPersonalData,
  });

  final InferenceRoute route;
  final double confidence;
  final String reason;
  final bool sendsPersonalData;

  String get trace =>
      'routing_decision(${route.traceCode}) -> confidence ${(confidence * 100).round()}%, pii ${sendsPersonalData ? 'yes' : 'no'}';
}
