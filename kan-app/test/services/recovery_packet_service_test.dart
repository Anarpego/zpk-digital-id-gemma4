import 'package:flutter_test/flutter_test.dart';

import '../test_identity_fabric.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/legal_template_service.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/recovery_packet_service.dart';

void main() {
  test(
    'builds signed redacted packet while keeping full complaint local',
    () async {
      final result = LocalBreachCatalog(
        now: DateTime.utc(2026, 5, 1),
      ).verify('1234567890101');
      final assessment = const IdentityProtectionAgent().assess(
        result: result,
        scenario: CaseScenario.discoveredVictim,
      );
      final fabric = testIdentityFabric;
      final trustReport = await fabric.evaluate(
        result: result,
        scenario: CaseScenario.discoveredVictim,
        assessment: assessment,
      );
      final complaint = const LegalTemplateService().buildComplaint(
        result: result,
        scenario: CaseScenario.discoveredVictim,
      );

      final packet = await RecoveryPacketService(identityFabric: fabric).build(
        result: result,
        scenario: CaseScenario.discoveredVictim,
        trustReport: trustReport,
        privateLocalComplaint: complaint,
      );

      expect(packet.privateLocalComplaint, contains(result.cui));
      expect(
        packet.redactedSharePacket.toString(),
        isNot(contains(result.cui)),
      );
      expect(packet.redactedPacketHash, hasLength(64));
      expect(packet.signature, hasLength(64));
      expect(packet.keyStore, 'dart-test-hmac');
      expect(
        packet.trace,
        contains('recovery_packet.redact(raw_cui) -> retained_on_device'),
      );
      expect(
        packet.trace,
        contains(startsWith('recovery_packet.sign(dart-test-hmac) -> ')),
      );
      expect(packet.trace, contains('recovery_packet.verify(local) -> ok'));
      expect(
        await RecoveryPacketService(identityFabric: fabric).verifyPacket(
          redactedSharePacket: packet.redactedSharePacket,
          redactedPacketHash: packet.redactedPacketHash,
          signature: packet.signature,
        ),
        isTrue,
      );
    },
  );

  test('rejects tampered redacted recovery packets', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final fabric = testIdentityFabric;
    final trustReport = await fabric.evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );
    final complaint = const LegalTemplateService().buildComplaint(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final service = RecoveryPacketService(identityFabric: fabric);
    final packet = await service.build(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      trustReport: trustReport,
      privateLocalComplaint: complaint,
    );
    final tampered = Map<String, Object>.from(packet.redactedSharePacket)
      ..['localMatches'] = 0;

    expect(
      await service.verifyPacket(
        redactedSharePacket: tampered,
        redactedPacketHash: packet.redactedPacketHash,
        signature: packet.signature,
      ),
      isFalse,
    );
  });
}
