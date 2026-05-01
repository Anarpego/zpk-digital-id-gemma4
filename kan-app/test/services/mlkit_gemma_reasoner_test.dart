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

    expect(calls, ['status', 'generate']);
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
