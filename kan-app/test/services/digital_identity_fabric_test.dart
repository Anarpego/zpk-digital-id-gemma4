import 'package:flutter_test/flutter_test.dart';

import '../test_identity_fabric.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('builds a local-only trust packet without exposing raw CUI', () async {
    final result = LocalBreachCatalog().verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final report = await testIdentityFabric.evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );

    expect(report.credential.pseudonymousId, startsWith('zpk-gt-'));
    expect(report.credential.pseudonymousId, isNot(contains(result.cui)));
    expect(report.didDocument['id'], startsWith('did:zpk:gt:zpk-gt-'));
    expect(
      report.verifiableCredential.toString(),
      contains('HmacSha256Signature2026'),
    );
    expect(
      await testIdentityFabric.verifyCredential(
        verifiableCredential: report.verifiableCredential,
      ),
      isTrue,
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
      contains('trust_fabric.sign_credential(hmac-sha256) -> ok'),
    );
    expect(
      report.trace,
      contains(
        'trust_fabric.keystore(dart-test-hmac) -> zpk-test-issuer-key-2026-05',
      ),
    );
    expect(
      report.trace,
      contains('trust_fabric.verify_credential_signature(local) -> ok'),
    );
    expect(
      report.trace,
      contains('trust_fabric.issue_consent(local, 15m) -> signed'),
    );
  });

  test('rejects tampered local recovery credentials', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final report = await testIdentityFabric.evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );
    final tampered = Map<String, Object>.from(report.verifiableCredential);
    tampered['credentialSubject'] = {
      ...(tampered['credentialSubject'] as Map<String, Object>),
      'matches': 0,
    };

    expect(
      await testIdentityFabric.verifyCredential(verifiableCredential: tampered),
      isFalse,
    );
  });
}
