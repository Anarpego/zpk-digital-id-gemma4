import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/digital_identity_fabric.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/revocation_service.dart';

void main() {
  test('builds signed local revocation receipt without raw CUI', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final scenario = CaseScenario.discoveredVictim;
    final fabric = const DigitalIdentityFabric();
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: scenario,
    );
    final trustReport = await fabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );

    final receipt = await RevocationService(identityFabric: fabric)
        .revokeLocalCredential(
          result: result,
          scenario: scenario,
          trustReport: trustReport,
          reason: 'citizen_requested_local_revocation',
        );

    expect(receipt.revocationId, startsWith('zpk-rev-'));
    expect(receipt.receiptHash, hasLength(64));
    expect(receipt.signature, hasLength(64));
    expect(receipt.keyStore, 'dart-test-hmac');
    expect(receipt.redactedPayload.toString(), isNot(contains(result.cui)));
    expect(receipt.trace, contains('revocation.redact(raw_cui) -> omitted'));
    expect(
      receipt.trace,
      contains(startsWith('revocation.sign(dart-test-hmac) -> ')),
    );
  });
}
