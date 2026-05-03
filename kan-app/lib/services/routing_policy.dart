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
      if (scenario.allowsNoCui) {
        return const RoutingDecision(
          route: InferenceRoute.localGemma,
          confidence: 0.86,
          reason:
              'El usuario no tiene CUI a mano; el agente prepara checklist e intake institucional sin emitir credencial real.',
          sendsPersonalData: false,
        );
      }
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

    if (scenario == CaseScenario.extortionThreat ||
        scenario == CaseScenario.remittanceFraud ||
        scenario == CaseScenario.publicServiceBreach ||
        scenario == CaseScenario.igssRegistration ||
        scenario == CaseScenario.satTaxAccess ||
        scenario == CaseScenario.schoolEnrollment ||
        scenario == CaseScenario.fieldAccess ||
        scenario == CaseScenario.violenceCoercion) {
      return const RoutingDecision(
        route: InferenceRoute.localGemma,
        confidence: 0.90,
        reason:
            'El caso puede implicar violencia o perdida economica; el agente razona localmente y prepara un paquete seguro.',
        sendsPersonalData: false,
      );
    }

    if (scenario == CaseScenario.suspicion) {
      return const RoutingDecision(
        route: InferenceRoute.localGemma,
        confidence: 0.78,
        reason:
            'No hay coincidencia local, pero el usuario reporta indicios; Gemma local puede ordenar pasos sin red.',
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
