import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/digital_identity_fabric.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_authentication_service.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/revocation_service.dart';

void main() {
  test('builds a signed authentication proof without raw CUI', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final trustReport = await const DigitalIdentityFabric().evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );

    final service = LocalAuthenticationService(
      fixedNow: DateTime.utc(2026, 5, 1, 12),
    );
    final proof = await service.buildProof(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      trustReport: trustReport,
    );

    expect(proof.relyingParty, 'municipalidad-guatemala-demo');
    expect(proof.challenge, startsWith('zpk-auth-'));
    expect(proof.pseudonymousId, startsWith('zpk-gt-'));
    expect(proof.issuedAt, DateTime.utc(2026, 5, 1, 12));
    expect(proof.expiresAt, DateTime.utc(2026, 5, 1, 12, 5));
    expect(proof.sharePacket.toString(), isNot(contains(result.cui)));
    expect(
      proof.trace,
      contains('auth.relying_party(local_allowlist) -> approved'),
    );
    expect(
      proof.trace,
      contains(
        'auth.scopes(local_policy) -> identity_recovery+citizen_support',
      ),
    );
    expect(proof.trace, contains('auth.raw_cui -> omitted'));
    expect(
      proof.trace,
      contains('auth.selective_disclosure(local) -> 4_claims'),
    );
    expect(proof.trace, contains('auth.verify(local) -> ok'));
    expect(
      proof.trace,
      contains('auth.valid_until(local) -> 2026-05-01T12:05:00.000Z'),
    );
    expect(proof.signature, isNotEmpty);
    expect(proof.keyStore, 'dart-test-hmac');
    expect(await service.verifySharePacket(proof.sharePacket), isTrue);
  });

  test('rejects tampered authentication proof packets', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final trustReport = await const DigitalIdentityFabric().evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );
    final proof = await const LocalAuthenticationService().buildProof(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      trustReport: trustReport,
    );
    final tampered = Map<String, Object>.from(proof.sharePacket)
      ..['expiresInMinutes'] = 60;

    expect(
      await const LocalAuthenticationService().verifySharePacket(tampered),
      isFalse,
    );
  });

  test(
    'does not issue authentication proof to unknown relying party',
    () async {
      final result = LocalBreachCatalog(
        now: DateTime.utc(2026, 5, 1),
      ).verify('1234567890101');
      final assessment = const IdentityProtectionAgent().assess(
        result: result,
        scenario: CaseScenario.discoveredVictim,
      );
      final trustReport = await const DigitalIdentityFabric().evaluate(
        result: result,
        scenario: CaseScenario.discoveredVictim,
        assessment: assessment,
      );

      await expectLater(
        const LocalAuthenticationService().buildProof(
          result: result,
          scenario: CaseScenario.discoveredVictim,
          trustReport: trustReport,
          relyingParty: 'unknown-institution-demo',
        ),
        throwsStateError,
      );
    },
  );

  test('does not verify signed proof for untrusted relying party', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final trustReport = await const DigitalIdentityFabric().evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );
    final permissiveService = LocalAuthenticationService(
      fixedNow: DateTime.utc(2026, 5, 1, 12),
      relyingPartyPolicy: const RelyingPartyPolicy(
        allowedParties: {
          'unknown-institution-demo': ['identity_recovery'],
        },
      ),
    );
    final proof = await permissiveService.buildProof(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      trustReport: trustReport,
      relyingParty: 'unknown-institution-demo',
    );

    expect(
      await LocalAuthenticationService(
        fixedNow: DateTime.utc(2026, 5, 1, 12),
      ).verifySharePacket(proof.sharePacket),
      isFalse,
    );
  });

  test('rejects expired authentication proof packets', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final trustReport = await const DigitalIdentityFabric().evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );
    final proof =
        await LocalAuthenticationService(
          fixedNow: DateTime.utc(2026, 5, 1, 12),
        ).buildProof(
          result: result,
          scenario: CaseScenario.discoveredVictim,
          trustReport: trustReport,
        );

    expect(
      await LocalAuthenticationService(
        fixedNow: DateTime.utc(2026, 5, 1, 12, 6),
      ).verifySharePacket(proof.sharePacket),
      isFalse,
    );
  });

  test('does not issue authentication proof after local revocation', () async {
    final identityFabric = const DigitalIdentityFabric();
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );
    final revocationReceipt =
        await RevocationService(
          identityFabric: identityFabric,
        ).revokeLocalCredential(
          result: result,
          scenario: CaseScenario.discoveredVictim,
          trustReport: trustReport,
          reason: 'test_revocation',
        );

    await expectLater(
      const LocalAuthenticationService().buildProof(
        result: result,
        scenario: CaseScenario.discoveredVictim,
        trustReport: trustReport,
        revocationReceipt: revocationReceipt,
      ),
      throwsStateError,
    );
  });
}
