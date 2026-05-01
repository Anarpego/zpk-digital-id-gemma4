import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../models/kan_case.dart';
import 'digital_identity_fabric.dart';
import 'recovery_packet_service.dart';

class AuditArchiveRecord {
  const AuditArchiveRecord({
    required this.id,
    required this.createdAt,
    required this.citizenPseudonym,
    required this.did,
    required this.scenario,
    required this.route,
    required this.usedLocalOnly,
    required this.localMatches,
    required this.recoveryPacketHash,
    required this.recoveryPacketSignature,
    required this.keyStore,
    required this.trace,
  });

  final String id;
  final DateTime createdAt;
  final String citizenPseudonym;
  final String did;
  final String scenario;
  final String route;
  final bool usedLocalOnly;
  final int localMatches;
  final String recoveryPacketHash;
  final String recoveryPacketSignature;
  final String keyStore;
  final List<String> trace;

  Map<String, Object> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'citizenPseudonym': citizenPseudonym,
    'did': did,
    'scenario': scenario,
    'route': route,
    'usedLocalOnly': usedLocalOnly,
    'localMatches': localMatches,
    'recoveryPacketHash': recoveryPacketHash,
    'recoveryPacketSignature': recoveryPacketSignature,
    'keyStore': keyStore,
    'trace': trace,
  };
}

class AuditArchiveReceipt {
  const AuditArchiveReceipt({
    required this.recordHash,
    required this.location,
    required this.recordCount,
    required this.trace,
  });

  final String recordHash;
  final String location;
  final int recordCount;
  final List<String> trace;
}

abstract interface class AuditArchive {
  Future<AuditArchiveReceipt> append(AuditArchiveRecord record);
}

class NativeAuditArchive implements AuditArchive {
  const NativeAuditArchive({
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/audit_archive'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<AuditArchiveReceipt> append(AuditArchiveRecord record) async {
    final canonicalRecord = _canonicalJson(record.toJson());
    final recordHash = _digest(canonicalRecord);
    final response = await _channel.invokeMapMethod<String, Object?>('append', {
      'recordJson': canonicalRecord,
      'recordHash': recordHash,
    });
    final location = response?['location'] as String? ?? 'native-internal';
    final recordCount = response?['recordCount'] as int? ?? 0;

    return AuditArchiveReceipt(
      recordHash: recordHash,
      location: location,
      recordCount: recordCount,
      trace: [
        'audit_archive.redacted_record(sha256) -> ${recordHash.substring(0, 16)}',
        'audit_archive.raw_cui -> omitted',
        'audit_archive.private_complaint -> omitted',
        'audit_archive.append(internal_storage) -> $location',
        'audit_archive.records -> $recordCount',
      ],
    );
  }
}

class MemoryAuditArchive implements AuditArchive {
  MemoryAuditArchive();

  final records = <String, String>{};

  @override
  Future<AuditArchiveReceipt> append(AuditArchiveRecord record) async {
    final canonicalRecord = _canonicalJson(record.toJson());
    final recordHash = _digest(canonicalRecord);
    records[recordHash] = canonicalRecord;

    return AuditArchiveReceipt(
      recordHash: recordHash,
      location: 'memory-audit-archive',
      recordCount: records.length,
      trace: [
        'audit_archive.redacted_record(sha256) -> ${recordHash.substring(0, 16)}',
        'audit_archive.raw_cui -> omitted',
        'audit_archive.private_complaint -> omitted',
        'audit_archive.append(memory) -> ok',
        'audit_archive.records -> ${records.length}',
      ],
    );
  }
}

class AuditArchiveService {
  const AuditArchiveService({required this.archive});

  final AuditArchive archive;

  Future<AuditArchiveReceipt> appendRecoveryAudit({
    required VerificationResult result,
    required CaseScenario scenario,
    required ReasonedGuidance guidance,
    required IdentityTrustReport trustReport,
    required RecoveryPacket recoveryPacket,
  }) {
    final record = AuditArchiveRecord(
      id: recoveryPacket.redactedPacketHash,
      createdAt: result.checkedAt,
      citizenPseudonym: trustReport.credential.pseudonymousId,
      did: trustReport.didDocument['id'] as String,
      scenario: scenario.shortCode,
      route: guidance.routingDecision.route.traceCode,
      usedLocalOnly: guidance.usedLocalOnly,
      localMatches: result.matches.length,
      recoveryPacketHash: recoveryPacket.redactedPacketHash,
      recoveryPacketSignature: recoveryPacket.signature,
      keyStore: recoveryPacket.keyStore,
      trace: [
        ...guidance.toolTrace,
        ...recoveryPacket.trace,
        'audit_archive.raw_cui -> omitted',
        'audit_archive.private_complaint -> omitted',
      ],
    );

    final serialized = _canonicalJson(record.toJson());
    if (serialized.contains(result.cui) ||
        serialized.contains(recoveryPacket.privateLocalComplaint)) {
      throw StateError('Audit archive record contains private local data.');
    }
    return archive.append(record);
  }
}

String _digest(String value) => sha256.convert(utf8.encode(value)).toString();

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
