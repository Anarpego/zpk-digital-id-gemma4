import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/mlkit_gemma_reasoner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('gt.kan.kan_app/mlkit_gemma');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('probes on-device status before generation', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': 'AVAILABLE',
              'model': 'mlkit-genai-prompt-aicore',
            },
            'warmup' => {
              'status': 'READY',
              'model': 'mlkit-genai-prompt-aicore',
            },
            'generate' => {
              'text': 'Respuesta local segura.',
              'status': 'AVAILABLE',
              'model': 'mlkit-genai-prompt-aicore',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    final guidance = await const MlKitGemmaReasoner().explain(
      result: LocalBreachCatalog().verify('1234567890101'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(calls, ['status', 'warmup', 'generate']);
    expect(guidance.summary, 'Respuesta local segura.');
    expect(guidance.usedLocalOnly, isTrue);
    expect(
      guidance.toolTrace,
      contains(
        'mlkit_gemma.status_probe(mlkit-genai-prompt-aicore) -> AVAILABLE',
      ),
    );
    expect(guidance.toolTrace, contains('privacy_guard.raw_cui -> absent'));
  });

  test('downloads model when supported device reports downloadable', () async {
    final calls = <String>[];
    var statusCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          return switch (call.method) {
            'status' => {
              'status': statusCalls++ == 0 ? 'DOWNLOADABLE' : 'AVAILABLE',
              'model': 'mlkit-genai-prompt-aicore',
            },
            'download' => {
              'status': 'AVAILABLE',
              'model': 'mlkit-genai-prompt-aicore',
              'events': [
                {'event': 'started', 'bytesToDownload': 1024},
                {'event': 'completed'},
              ],
            },
            'warmup' => {
              'status': 'READY',
              'model': 'mlkit-genai-prompt-aicore',
            },
            'generate' => {
              'text': 'Respuesta local despues de descarga.',
              'status': 'AVAILABLE',
              'model': 'mlkit-genai-prompt-aicore',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    final guidance = await const MlKitGemmaReasoner().explain(
      result: LocalBreachCatalog().verify('1234567890101'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(calls, ['status', 'download', 'status', 'warmup', 'generate']);
    expect(guidance.summary, 'Respuesta local despues de descarga.');
    expect(
      guidance.toolTrace,
      contains(
        'mlkit_gemma.status_probe(mlkit-genai-prompt-aicore) -> DOWNLOADABLE',
      ),
    );
    expect(
      guidance.toolTrace,
      contains('mlkit_gemma.download(mlkit-genai-prompt-aicore) -> AVAILABLE'),
    );
    expect(
      guidance.toolTrace,
      contains('mlkit_gemma.warmup(mlkit-genai-prompt-aicore) -> READY'),
    );
  });

  test(
    'does not build a generation request when status is unavailable',
    () async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return {
              'status': 'UNAVAILABLE',
              'model': 'mlkit-genai-prompt-aicore',
            };
          });

      await expectLater(
        const MlKitGemmaReasoner().explain(
          result: LocalBreachCatalog().verify('1234567890101'),
          scenario: CaseScenario.discoveredVictim,
        ),
        throwsA(isA<StateError>()),
      );
      expect(calls, ['status']);
    },
  );
}
