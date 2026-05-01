import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/gemma_api_reasoner.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('parses hosted Gemma final text and token trace', () async {
    final reasoner = GemmaApiReasoner(
      apiKey: 'test-key',
      client: MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-key');
        expect(
          request.url.path,
          '/v1beta/models/gemma-4-31b-it:generateContent',
        );

        return http.Response('''
{
  "candidates": [
    {
      "content": {
        "parts": [
          {"text": "internal reasoning", "thought": true},
          {"text": "Respuesta final segura."}
        ],
        "role": "model"
      },
      "finishReason": "STOP"
    }
  ],
  "usageMetadata": {
    "promptTokenCount": 35,
    "totalTokenCount": 80
  },
  "modelVersion": "gemma-4-31b-it"
}
''', 200);
      }),
    );

    final guidance = await reasoner.explain(
      result: LocalBreachCatalog().verify('1234567890101'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(guidance.summary, 'Respuesta final segura.');
    expect(guidance.usedLocalOnly, isFalse);
    expect(
      guidance.toolTrace,
      contains('gemma_agent.prompt(redacted_facts) -> ok'),
    );
    expect(
      guidance.toolTrace,
      contains('trust_fabric.sign_credential(hmac-sha256) -> ok'),
    );
    expect(
      guidance.toolTrace,
      contains('trust_fabric.issue_consent(local, 15m) -> signed'),
    );
    expect(
      guidance.toolTrace,
      contains('gemma_api.generateContent(gemma-4-31b-it) -> ok'),
    );
    expect(
      guidance.toolTrace,
      contains('gemma_api.tokens -> prompt 35, total 80'),
    );
    expect(
      guidance.toolTrace,
      contains(startsWith('agent_ledger.hash_chain(sha256) -> ')),
    );
    expect(
      guidance.toolTrace,
      contains(startsWith('agent_ledger.sign(dart-test-hmac) -> ')),
    );
  });

  test('fails closed when API key is missing', () async {
    final reasoner = GemmaApiReasoner(apiKey: '');

    expect(
      () => reasoner.explain(
        result: LocalBreachCatalog().verify('1234567890101'),
        scenario: CaseScenario.discoveredVictim,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
