import 'package:cactus/cactus.dart';

import '../models/kan_case.dart';
import 'kan_reasoner.dart';
import 'routing_policy.dart';

class CactusReasoner implements KanReasoner {
  CactusReasoner({
    CactusLM? lm,
    this.model = 'google/gemma-4-E2B-it',
    this.maxTokens = 384,
    this.enableTools = true,
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    this.routingPolicy = const RoutingPolicy(),
  }) : _lm = lm ?? CactusLM(enableToolFiltering: enableTools),
       _promptBuilder = promptBuilder;

  final CactusLM _lm;
  final String model;
  final int maxTokens;
  final bool enableTools;
  final RoutingPolicy routingPolicy;
  final ReasonerPromptBuilder _promptBuilder;

  bool _initialized = false;

  static final tools = [
    createTool(
      'verify_dpi_in_local_leaks',
      'Verifica si un CUI aparece en el catalogo local de brechas.',
      {
        'cui': ToolParameter(
          type: 'string',
          description: 'CUI guatemalteco de 13 digitos',
          required: true,
        ),
      },
    ),
    createTool(
      'fill_legal_template',
      'Prepara una denuncia preliminar en el dispositivo.',
      {
        'template': ToolParameter(
          type: 'string',
          description: 'Plantilla legal local que se debe llenar',
          required: true,
        ),
      },
    ),
  ];

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    final routing = routingPolicy.decide(result: result, scenario: scenario);
    await _initialize();
    final prompt = _promptBuilder.build(result: result, scenario: scenario);
    final completion = await _lm.generateCompletion(
      messages: [ChatMessage(role: 'user', content: prompt)],
      params: CactusCompletionParams(
        model: model,
        maxTokens: maxTokens,
        tools: enableTools ? tools : null,
        completionMode: CompletionMode.local,
      ),
    );
    if (!completion.success) {
      throw StateError('Cactus completion failed: ${completion.response}');
    }

    return ReasonedGuidance(
      summary: completion.response.trim(),
      nextSteps: const [
        'Revise la respuesta antes de generar documentos.',
        'Mantenga el CUI y datos personales solo en el dispositivo.',
      ],
      toolTrace: [
        routing.trace,
        'cactus.tools -> ${enableTools ? 'enabled' : 'disabled'}',
        'cactus.generateCompletion(local, $model) -> ${completion.success ? 'ok' : 'error'}',
        'cactus.metrics -> ttft ${completion.timeToFirstTokenMs.round()}ms, total ${completion.totalTimeMs.round()}ms, ${completion.tokensPerSecond.toStringAsFixed(1)} tok/s',
        for (final call in completion.toolCalls)
          '${call.name}(cactus) -> ${call.arguments}',
      ],
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }
    await _lm.downloadModel(model: model);
    await _lm.initializeModel(params: CactusInitParams(model: model));
    _initialized = true;
  }
}
