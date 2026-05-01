import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/audit_archive.dart';
import 'package:kan_app/services/digital_identity_fabric.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/legal_template_service.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/mock_reasoner.dart';
import 'package:kan_app/services/recovery_packet_service.dart';

void main() {
  test(
    'archives redacted recovery audit without raw CUI or complaint',
    () async {
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
      final guidance = await MockReasoner(
        identityFabric: fabric,
      ).explain(result: result, scenario: scenario);
      final complaint = const LegalTemplateService().buildComplaint(
        result: result,
        scenario: scenario,
      );
      final packet = await RecoveryPacketService(identityFabric: fabric).build(
        result: result,
        scenario: scenario,
        trustReport: trustReport,
        privateLocalComplaint: complaint,
      );
      final archive = MemoryAuditArchive();

      final receipt = await AuditArchiveService(archive: archive)
          .appendRecoveryAudit(
            result: result,
            scenario: scenario,
            guidance: guidance,
            trustReport: trustReport,
            recoveryPacket: packet,
          );

      final storedRecord = archive.records.values.single;
      expect(receipt.recordHash, hasLength(64));
      expect(receipt.recordCount, 1);
      expect(storedRecord, isNot(contains(result.cui)));
      expect(storedRecord, isNot(contains(complaint)));
      expect(storedRecord, contains('audit_archive.raw_cui'));
      expect(storedRecord, contains(packet.redactedPacketHash));
    },
  );
}
