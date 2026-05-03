import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/litert_gemma_reasoner.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

import '../test_identity_fabric.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gt.kan.kan_app/litert_gemma');
  const modelJson = '''
{
  "summary": "Respuesta Gemma 4 local segura.",
  "next_steps": [
    "Guardar evidencia redactada.",
    "Preparar una denuncia preliminar."
  ],
  "national_scale_note": "El flujo puede operar por municipio sin centralizar CUI.",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
''';

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('runs Gemma 4 through LiteRT-LM after status and warmup', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
              'modelSizeBytes': 2400000000,
            },
            'warmup' => {'status': 'READY', 'model': 'gemma-4-E2B-it-litertlm'},
            'generate' => {
              'text': modelJson,
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    final guidance =
        await const LiteRtGemmaReasoner(
          modelPath: '/sdcard/Download/gemma-4-E2B-it.litertlm',
          identityFabric: testIdentityFabric,
        ).explain(
          result: LocalBreachCatalog().verify('1234567890101'),
          scenario: CaseScenario.discoveredVictim,
        );

    expect(calls, ['status', 'warmup', 'generate']);
    expect(guidance.summary, contains('Respuesta Gemma 4 local segura.'));
    expect(guidance.usedLocalOnly, isTrue);
    expect(
      guidance.toolTrace,
      contains(
        'litert_gemma.status_probe(gemma-4-E2B-it-litertlm) -> AVAILABLE',
      ),
    );
    expect(guidance.toolTrace, contains('privacy_guard.raw_cui -> absent'));
    expect(
      guidance.toolTrace,
      contains('litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok'),
    );
  });

  test('does not generate when model path is missing', () async {
    await expectLater(
      const LiteRtGemmaReasoner(modelPath: '').explain(
        result: LocalBreachCatalog().verify('1234567890101'),
        scenario: CaseScenario.discoveredVictim,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('does not generate when warmup fails', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            'warmup' => {
              'status': 'FAILED',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    await expectLater(
      const LiteRtGemmaReasoner(
        modelPath: '/sdcard/Download/gemma-4-E2B-it.litertlm',
        identityFabric: testIdentityFabric,
      ).explain(
        result: LocalBreachCatalog().verify('1234567890101'),
        scenario: CaseScenario.discoveredVictim,
      ),
      throwsA(isA<StateError>()),
    );
    expect(calls, ['status', 'warmup']);
  });

  test('does not generate when native status reports missing model', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return {
            'status': 'MISSING_MODEL',
            'model': 'gemma-4-E2B-it-litertlm',
          };
        });

    await expectLater(
      const LiteRtGemmaReasoner(
        modelPath: '/sdcard/Download/missing.litertlm',
        identityFabric: testIdentityFabric,
      ).explain(
        result: LocalBreachCatalog().verify('1234567890101'),
        scenario: CaseScenario.discoveredVictim,
      ),
      throwsA(isA<StateError>()),
    );
    expect(calls, ['status']);
  });

  test(
    'downloads the model before generation when a URL is configured',
    () async {
      final calls = <String>[];
      var statusCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return switch (call.method) {
              'status' => {
                'status': statusCalls++ == 0 ? 'MISSING_MODEL' : 'AVAILABLE',
                'model': 'gemma-4-E2B-it-litertlm',
              },
              'downloadModel' => {
                'status': 'AVAILABLE',
                'model': 'gemma-4-E2B-it-litertlm',
                'sha256': 'ab7838',
                'bytes': 2583085056,
              },
              'warmup' => {
                'status': 'READY',
                'model': 'gemma-4-E2B-it-litertlm',
              },
              'generate' => {
                'text': modelJson,
                'status': 'AVAILABLE',
                'model': 'gemma-4-E2B-it-litertlm',
              },
              _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
            };
          });

      final guidance =
          await const LiteRtGemmaReasoner(
            modelPath:
                '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
            modelUrl: 'https://example.test/gemma-4-E2B-it.litertlm',
            modelSha256: 'ab7838',
            identityFabric: testIdentityFabric,
          ).explain(
            result: LocalBreachCatalog().verify('1234567890101'),
            scenario: CaseScenario.discoveredVictim,
          );

      expect(calls, [
        'status',
        'downloadModel',
        'status',
        'warmup',
        'generate',
      ]);
      expect(
        guidance.toolTrace,
        contains(
          'litert_gemma.download(gemma-4-E2B-it-litertlm) -> AVAILABLE:ab7838',
        ),
      );
    },
  );

  test(
    'runtime status reports downloadable model before device install',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'status');
            return {
              'status': 'MISSING_MODEL',
              'model': 'gemma-4-E2B-it-litertlm',
            };
          });

      final status = await const LiteRtGemmaReasoner(
        modelPath:
            '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
        modelUrl: 'https://example.test/models/gemma-4-E2B-it.litertlm',
      ).runtimeStatus();

      expect(status.state, 'DOWNLOADABLE');
      expect(status.isModelBacked, isTrue);
      expect(status.isOfflineCapable, isFalse);
      expect(
        status.trace,
        contains('litert_gemma.model_download -> configured'),
      );
    },
  );

  test('runtime status rejects corrupt model hash before generation', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'status');
          expect(
            (call.arguments as Map<Object?, Object?>)['sha256'],
            'expected-sha',
          );
          return {
            'status': 'CORRUPT_MODEL',
            'model': 'gemma-4-E2B-it-litertlm',
            'sha256': 'actual-sha',
            'sha256Expected': 'expected-sha',
          };
        });

    final status = await const LiteRtGemmaReasoner(
      modelPath:
          '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
      modelSha256: 'expected-sha',
    ).runtimeStatus();

    expect(status.state, 'CORRUPT_MODEL');
    expect(status.isOfflineCapable, isFalse);
  });

  test('runtime status reports installed model blocked on emulator', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'status');
          return {
            'status': 'EMULATOR_UNSUPPORTED',
            'model': 'gemma-4-E2B-it-litertlm',
            'modelSizeBytes': 2583085056,
            'runtimeGuard': 'android-emulator-native-litertlm',
          };
        });

    final status = await const LiteRtGemmaReasoner(
      modelPath:
          '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
    ).runtimeStatus();

    expect(status.state, 'EMULATOR_UNSUPPORTED');
    expect(status.isOfflineCapable, isFalse);
    expect(status.summary, contains('dispositivo ARM64 fisico'));
    expect(
      status.trace,
      contains(
        'litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> EMULATOR_UNSUPPORTED',
      ),
    );
  });

  test(
    'installs downloadable model and warms runtime before first case',
    () async {
      final calls = <String>[];
      var statusCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (call.method == 'status') {
              expect(
                (call.arguments as Map<Object?, Object?>)['sha256'],
                'ab7838',
              );
            }
            return switch (call.method) {
              'status' => {
                'status': statusCalls++ == 0 ? 'MISSING_MODEL' : 'AVAILABLE',
                'model': 'gemma-4-E2B-it-litertlm',
              },
              'downloadModel' => {
                'status': 'AVAILABLE',
                'model': 'gemma-4-E2B-it-litertlm',
                'sha256': 'ab7838',
                'bytes': 2583085056,
              },
              'warmup' => {
                'status': 'READY',
                'model': 'gemma-4-E2B-it-litertlm',
              },
              _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
            };
          });

      final result = await const LiteRtGemmaReasoner(
        modelPath:
            '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
        modelUrl: 'https://example.test/models/gemma-4-E2B-it.litertlm',
        modelSha256: 'ab7838',
      ).installRuntimeAssets();

      expect(calls, ['status', 'downloadModel', 'status', 'warmup']);
      expect(result.status, 'AVAILABLE');
      expect(
        result.trace,
        contains(
          'litert_gemma.install.download(gemma-4-E2B-it-litertlm) -> AVAILABLE:ab7838',
        ),
      );
      expect(
        result.trace,
        contains(
          'litert_gemma.install.warmup(gemma-4-E2B-it-litertlm) -> READY',
        ),
      );
    },
  );

  test('warms and hash-verifies when model is already installed', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
              'hashVerification': 'sidecar',
            },
            'warmup' => {
              'status': 'READY',
              'model': 'gemma-4-E2B-it-litertlm',
              'hashVerification': 'sidecar',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    final result = await const LiteRtGemmaReasoner(
      modelPath:
          '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
      modelSha256: 'ab7838',
    ).installRuntimeAssets();

    expect(calls, ['status', 'warmup']);
    expect(result.status, 'READY');
    expect(result.summary, contains('hash-verificado'));
    expect(
      result.trace,
      contains('litert_gemma.install.warmup.hash -> sidecar'),
    );
  });

  test('install fails when warmup does not become ready', () async {
    final calls = <String>[];
    var statusCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': statusCalls++ == 0 ? 'MISSING_MODEL' : 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            'downloadModel' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
              'sha256': 'ab7838',
              'bytes': 2583085056,
            },
            'warmup' => {
              'status': 'FAILED',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    await expectLater(
      const LiteRtGemmaReasoner(
        modelPath:
            '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
        modelUrl: 'https://example.test/models/gemma-4-E2B-it.litertlm',
        modelSha256: 'ab7838',
      ).installRuntimeAssets(),
      throwsA(isA<StateError>()),
    );
    expect(calls, ['status', 'downloadModel', 'status', 'warmup']);
  });

  test('self test fails before generation when warmup fails', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            'warmup' => {
              'status': 'FAILED',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    await expectLater(
      const LiteRtGemmaReasoner(
        modelPath:
            '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
      ).runRuntimeSelfTest(),
      throwsA(isA<StateError>()),
    );
    expect(calls, ['status', 'warmup']);
  });
}
