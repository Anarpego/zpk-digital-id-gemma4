import 'package:cactus/cactus.dart';

import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'agent_response_contract.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class CactusReasoner implements KanReasoner {
  CactusReasoner({
    CactusLM? lm,
    this.model = 'google/gemma-4-E2B-it',
    this.maxTokens = 384,
    this.enableTools = true,
    ReasonerPromptBuilder promptBuilder = const ReasonerPromptBuilder(),
    AgentResponseContract responseContract = const AgentResponseContract(),
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  }) : _lm = lm ?? CactusLM(enableToolFiltering: enableTools),
       _promptBuilder = promptBuilder,
       _responseContract = responseContract;

  final CactusLM _lm;
  final String model;
  final int maxTokens;
  final bool enableTools;
  final RoutingPolicy routingPolicy;
  final IdentityProtectionAgent agent;
  final DigitalIdentityFabric identityFabric;
  final PrivacyGuard privacyGuard;
  final ReasonerPromptBuilder _promptBuilder;
  final AgentResponseContract _responseContract;

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
    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final routing = assessment.route;
    await _initialize();
    final prompt = await _promptBuilder.build(
      result: result,
      scenario: scenario,
      identityFabric: identityFabric,
    );
    final privacyReport = privacyGuard.requireRedactedModelPrompt(
      prompt: prompt,
      result: result,
    );
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
    final agentResponse = _responseContract.parse(
      text: completion.response,
      result: result,
    );
    final ledger =
        await AgentExecutionLedgerService(identityFabric: identityFabric).build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: scenario,
          reasonerLabel: 'cactus:$model',
          usedLocalOnly: true,
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
        'cactus.tools -> ${enableTools ? 'enabled' : 'disabled'}',
        'cactus.generateCompletion(local, $model) -> ${completion.success ? 'ok' : 'error'}',
        'cactus.metrics -> ttft ${completion.timeToFirstTokenMs.round()}ms, total ${completion.totalTimeMs.round()}ms, ${completion.tokensPerSecond.toStringAsFixed(1)} tok/s',
        for (final call in completion.toolCalls)
          '${call.name}(cactus) -> ${call.arguments}',
        ...ledger.trace,
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
