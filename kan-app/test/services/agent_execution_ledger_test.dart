import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/agent_execution_ledger.dart';
import 'package:kan_app/services/digital_identity_fabric.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('builds a signed hash-chain ledger without raw CUI', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final fabric = const DigitalIdentityFabric();
    final trustReport = await fabric.evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );

    final ledger = await AgentExecutionLedgerService(identityFabric: fabric)
        .build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: CaseScenario.discoveredVictim,
          reasonerLabel: 'local-deterministic',
          usedLocalOnly: true,
        );

    expect(ledger.entries, hasLength(10));
    expect(ledger.rootHash, hasLength(64));
    expect(ledger.proofValue, hasLength(64));
    expect(ledger.keyStore, 'dart-test-hmac');
    expect(ledger.entries.first.previousHash, '0' * 64);
    expect(ledger.entries.last.entryHash, ledger.rootHash);
    expect(ledger.entries.toString(), isNot(contains(result.cui)));
    expect(
      ledger.trace,
      contains(startsWith('agent_ledger.hash_chain(sha256) -> ')),
    );
    expect(
      ledger.trace,
      contains(startsWith('agent_ledger.sign(dart-test-hmac) -> ')),
    );
    expect(ledger.trace, contains('agent_ledger.verify(local) -> ok'));
    expect(ledger.trace, contains('agent_ledger.entries -> 10'));
    expect(
      await AgentExecutionLedgerService(identityFabric: fabric).verify(ledger),
      isTrue,
    );
  });

  test('rejects tampered agent ledger hash chains', () async {
    final result = LocalBreachCatalog(
      now: DateTime.utc(2026, 5, 1),
    ).verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );
    final fabric = const DigitalIdentityFabric();
    final trustReport = await fabric.evaluate(
      result: result,
      scenario: CaseScenario.discoveredVictim,
      assessment: assessment,
    );

    final ledger = await AgentExecutionLedgerService(identityFabric: fabric)
        .build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: CaseScenario.discoveredVictim,
          reasonerLabel: 'local-deterministic',
          usedLocalOnly: true,
        );
    final tamperedEntries = [...ledger.entries];
    final first = tamperedEntries.first;
    tamperedEntries[0] = AgentLedgerEntry(
      sequence: first.sequence,
      action: 'tampered_action',
      inputDigest: first.inputDigest,
      outputDigest: first.outputDigest,
      previousHash: first.previousHash,
      entryHash: first.entryHash,
    );
    final tampered = AgentExecutionLedger(
      entries: tamperedEntries,
      rootHash: ledger.rootHash,
      proofValue: ledger.proofValue,
      keyStore: ledger.keyStore,
      trace: ledger.trace,
    );

    expect(
      await AgentExecutionLedgerService(
        identityFabric: fabric,
      ).verify(tampered),
      isFalse,
    );
  });
}
