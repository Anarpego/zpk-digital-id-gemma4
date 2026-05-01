import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('classifies exposed identity cases and blocks PII remote routing', () {
    final result = LocalBreachCatalog().verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );

    expect(assessment.riskLevel, IdentityRiskLevel.critical);
    expect(assessment.route.sendsPersonalData, isFalse);
    expect(
      assessment.toolTrace,
      contains('select_privacy_route(local_model) -> pii_block_ok'),
    );
    expect(assessment.toPromptBlock(), contains('plan_guatemala'));
    expect(assessment.toPromptBlock(), contains('patron_latam'));
  });
}
