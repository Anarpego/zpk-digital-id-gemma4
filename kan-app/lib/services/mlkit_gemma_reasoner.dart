import 'package:flutter/services.dart';

import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class MlKitGemmaReasoner implements KanReasoner {
  const MlKitGemmaReasoner({
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/mlkit_gemma'),
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  }) : _channel = channel,
       _promptBuilder = promptBuilder;

  final MethodChannel _channel;
  final ReasonerPromptBuilder _promptBuilder;
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
      summary: text,
      nextSteps: const [
        'Revise la respuesta antes de generar documentos.',
        'Mantenga el CUI y las pruebas dentro del dispositivo.',
      ],
      toolTrace: [
        ...assessment.toolTrace,
        ...trustReport.trace,
        ...privacyReport.trace,
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
