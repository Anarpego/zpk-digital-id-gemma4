import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';

class AgentLedgerEntry {
  const AgentLedgerEntry({
    required this.sequence,
    required this.action,
    required this.inputDigest,
    required this.outputDigest,
    required this.previousHash,
    required this.entryHash,
  });

  final int sequence;
  final String action;
  final String inputDigest;
  final String outputDigest;
  final String previousHash;
  final String entryHash;

  Map<String, Object> toJson() => {
    'sequence': sequence,
    'action': action,
    'inputDigest': inputDigest,
    'outputDigest': outputDigest,
    'previousHash': previousHash,
    'entryHash': entryHash,
  };
}

class AgentExecutionLedger {
  const AgentExecutionLedger({
    required this.entries,
    required this.rootHash,
    required this.proofValue,
    required this.keyStore,
    required this.trace,
  });

  final List<AgentLedgerEntry> entries;
  final String rootHash;
  final String proofValue;
  final String keyStore;
  final List<String> trace;
}

class AgentExecutionLedgerService {
  const AgentExecutionLedgerService({required this.identityFabric});

  final DigitalIdentityFabric identityFabric;

  Future<AgentExecutionLedger> build({
    required IdentityAgentAssessment assessment,
    required IdentityTrustReport trustReport,
    required VerificationResult result,
    required CaseScenario scenario,
    required String reasonerLabel,
    required bool usedLocalOnly,
  }) async {
    final events = [
      for (final call in assessment.toolCalls)
        _LedgerEvent(call.name, call.input, call.output),
      _LedgerEvent(
        'identity_credential',
        trustReport.credential.assuranceLevel,
        trustReport.credential.pseudonymousId,
      ),
      _LedgerEvent(
        'consent_grant',
        trustReport.consentGrant.scope,
        '${trustReport.consentGrant.expiresInMinutes}m',
      ),
      _LedgerEvent(
        'reasoner',
        reasonerLabel,
        usedLocalOnly ? 'local_only' : 'redacted_remote',
      ),
      _LedgerEvent(
        'scenario',
        scenario.shortCode,
        '${result.matches.length}_local_matches',
      ),
    ];

    var previousHash = '0' * 64;
    final entries = <AgentLedgerEntry>[];
    for (var index = 0; index < events.length; index++) {
      final event = events[index];
      final entryPayload = {
        'sequence': index + 1,
        'action': event.action,
        'inputDigest': _digest(event.input),
        'outputDigest': _digest(event.output),
        'previousHash': previousHash,
      };
      final entryHash = _digest(_canonicalJson(entryPayload));
      final entry = AgentLedgerEntry(
        sequence: index + 1,
        action: event.action,
        inputDigest: entryPayload['inputDigest'] as String,
        outputDigest: entryPayload['outputDigest'] as String,
        previousHash: previousHash,
        entryHash: entryHash,
      );
      entries.add(entry);
      previousHash = entryHash;
    }

    final rootHash = previousHash;
    final signature = await identityFabric.signCanonicalPayload(
      _canonicalJson({
        'purpose': 'zpk-agent-execution-ledger',
        'issuer': identityFabric.issuerKeyId,
        'rootHash': rootHash,
        'entries': entries.map((entry) => entry.toJson()).toList(),
      }),
    );

    final ledger = AgentExecutionLedger(
      entries: entries,
      rootHash: rootHash,
      proofValue: signature.proofValue,
      keyStore: signature.keyStore,
      trace: const [],
    );
    final verified = await verify(ledger);

    return AgentExecutionLedger(
      entries: ledger.entries,
      rootHash: ledger.rootHash,
      proofValue: ledger.proofValue,
      keyStore: ledger.keyStore,
      trace: [
        'agent_ledger.hash_chain(sha256) -> ${rootHash.substring(0, 16)}',
        'agent_ledger.sign(${signature.keyStore}) -> ${signature.proofValue.substring(0, 16)}',
        'agent_ledger.verify(local) -> ${verified ? 'ok' : 'failed'}',
        'agent_ledger.entries -> ${entries.length}',
      ],
    );
  }

  Future<bool> verify(AgentExecutionLedger ledger) async {
    if (ledger.entries.isEmpty) {
      return false;
    }

    var previousHash = '0' * 64;
    for (final entry in ledger.entries) {
      if (entry.previousHash != previousHash) {
        return false;
      }
      final entryPayload = {
        'sequence': entry.sequence,
        'action': entry.action,
        'inputDigest': entry.inputDigest,
        'outputDigest': entry.outputDigest,
        'previousHash': entry.previousHash,
      };
      final expectedEntryHash = _digest(_canonicalJson(entryPayload));
      if (entry.entryHash != expectedEntryHash) {
        return false;
      }
      previousHash = entry.entryHash;
    }

    if (ledger.rootHash != previousHash) {
      return false;
    }

    final signature = await identityFabric.signCanonicalPayload(
      _canonicalJson({
        'purpose': 'zpk-agent-execution-ledger',
        'issuer': identityFabric.issuerKeyId,
        'rootHash': ledger.rootHash,
        'entries': ledger.entries.map((entry) => entry.toJson()).toList(),
      }),
    );
    return signature.proofValue == ledger.proofValue;
  }

  String _digest(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  String _canonicalJson(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return '{${keys.map((key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}').join(',')}}';
    }
    if (value is Iterable) {
      return '[${value.map(_canonicalJson).join(',')}]';
    }
    return jsonEncode(value);
  }
}

class _LedgerEvent {
  const _LedgerEvent(this.action, this.input, this.output);

  final String action;
  final String input;
  final String output;
}
