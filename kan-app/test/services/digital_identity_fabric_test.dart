import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/digital_identity_fabric.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('builds a local-only trust packet without exposing raw CUI', () {
    final result = LocalBreachCatalog().verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final report = const DigitalIdentityFabric().evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );

    expect(report.credential.pseudonymousId, startsWith('zpk-gt-'));
    expect(report.credential.pseudonymousId, isNot(contains(result.cui)));
    expect(report.didDocument['id'], startsWith('did:zpk:gt:zpk-gt-'));
    expect(
      report.verifiableCredential.toString(),
      contains('LocalDeterministicProof'),
    );
    expect(
      report.selectiveDisclosureClaims.join('\n'),
      isNot(contains(result.cui)),
    );
    expect(report.consentGrant.expiresInMinutes, 15);
    expect(report.institutionPacket.join('\n'), isNot(contains(result.cui)));
    expect(
      report.trace,
      contains('trust_fabric.vc_selective_disclosure(local) -> 1_matches'),
    );
    expect(
      report.trace,
      contains('trust_fabric.issue_consent(local, 15m) -> ok'),
    );
  });
}
