import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/local_deterministic_reasoner.dart';

import '../test_identity_fabric.dart';

void main() {
  test('fallback trace includes a useful primary error detail', () async {
    final reasoner = FallbackReasoner(
      primary: const _ThrowingReasoner(),
      fallback: const LocalDeterministicReasoner(
        identityFabric: testIdentityFabric,
      ),
      primaryLabel: 'cactus:functiongemma-270m',
    );

    final guidance = await reasoner.explain(
      result: LocalBreachCatalog().verify('1234567890101'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(
      guidance.toolTrace.first,
      contains('fallback: Bad state: Cactus completion failed'),
    );
  });

  test('runtime wrapper preserves model download progress', () async {
    final status = await const FallbackReasoner(
      primary: _ProgressReasoner(),
      fallback: LocalDeterministicReasoner(identityFabric: testIdentityFabric),
      primaryLabel: 'litert-gemma:gemma-4-e2b-it',
    ).runtimeStatus();

    expect(status.state, 'DOWNLOADING');
    expect(status.isOfflineCapable, isTrue);
    expect(status.downloadedBytes, 1024);
    expect(status.totalBytes, 4096);
    expect(status.summary, contains('Respaldo offline disponible'));
    expect(
      status.trace,
      contains('reasoner_runtime(litert-gemma:gemma-4-e2b-it) -> DOWNLOADING'),
    );
    expect(status.trace, contains('runtime.local_deterministic -> ready'));
  });

  test(
    'runtime wrapper exposes fallback when Gemma is hardware blocked',
    () async {
      final status = await const FallbackReasoner(
        primary: _LowMemoryReasoner(),
        fallback: LocalDeterministicReasoner(
          identityFabric: testIdentityFabric,
        ),
        primaryLabel: 'litert-gemma:gemma-4-e2b-it',
      ).runtimeStatus();

      expect(status.state, 'DEVICE_LOW_MEMORY');
      expect(status.isModelBacked, isTrue);
      expect(status.isOfflineCapable, isTrue);
      expect(status.summary, contains('6 GB'));
      expect(status.summary, contains('Respaldo offline disponible'));
      expect(
        status.trace,
        contains(
          'reasoner_runtime(litert-gemma:gemma-4-e2b-it) -> DEVICE_LOW_MEMORY',
        ),
      );
      expect(status.trace, contains('runtime.network_required -> false'));
    },
  );

  test(
    'runtime wrapper stays offline-capable when primary probe fails',
    () async {
      final status = await const FallbackReasoner(
        primary: _ThrowingRuntimeReasoner(),
        fallback: LocalDeterministicReasoner(
          identityFabric: testIdentityFabric,
        ),
        primaryLabel: 'litert-gemma:gemma-4-e2b-it',
      ).runtimeStatus();

      expect(status.state, 'PRIMARY_NOT_READY');
      expect(status.isModelBacked, isTrue);
      expect(status.isOfflineCapable, isTrue);
      expect(status.summary, contains('Respaldo disponible'));
      expect(status.trace, contains('runtime.local_deterministic -> ready'));
    },
  );
}

class _ThrowingReasoner implements KanReasoner {
  const _ThrowingReasoner();

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    throw StateError('Cactus completion failed: model missing');
  }
}

class _ProgressReasoner implements KanReasoner, ReasonerRuntimeProbe {
  const _ProgressReasoner();

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReasonerRuntimeStatus> runtimeStatus() async =>
      const ReasonerRuntimeStatus(
        label: 'LiteRT-LM Gemma 4',
        state: 'DOWNLOADING',
        summary: 'Descargando modelo.',
        isOfflineCapable: false,
        isModelBacked: true,
        trace: ['litert_gemma.runtime_status(model) -> DOWNLOADING'],
        downloadedBytes: 1024,
        totalBytes: 4096,
      );
}

class _LowMemoryReasoner implements KanReasoner, ReasonerRuntimeProbe {
  const _LowMemoryReasoner();

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReasonerRuntimeStatus>
  runtimeStatus() async => const ReasonerRuntimeStatus(
    label: 'LiteRT-LM Gemma 4',
    state: 'DEVICE_LOW_MEMORY',
    summary: 'Gemma 4 E2B requiere 6 GB para generacion estable.',
    isOfflineCapable: false,
    isModelBacked: true,
    trace: [
      'litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> DEVICE_LOW_MEMORY',
      'litert_gemma.device_ram_bytes -> 3869007872',
      'litert_gemma.required_ram_bytes -> 6000000000',
    ],
  );
}

class _ThrowingRuntimeReasoner implements KanReasoner, ReasonerRuntimeProbe {
  const _ThrowingRuntimeReasoner();

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ReasonerRuntimeStatus> runtimeStatus() async {
    throw StateError('native status channel unavailable');
  }
}
