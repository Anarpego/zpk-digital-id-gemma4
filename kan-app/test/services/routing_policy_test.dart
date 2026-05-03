import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/routing_policy.dart';

void main() {
  final policy = RoutingPolicy();

  test('invalid CUI stays in local tools', () {
    final decision = policy.decide(
      result: LocalBreachCatalog().verify('123'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(decision.route, InferenceRoute.localTools);
    expect(decision.sendsPersonalData, isFalse);
    expect(decision.confidence, greaterThan(0.95));
  });

  test('exposed CUI routes to local model candidate', () {
    final decision = policy.decide(
      result: LocalBreachCatalog().verify('1234567890101'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(decision.route, InferenceRoute.localGemma);
    expect(decision.sendsPersonalData, isFalse);
    expect(decision.confidence, greaterThan(0.90));
  });

  test('suspicion without local match stays on local model route', () {
    final decision = policy.decide(
      result: LocalBreachCatalog().verify('1111111111111'),
      scenario: CaseScenario.suspicion,
    );

    expect(decision.route, InferenceRoute.localGemma);
    expect(decision.sendsPersonalData, isFalse);
    expect(decision.confidence, greaterThan(0.70));
  });

  test('institutional scale cases stay on local Gemma route', () {
    for (final scenario in [
      CaseScenario.publicServiceBreach,
      CaseScenario.igssRegistration,
      CaseScenario.satTaxAccess,
      CaseScenario.schoolEnrollment,
      CaseScenario.fieldAccess,
      CaseScenario.violenceCoercion,
    ]) {
      final decision = policy.decide(
        result: LocalBreachCatalog().verify('1111111111111'),
        scenario: scenario,
      );

      expect(decision.route, InferenceRoute.localGemma);
      expect(decision.sendsPersonalData, isFalse);
    }
  });

  test('institution intake can run without CUI', () {
    final decision = policy.decide(
      result: LocalBreachCatalog().verify(''),
      scenario: CaseScenario.igssRegistration,
    );

    expect(decision.route, InferenceRoute.localGemma);
    expect(decision.sendsPersonalData, isFalse);
    expect(decision.reason, contains('sin emitir credencial real'));
  });
}
