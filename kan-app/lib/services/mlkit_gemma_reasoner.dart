import 'package:flutter/services.dart';

import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'agent_response_contract.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class MlKitGemmaReasoner implements KanReasoner {
  const MlKitGemmaReasoner({
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/mlkit_gemma'),
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    AgentResponseContract responseContract = const AgentResponseContract(),
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  }) : _channel = channel,
       _promptBuilder = promptBuilder,
       _responseContract = responseContract;

  final MethodChannel _channel;
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
    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final routing = assessment.route;
    final statusProbe = await _channel.invokeMapMethod<String, Object?>(
      'status',
    );
    var probedStatus = statusProbe?['status'] as String? ?? 'UNKNOWN';
    var probedModel =
        statusProbe?['model'] as String? ?? 'mlkit-genai-prompt-aicore';
    final setupTrace = <String>[
      'mlkit_gemma.status_probe($probedModel) -> $probedStatus',
    ];
    if (probedStatus == 'DOWNLOADABLE') {
      final download = await _channel.invokeMapMethod<String, Object?>(
        'download',
      );
      final downloadStatus = download?['status'] as String? ?? 'UNKNOWN';
      setupTrace.add('mlkit_gemma.download($probedModel) -> $downloadStatus');
      final reprobe = await _channel.invokeMapMethod<String, Object?>('status');
      probedStatus = reprobe?['status'] as String? ?? downloadStatus;
      probedModel =
          reprobe?['model'] as String? ??
          download?['model'] as String? ??
          probedModel;
      setupTrace.add('mlkit_gemma.status_probe($probedModel) -> $probedStatus');
    }
    if (probedStatus != 'AVAILABLE') {
      throw StateError('ML Kit Gemma status is $probedStatus.');
    }
    final warmup = await _channel.invokeMapMethod<String, Object?>('warmup');
    setupTrace.add(
      'mlkit_gemma.warmup($probedModel) -> ${warmup?['status'] ?? 'UNKNOWN'}',
    );

    final prompt = await _promptBuilder.build(
      result: result,
      scenario: scenario,
      identityFabric: identityFabric,
    );
    final privacyReport = privacyGuard.requireRedactedModelPrompt(
      prompt: prompt,
      result: result,
    );

    final response = await _channel.invokeMapMethod<String, Object?>(
      'generate',
      {'prompt': prompt},
    );
    final text = (response?['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException('ML Kit Gemma returned no final text.');
    }
    final agentResponse = _responseContract.parse(text: text, result: result);

    final status = response?['status'] as String? ?? 'AVAILABLE';
    final model = response?['model'] as String? ?? 'mlkit-genai-prompt';
    final ledger =
        await AgentExecutionLedgerService(identityFabric: identityFabric).build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: scenario,
          reasonerLabel: 'mlkit-gemma:$model',
          usedLocalOnly: true,
        );

    return ReasonedGuidance(
      summary: agentResponse.summary,
      nextSteps: agentResponse.nextSteps,
      toolTrace: [
        ...assessment.toolTrace,
        ...trustReport.trace,
        ...privacyReport.trace,
        ...setupTrace,
        ...agentResponse.trace,
        'gemma_agent.prompt(redacted_facts) -> ok',
        'mlkit_gemma.status -> $status',
        'mlkit_gemma.generateContent($model) -> ok',
        ...ledger.trace,
      ],
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }
}
