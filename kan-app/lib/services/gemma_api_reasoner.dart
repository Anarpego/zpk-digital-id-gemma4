import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'agent_response_contract.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class GemmaApiReasoner implements KanReasoner {
  GemmaApiReasoner({
    required this.apiKey,
    this.model = 'gemma-4-31b-it',
    http.Client? client,
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    AgentResponseContract responseContract = const AgentResponseContract(),
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  }) : _client = client ?? http.Client(),
       _promptBuilder = promptBuilder,
       _responseContract = responseContract;

  final String apiKey;
  final String model;
  final http.Client _client;
  final ReasonerPromptBuilder _promptBuilder;
  final AgentResponseContract _responseContract;
  final RoutingPolicy routingPolicy;
  final IdentityProtectionAgent agent;
  final DigitalIdentityFabric identityFabric;
  final PrivacyGuard privacyGuard;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    if (apiKey.isEmpty) {
      throw StateError('KAN_GEMINI_API_KEY is required for hosted Gemma mode.');
    }

    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final routing = assessment.route;
    final prompt = await _promptBuilder.build(
      result: result,
      scenario: scenario,
      identityFabric: identityFabric,
    );
    final privacyReport = privacyGuard.requireRedactedModelPrompt(
      prompt: prompt,
      result: result,
    );
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
    final modelText = _extractFinalText(body);
    final agentResponse = _responseContract.parse(
      text: modelText,
      result: result,
    );
    final usage = body['usageMetadata'] as Map<String, dynamic>? ?? {};
    final modelVersion = body['modelVersion'] as String? ?? model;
    final ledger =
        await AgentExecutionLedgerService(identityFabric: identityFabric).build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: scenario,
          reasonerLabel: 'gemma-api:$modelVersion',
          usedLocalOnly: false,
        );

    return ReasonedGuidance(
      summary: agentResponse.summary,
      nextSteps: agentResponse.nextSteps,
      toolTrace: [
        ...assessment.toolTrace,
        ...trustReport.trace,
        ...privacyReport.trace,
        ...agentResponse.trace,
        'gemma_agent.prompt(redacted_facts) -> ok',
        'gemma_api.generateContent($modelVersion) -> ok',
        'gemma_api.tokens -> prompt ${usage['promptTokenCount'] ?? 'n/a'}, total ${usage['totalTokenCount'] ?? 'n/a'}',
        ...ledger.trace,
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
