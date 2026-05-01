import 'package:flutter/services.dart';

import '../models/kan_case.dart';
import 'kan_reasoner.dart';
import 'routing_policy.dart';

class MlKitGemmaReasoner implements KanReasoner {
  const MlKitGemmaReasoner({
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/mlkit_gemma'),
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    this.routingPolicy = const RoutingPolicy(),
  }) : _channel = channel,
       _promptBuilder = promptBuilder;

  final MethodChannel _channel;
  final ReasonerPromptBuilder _promptBuilder;
  final RoutingPolicy routingPolicy;

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    final routing = routingPolicy.decide(result: result, scenario: scenario);
    final prompt = _promptBuilder.build(result: result, scenario: scenario);

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

    return ReasonedGuidance(
      summary: text,
      nextSteps: const [
        'Revise la respuesta antes de generar documentos.',
        'Mantenga el CUI y las pruebas dentro del dispositivo.',
      ],
      toolTrace: [
        routing.trace,
        'mlkit_gemma.status -> $status',
        'mlkit_gemma.generateContent($model) -> ok',
      ],
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }
}
