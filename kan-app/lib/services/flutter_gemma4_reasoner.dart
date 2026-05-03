import 'package:flutter_gemma/flutter_gemma.dart';

import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'agent_response_contract.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class FlutterGemma4Reasoner
    implements
        KanReasoner,
        ReasonerRuntimeProbe,
        ReasonerRuntimeInstaller,
        ReasonerRuntimeSelfTester {
  FlutterGemma4Reasoner({
    required this.modelUrl,
    this.modelId = 'gemma-4-E2B-it.litertlm',
    this.maxTokens = 2048,
    this.preferredBackend = PreferredBackend.cpu,
    this.huggingFaceToken = '',
    AgentResponseContract responseContract = const AgentResponseContract(),
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  }) : _responseContract = responseContract;

  final String modelUrl;
  final String modelId;
  final int maxTokens;
  final PreferredBackend preferredBackend;
  final String huggingFaceToken;
  final RoutingPolicy routingPolicy;
  final IdentityProtectionAgent agent;
  final DigitalIdentityFabric identityFabric;
  final PrivacyGuard privacyGuard;
  final AgentResponseContract _responseContract;
  int? _lastInstallProgress;
  bool _initialized = false;

  @override
  Future<ReasonerRuntimeStatus> runtimeStatus() async {
    if (modelUrl.trim().isEmpty) {
      return const ReasonerRuntimeStatus(
        label: 'Flutter Gemma 4',
        state: 'MISSING_CONFIG',
        summary: 'Falta KAN_FLUTTER_GEMMA_MODEL_URL para instalar Gemma 4.',
        isOfflineCapable: false,
        isModelBacked: true,
        trace: ['flutter_gemma4.model_url -> missing'],
      );
    }
    await _initialize();
    final installed = await FlutterGemma.isModelInstalled(modelId);
    return ReasonerRuntimeStatus(
      label: 'Flutter Gemma 4',
      state: installed ? 'AVAILABLE' : 'DOWNLOADABLE',
      summary: installed
          ? 'Gemma 4 esta instalado para inferencia local con flutter_gemma.'
          : 'Gemma 4 puede descargarse desde URL HTTPS y ejecutarse localmente.',
      isOfflineCapable: installed,
      isModelBacked: true,
      trace: [
        'flutter_gemma4.runtime_status($modelId) -> ${installed ? 'AVAILABLE' : 'DOWNLOADABLE'}',
        'flutter_gemma4.model_type -> gemma4',
        'flutter_gemma4.file_type -> litertlm',
        'flutter_gemma4.backend -> ${preferredBackend.name}',
        if (_lastInstallProgress != null)
          'flutter_gemma4.install_progress_percent -> $_lastInstallProgress',
      ],
    );
  }

  @override
  Future<ReasonerRuntimeInstallResult> installRuntimeAssets() async {
    if (modelUrl.trim().isEmpty) {
      throw StateError('KAN_FLUTTER_GEMMA_MODEL_URL is required.');
    }
    await _initialize();
    _lastInstallProgress = 0;
    final installation =
        await FlutterGemma.installModel(
              modelType: ModelType.gemma4,
              fileType: ModelFileType.litertlm,
            )
            .fromNetwork(modelUrl, foreground: true)
            .withProgress((progress) => _lastInstallProgress = progress)
            .install();
    _lastInstallProgress = 100;

    return ReasonerRuntimeInstallResult(
      label: 'Flutter Gemma 4',
      status: 'AVAILABLE',
      summary: 'Gemma 4 quedo instalado para inferencia local.',
      trace: [
        'flutter_gemma4.install($modelId) -> AVAILABLE',
        'flutter_gemma4.install.model_id -> ${installation.modelId}',
        'flutter_gemma4.install.model_type -> ${installation.modelType.name}',
        'flutter_gemma4.install.file_type -> ${installation.fileType.name}',
      ],
    );
  }

  @override
  Future<ReasonerRuntimeSelfTestResult> runRuntimeSelfTest() async {
    await _ensureInstalled();
    final text = await _generateJson(
      prompt: '''
Eres el agente local ZPK para una prueba Gemma 4 offline en Guatemala.
Usa solo datos sinteticos y redactados. No inventes CUI, DPI, telefono, correo, direccion ni nombres completos.

Devuelve solo JSON valido:
{
  "summary": "resumen corto en espanol",
  "next_steps": ["paso 1", "paso 2"],
  "national_scale_note": "nota nacional sin PII",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
''',
    );
    final contractResult = _responseContract.parse(
      text: text,
      result: VerificationResult(
        cui: '9999999999999',
        matches: [
          BreachRecord(
            slug: 'flutter-gemma4-self-test',
            name: 'Prueba Gemma 4 sintetica redactada',
            exposedFields: ['riesgo_sintetico'],
            reportedOn: DateTime.utc(2026, 5, 2),
          ),
        ],
        checkedAt: DateTime.utc(2026, 5, 2),
        catalogSource: 'self_test_redacted',
      ),
    );

    return ReasonerRuntimeSelfTestResult(
      label: 'Flutter Gemma 4',
      status: 'OK',
      summary: 'Gemma 4 genero JSON local valido con flutter_gemma.',
      trace: [
        ...contractResult.trace,
        'privacy_guard.self_test_raw_cui -> absent',
        'flutter_gemma4.generate($modelId) -> ok',
      ],
    );
  }

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    await _ensureInstalled();
    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final prompt = _buildOnDevicePrompt(
      result: result,
      scenario: scenario,
      assessment: assessment,
      trustReport: trustReport,
    );
    final privacyReport = privacyGuard.requireRedactedModelPrompt(
      prompt: prompt,
      result: result,
    );
    final text = await _generateJson(prompt: prompt);
    final agentResponse = _responseContract.parse(text: text, result: result);
    final ledger =
        await AgentExecutionLedgerService(identityFabric: identityFabric).build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: scenario,
          reasonerLabel: 'flutter-gemma4:$modelId',
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
        'flutter_gemma4.generate($modelId) -> ok',
        ...ledger.trace,
      ],
      usedLocalOnly: true,
      routingDecision: assessment.route,
    );
  }

  String _buildOnDevicePrompt({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityAgentAssessment assessment,
    required IdentityTrustReport trustReport,
  }) {
    final exposedFields =
        result.matches.expand((match) => match.exposedFields).toSet().toList()
          ..sort();
    final sources = result.matches.map((match) => match.name).toSet().toList()
      ..sort();
    final bulletins = assessment.matchedBulletins
        .map(
          (match) =>
              '${match.bulletin.id}: ${match.bulletin.recommendedAction}',
        )
        .toList(growable: false);
    final selectedClaims = trustReport.selectiveDisclosureClaims
        .map((claim) {
          if (claim.startsWith('citizen=')) {
            return 'citizen=local_pseudonym_available';
          }
          return claim;
        })
        .join(', ');
    final coreTools = assessment.toolCalls
        .where(
          (call) =>
              call.name == 'validate_cui' ||
              call.name == 'local_breach_lookup' ||
              call.name == 'classify_identity_risk' ||
              call.name == 'select_privacy_route' ||
              call.name == 'threat_bulletin.match' ||
              call.name == 'prepare_action_packet',
        )
        .map((call) => '- ${call.trace}')
        .join('\n');

    return '''
Eres ZPK Digital ID ejecutandose offline con Gemma 4 local.
Ayuda a una persona en Guatemala con lenguaje claro y pocos pasos.
No eres chatbot general: eres agente de identidad que ya ejecuto herramientas locales.
No pidas mas datos personales. No escribas CUI, DPI, telefono, correo, direccion ni nombres completos.

Caso redactado:
- escenario: ${scenario.label}
- mision: ${scenario.mission}
- institucion_objetivo: ${scenario.institutionName}
- cui_formato_valido: ${result.isValidCui}
- coincidencias_locales: ${result.matches.length}
- campos_expuestos: ${exposedFields.isEmpty ? 'ninguno' : exposedFields.join(', ')}
- fuentes_redactadas: ${sources.isEmpty ? 'ninguna' : sources.join('; ')}
- riesgo: ${assessment.riskLevel.label}
- ruta_privacidad: ${assessment.route.route.traceCode}
- envia_datos_personales: ${assessment.route.sendsPersonalData}
- divulgacion_selectiva: $selectedClaims
- estado_recuperacion: ${trustReport.recoveryStatus}
- boletines_hash_verificados: ${bulletins.isEmpty ? 'sin coincidencia' : bulletins.join('; ')}

Herramientas locales ejecutadas:
$coreTools

Tarea:
Redacta una guia ciudadana breve. Debe servir para alguien con poca experiencia usando celular:
1. Explica que la app ya reviso el riesgo localmente.
2. Da 2 a 4 pasos accionables para recuperar identidad o reducir dano.
3. Menciona que DPI fisico y evidencia local se usan solo en el dispositivo.
4. Explica como esta misma ruta escala para Guatemala y America Latina sin centralizar CUI.

Devuelve solo JSON valido:
{
  "summary": "explicacion breve en espanol sin identificadores",
  "next_steps": ["paso accionable", "paso accionable"],
  "national_scale_note": "nota de escala nacional y regional sin PII",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
''';
  }

  Future<void> _initialize() async {
    if (_initialized) {
      return;
    }
    await FlutterGemma.initialize(
      huggingFaceToken: huggingFaceToken.trim().isEmpty
          ? null
          : huggingFaceToken.trim(),
      maxDownloadRetries: 10,
    );
    _initialized = true;
  }

  Future<void> _ensureInstalled() async {
    // flutter_gemma stores the file on disk, but the active inference spec is
    // process-local. Calling install is idempotent and re-selects this model.
    await installRuntimeAssets();
  }

  Future<String> _generateJson({required String prompt}) async {
    final model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: preferredBackend,
    );
    try {
      final chat = await model.createChat(
        temperature: 0.2,
        topK: 10,
        topP: 0.9,
        modelType: ModelType.gemma4,
        supportsFunctionCalls: false,
        isThinking: false,
        systemInstruction:
            'Eres ZPK Digital ID. Responde solo JSON valido y no reveles identificadores.',
      );
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();
      final text = switch (response) {
        TextResponse(:final token) => token.trim(),
        ThinkingResponse(:final content) => content.trim(),
        FunctionCallResponse(:final name, :final args) =>
          '{"summary":"Gemma 4 eligio herramienta local $name.","next_steps":["Revisar argumentos redactados: ${args.keys.join(', ')}"],"national_scale_note":"La decision de herramienta se mantuvo local.","safety_review":{"raw_cui_included":false,"needs_human_review":true}}',
        ParallelFunctionCallResponse(:final calls) =>
          '{"summary":"Gemma 4 eligio ${calls.length} herramientas locales.","next_steps":["Revisar llamadas redactadas antes de compartir evidencia."],"national_scale_note":"La decision de herramientas se mantuvo local.","safety_review":{"raw_cui_included":false,"needs_human_review":true}}',
      };
      if (text.isEmpty) {
        throw const FormatException('Flutter Gemma returned no text.');
      }
      return text;
    } finally {
      await model.close();
    }
  }
}
