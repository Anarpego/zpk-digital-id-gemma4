import '../models/kan_case.dart';

class RoutingPolicy {
  const RoutingPolicy({
    this.localConfidenceFloor = 0.80,
    this.serverEscalationFloor = 0.70,
  });

  final double localConfidenceFloor;
  final double serverEscalationFloor;

  RoutingDecision decide({
    required VerificationResult result,
    required CaseScenario scenario,
  }) {
    if (!result.isValidCui) {
      return const RoutingDecision(
        route: InferenceRoute.localTools,
        confidence: 0.99,
        reason: 'Formato invalido; no hace falta modelo.',
        sendsPersonalData: false,
      );
    }

    if (result.isExposed) {
      return const RoutingDecision(
        route: InferenceRoute.localGemma,
        confidence: 0.92,
        reason:
            'Hay coincidencia local; el caso puede explicarse en el dispositivo.',
        sendsPersonalData: false,
      );
    }

    if (scenario == CaseScenario.suspicion) {
      return const RoutingDecision(
        route: InferenceRoute.abstractServer,
        confidence: 0.66,
        reason:
            'No hay coincidencia local, pero el usuario reporta indicios; conviene razonamiento abstracto sin CUI.',
        sendsPersonalData: false,
      );
    }

    return const RoutingDecision(
      route: InferenceRoute.localTools,
      confidence: 0.84,
      reason:
          'Verificacion preventiva sin coincidencias; las herramientas locales bastan.',
      sendsPersonalData: false,
    );
  }
}
