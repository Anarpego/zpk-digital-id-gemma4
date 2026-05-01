import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/kan_case.dart';
import 'kan_reasoner.dart';
import 'routing_policy.dart';

class GemmaApiReasoner implements KanReasoner {
  GemmaApiReasoner({
    required this.apiKey,
    this.model = 'gemma-4-31b-it',
    http.Client? client,
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    this.routingPolicy = const RoutingPolicy(),
  }) : _client = client ?? http.Client(),
       _promptBuilder = promptBuilder;

  final String apiKey;
  final String model;
  final http.Client _client;
  final ReasonerPromptBuilder _promptBuilder;
  final RoutingPolicy routingPolicy;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('KAN_GEMINI_API_KEY is required for hosted Gemma mode.');
    }

    final routing = routingPolicy.decide(result: result, scenario: scenario);
    final prompt = _promptBuilder.build(result: result, scenario: scenario);
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 220},
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Gemma API failed with HTTP ${response.statusCode}.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractFinalText(body);
    final usage = body['usageMetadata'] as Map<String, dynamic>? ?? {};
    final modelVersion = body['modelVersion'] as String? ?? model;

    return ReasonedGuidance(
      summary: text,
      nextSteps: const [
        'Revise la respuesta antes de generar documentos.',
        'No envie CUI ni datos personales al servidor.',
      ],
      toolTrace: [
        routing.trace,
        'gemma_api.generateContent($modelVersion) -> ok',
        'gemma_api.tokens -> prompt ${usage['promptTokenCount'] ?? 'n/a'}, total ${usage['totalTokenCount'] ?? 'n/a'}',
      ],
      usedLocalOnly: false,
      routingDecision: routing,
    );
  }

  String _extractFinalText(Map<String, dynamic> body) {
    final candidates = body['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) {
      throw const FormatException('Gemma API returned no candidates.');
    }
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    final textParts = parts
        .whereType<Map<String, dynamic>>()
        .where((part) => part['thought'] != true)
        .map((part) => part['text'])
        .whereType<String>()
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (textParts.isEmpty) {
      throw const FormatException('Gemma API returned no final text.');
    }
    return textParts.last;
  }
}
