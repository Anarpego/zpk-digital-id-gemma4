enum CaseScenario { discoveredVictim, suspicion, preventive }

extension CaseScenarioLabel on CaseScenario {
  String get label => switch (this) {
    CaseScenario.discoveredVictim => 'Ya fui afectado',
    CaseScenario.suspicion => 'Tengo sospechas',
    CaseScenario.preventive => 'Verificacion preventiva',
  };

  String get shortCode => switch (this) {
    CaseScenario.discoveredVictim => 'victim',
    CaseScenario.suspicion => 'suspicion',
    CaseScenario.preventive => 'preventive',
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
