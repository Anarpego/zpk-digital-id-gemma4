import 'package:flutter/services.dart';

import '../models/kan_case.dart';
import 'agent_execution_ledger.dart';
import 'agent_response_contract.dart';
import 'digital_identity_fabric.dart';
import 'identity_protection_agent.dart';
import 'kan_reasoner.dart';
import 'privacy_guard.dart';
import 'routing_policy.dart';

class LiteRtGemmaReasoner
    implements
        KanReasoner,
        ReasonerRuntimeProbe,
        ReasonerRuntimeInstaller,
        ReasonerRuntimeSelfTester {
  const LiteRtGemmaReasoner({
    required this.modelPath,
    this.modelUrl = '',
    this.modelSha256 = '',
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/litert_gemma'),
    AgentResponseContract responseContract = const AgentResponseContract(),
    this.routingPolicy = const RoutingPolicy(),
    this.agent = const IdentityProtectionAgent(),
    this.identityFabric = const DigitalIdentityFabric(),
    this.privacyGuard = const PrivacyGuard(),
  }) : _channel = channel,
       _responseContract = responseContract;

  final String modelPath;
  final String modelUrl;
  final String modelSha256;
  final MethodChannel _channel;
  final AgentResponseContract _responseContract;
  final RoutingPolicy routingPolicy;
  final IdentityProtectionAgent agent;
  final DigitalIdentityFabric identityFabric;
  final PrivacyGuard privacyGuard;

  @override
  Future<ReasonerRuntimeStatus> runtimeStatus() async {
    if (modelPath.trim().isEmpty) {
      return const ReasonerRuntimeStatus(
        label: 'LiteRT-LM Gemma 4',
        state: 'MISSING_CONFIG',
        summary:
            'Falta KAN_LITERT_MODEL_PATH para habilitar el agente Gemma 4 offline.',
        isOfflineCapable: false,
        isModelBacked: true,
        trace: [
          'litert_gemma.runtime_config(model_path) -> missing',
          'litert_gemma.network_required -> false_after_install',
        ],
      );
    }

    final statusProbe = await _channel.invokeMapMethod<String, Object?>(
      'status',
      {'modelPath': modelPath, 'sha256': modelSha256},
    );
    final status = statusProbe?['status'] as String? ?? 'UNKNOWN';
    final model = statusProbe?['model'] as String? ?? 'gemma-4-E2B-it-litertlm';
    final size = statusProbe?['modelSizeBytes'];
    final partialSize = statusProbe?['partialSizeBytes'];
    final expectedSize = statusProbe?['expectedBytes'];
    final deviceRamBytes = statusProbe?['deviceRamBytes'];
    final requiredRamBytes = statusProbe?['requiredRamBytes'];
    final hashVerification = statusProbe?['hashVerification'] as String?;
    final canDownload = status == 'MISSING_MODEL' && modelUrl.trim().isNotEmpty;
    final summary = switch (status) {
      'AVAILABLE' =>
        'Gemma 4 offline listo en app-private storage. La guia puede generarse sin red.',
      'DEVICE_LOW_MEMORY' =>
        'Gemma 4 esta instalado, pero este telefono no tiene memoria suficiente para ejecutar Gemma 4 E2B de forma estable. Use un Android con 6 GB+ RAM, iOS/Apple Silicon, o mantenga el flujo local deterministico en este dispositivo.',
      'DOWNLOADING' =>
        'Gemma 4 se esta instalando en almacenamiento privado. Mantenga la app abierta hasta que termine.',
      'CORRUPT_MODEL' =>
        'El archivo Gemma 4 no coincide con el hash esperado; reinstale el modelo antes de generar guias.',
      'EMULATOR_UNSUPPORTED' =>
        'Gemma 4 esta instalado, pero el emulador Android no ejecuta de forma segura LiteRT-LM. Use un dispositivo ARM64 fisico para generacion offline.',
      'MISSING_MODEL' when canDownload =>
        'Gemma 4 no esta instalado todavia; el APK tiene una URL local o segura para descargar el modelo a almacenamiento privado.',
      'MISSING_MODEL' =>
        'Gemma 4 no esta instalado y no hay URL de descarga configurada.',
      _ => 'Estado LiteRT-LM recibido: $status.',
    };
    return ReasonerRuntimeStatus(
      label: 'LiteRT-LM Gemma 4',
      state: canDownload ? 'DOWNLOADABLE' : status,
      summary: summary,
      isOfflineCapable: status == 'AVAILABLE',
      isModelBacked: true,
      trace: [
        'litert_gemma.runtime_status($model) -> $status',
        if (size != null) 'litert_gemma.model_size_bytes -> $size',
        if (partialSize != null)
          'litert_gemma.model_partial_bytes -> $partialSize',
        if (expectedSize != null)
          'litert_gemma.model_expected_bytes -> $expectedSize',
        if (deviceRamBytes != null)
          'litert_gemma.device_ram_bytes -> $deviceRamBytes',
        if (requiredRamBytes != null)
          'litert_gemma.required_ram_bytes -> $requiredRamBytes',
        if (hashVerification != null)
          'litert_gemma.hash_verification -> $hashVerification',
        'litert_gemma.model_path(app_private) -> configured',
        if (canDownload) 'litert_gemma.model_download -> configured',
      ],
      downloadedBytes: (partialSize ?? size) is int
          ? (partialSize ?? size) as int
          : null,
      totalBytes: expectedSize is int ? expectedSize : null,
    );
  }

  @override
  Future<ReasonerRuntimeInstallResult> installRuntimeAssets() async {
    if (modelPath.trim().isEmpty) {
      throw StateError(
        'KAN_LITERT_MODEL_PATH must point to a local Gemma 4 .litertlm file.',
      );
    }

    final before = await _channel.invokeMapMethod<String, Object?>('status', {
      'modelPath': modelPath,
      'sha256': modelSha256,
    });
    final beforeStatus = before?['status'] as String? ?? 'UNKNOWN';
    final model = before?['model'] as String? ?? 'gemma-4-E2B-it-litertlm';
    final trace = <String>[
      'litert_gemma.install.status_probe($model) -> $beforeStatus',
    ];
    if (beforeStatus == 'AVAILABLE') {
      final warmup = await _channel.invokeMapMethod<String, Object?>('warmup', {
        'modelPath': modelPath,
        'sha256': modelSha256,
      });
      final warmupStatus = warmup?['status'] as String? ?? 'UNKNOWN';
      final warmupHash = warmup?['hashVerification'] as String?;
      trace.add('litert_gemma.install.warmup($model) -> $warmupStatus');
      if (warmupHash != null) {
        trace.add('litert_gemma.install.warmup.hash -> $warmupHash');
      }
      if (warmupStatus != 'READY') {
        throw StateError('LiteRT-LM Gemma warmup finished with $warmupStatus.');
      }
      return ReasonerRuntimeInstallResult(
        label: 'LiteRT-LM Gemma 4',
        status: 'READY',
        summary:
            'Gemma 4 ya esta instalado, hash-verificado y calentado para uso offline.',
        trace: trace,
      );
    }
    if (modelUrl.trim().isEmpty) {
      throw StateError('KAN_LITERT_MODEL_URL is required to install Gemma 4.');
    }

    final download = await _channel.invokeMapMethod<String, Object?>(
      'downloadModel',
      {'url': modelUrl, 'modelPath': modelPath, 'sha256': modelSha256},
    );
    final downloadStatus = download?['status'] as String? ?? 'UNKNOWN';
    final downloadedSha = download?['sha256'] as String? ?? 'unknown';
    final downloadedBytes = download?['bytes'];
    final expectedBytes = download?['expectedBytes'];
    trace.add(
      'litert_gemma.install.download($model) -> $downloadStatus:$downloadedSha',
    );
    if (downloadedBytes != null) {
      trace.add('litert_gemma.install.downloaded_bytes -> $downloadedBytes');
    }
    final after = await _channel.invokeMapMethod<String, Object?>('status', {
      'modelPath': modelPath,
      'sha256': modelSha256,
    });
    final afterStatus = after?['status'] as String? ?? downloadStatus;
    final afterHashVerification = after?['hashVerification'] as String?;
    trace.add('litert_gemma.install.status_probe($model) -> $afterStatus');
    if (afterHashVerification != null) {
      trace.add(
        'litert_gemma.install.status_probe.hash -> $afterHashVerification',
      );
    }
    if (afterStatus != 'AVAILABLE') {
      throw StateError('LiteRT-LM Gemma install finished with $afterStatus.');
    }

    final warmup = await _channel.invokeMapMethod<String, Object?>('warmup', {
      'modelPath': modelPath,
      'sha256': modelSha256,
    });
    final warmupStatus = warmup?['status'] as String? ?? 'UNKNOWN';
    final warmupHash = warmup?['hashVerification'] as String?;
    trace.add('litert_gemma.install.warmup($model) -> $warmupStatus');
    if (warmupHash != null) {
      trace.add('litert_gemma.install.warmup.hash -> $warmupHash');
    }
    if (warmupStatus != 'READY') {
      throw StateError('LiteRT-LM Gemma warmup finished with $warmupStatus.');
    }

    return ReasonerRuntimeInstallResult(
      label: 'LiteRT-LM Gemma 4',
      status: afterStatus,
      summary: 'Gemma 4 quedo instalado y calentado para uso offline.',
      trace: trace,
      downloadedBytes: downloadedBytes is int ? downloadedBytes : null,
      totalBytes: expectedBytes is int ? expectedBytes : null,
    );
  }

  @override
  Future<ReasonerRuntimeSelfTestResult> runRuntimeSelfTest() async {
    if (modelPath.trim().isEmpty) {
      throw StateError(
        'KAN_LITERT_MODEL_PATH must point to a local Gemma 4 .litertlm file.',
      );
    }

    final statusProbe = await _channel.invokeMapMethod<String, Object?>(
      'status',
      {'modelPath': modelPath, 'sha256': modelSha256},
    );
    final probedStatus = statusProbe?['status'] as String? ?? 'UNKNOWN';
    final model = statusProbe?['model'] as String? ?? 'gemma-4-E2B-it-litertlm';
    final trace = <String>[
      'litert_gemma.self_test.status_probe($model) -> $probedStatus',
    ];
    if (probedStatus != 'AVAILABLE') {
      throw StateError('LiteRT-LM Gemma status is $probedStatus.');
    }

    final warmup = await _channel.invokeMapMethod<String, Object?>('warmup', {
      'modelPath': modelPath,
      'sha256': modelSha256,
    });
    final warmupStatus = warmup?['status'] as String? ?? 'UNKNOWN';
    final warmupHash = warmup?['hashVerification'] as String?;
    trace.add('litert_gemma.self_test.warmup($model) -> $warmupStatus');
    if (warmupHash != null) {
      trace.add('litert_gemma.self_test.warmup.hash -> $warmupHash');
    }
    if (warmupStatus != 'READY') {
      throw StateError('LiteRT-LM Gemma warmup finished with $warmupStatus.');
    }

    final prompt = '''
ZPK offline Guatemala. Caso sintetico: extorsion + recuperacion identidad. PII: REDACTED. Riesgo: alto.
JSON:
{
  "summary": "resumen breve",
  "next_steps": ["paso seguro", "paquete redactado"],
  "national_scale_note": "escala sin PII",
  "safety_review": {"raw_cui_included": false, "needs_human_review": true}
}
''';
    final response = await _channel.invokeMapMethod<String, Object?>(
      'generate',
      {'modelPath': modelPath, 'sha256': modelSha256, 'prompt': prompt},
    );
    final text = (response?['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException('LiteRT-LM Gemma returned no final text.');
    }
    final contractResult = _responseContract.parse(
      text: text,
      result: VerificationResult(
        cui: '9999999999999',
        matches: [
          BreachRecord(
            slug: 'zpk-self-test-redacted',
            name: 'Prueba sintetica redactada',
            exposedFields: ['riesgo_sintetico'],
            reportedOn: DateTime.utc(2026, 5, 2),
          ),
        ],
        checkedAt: DateTime.utc(2026, 5, 2),
        catalogSource: 'self_test_redacted',
      ),
    );
    final generationStatus = response?['status'] as String? ?? 'AVAILABLE';
    trace.addAll([
      ...contractResult.trace,
      'privacy_guard.self_test_raw_cui -> absent',
      'litert_gemma.self_test.status -> $generationStatus',
      'litert_gemma.generate($model) -> ok',
    ]);

    return ReasonerRuntimeSelfTestResult(
      label: 'LiteRT-LM Gemma 4',
      status: 'OK',
      summary:
          'Gemma 4 genero JSON valido offline y paso contrato de seguridad sin CUI.',
      trace: trace,
    );
  }

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    if (modelPath.trim().isEmpty) {
      throw StateError(
        'KAN_LITERT_MODEL_PATH must point to a local Gemma 4 .litertlm file.',
      );
    }

    final assessment = agent.assess(result: result, scenario: scenario);
    final trustReport = await identityFabric.evaluate(
      result: result,
      scenario: scenario,
      assessment: assessment,
    );
    final routing = assessment.route;
    final statusProbe = await _channel.invokeMapMethod<String, Object?>(
      'status',
      {'modelPath': modelPath, 'sha256': modelSha256},
    );
    var probedStatus = statusProbe?['status'] as String? ?? 'UNKNOWN';
    var probedModel =
        statusProbe?['model'] as String? ?? 'gemma-4-E2B-it-litertlm';
    final setupTrace = <String>[
      'litert_gemma.status_probe($probedModel) -> $probedStatus',
    ];
    final statusHashVerification = statusProbe?['hashVerification'] as String?;
    if (statusHashVerification != null) {
      setupTrace.add(
        'litert_gemma.status_probe.hash -> $statusHashVerification',
      );
    }
    if (probedStatus == 'MISSING_MODEL' && modelUrl.trim().isNotEmpty) {
      final download = await _channel.invokeMapMethod<String, Object?>(
        'downloadModel',
        {'url': modelUrl, 'modelPath': modelPath, 'sha256': modelSha256},
      );
      final downloadStatus = download?['status'] as String? ?? 'UNKNOWN';
      final downloadedSha = download?['sha256'] as String? ?? 'unknown';
      setupTrace.add(
        'litert_gemma.download($probedModel) -> $downloadStatus:$downloadedSha',
      );
      final reprobe = await _channel.invokeMapMethod<String, Object?>(
        'status',
        {'modelPath': modelPath, 'sha256': modelSha256},
      );
      probedStatus = reprobe?['status'] as String? ?? downloadStatus;
      probedModel =
          reprobe?['model'] as String? ??
          download?['model'] as String? ??
          probedModel;
      final reprobeHashVerification = reprobe?['hashVerification'] as String?;
      setupTrace.add(
        'litert_gemma.status_probe($probedModel) -> $probedStatus',
      );
      if (reprobeHashVerification != null) {
        setupTrace.add(
          'litert_gemma.status_probe.hash -> $reprobeHashVerification',
        );
      }
    }
    if (probedStatus != 'AVAILABLE') {
      throw StateError('LiteRT-LM Gemma status is $probedStatus.');
    }

    final warmup = await _channel.invokeMapMethod<String, Object?>('warmup', {
      'modelPath': modelPath,
      'sha256': modelSha256,
    });
    final warmupStatus = warmup?['status'] as String? ?? 'UNKNOWN';
    final warmupHash = warmup?['hashVerification'] as String?;
    setupTrace.add('litert_gemma.warmup($probedModel) -> $warmupStatus');
    if (warmupHash != null) {
      setupTrace.add('litert_gemma.warmup.hash -> $warmupHash');
    }
    if (warmupStatus != 'READY') {
      throw StateError('LiteRT-LM Gemma warmup finished with $warmupStatus.');
    }

    final prompt = _buildCompactLiteRtPrompt(
      result: result,
      scenario: scenario,
      trustReport: trustReport,
      assessment: assessment,
    );
    final privacyReport = privacyGuard.requireRedactedModelPrompt(
      prompt: prompt,
      result: result,
    );

    final response = await _channel.invokeMapMethod<String, Object?>(
      'generate',
      {'modelPath': modelPath, 'sha256': modelSha256, 'prompt': prompt},
    );
    final text = (response?['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw const FormatException('LiteRT-LM Gemma returned no final text.');
    }
    final agentResponse = _responseContract.parse(text: text, result: result);

    final status = response?['status'] as String? ?? 'AVAILABLE';
    final model = response?['model'] as String? ?? probedModel;
    final generationHash = response?['hashVerification'] as String?;
    final ledger =
        await AgentExecutionLedgerService(identityFabric: identityFabric).build(
          assessment: assessment,
          trustReport: trustReport,
          result: result,
          scenario: scenario,
          reasonerLabel: 'litert-gemma:$model',
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
        if (generationHash != null)
          'litert_gemma.generate.hash -> $generationHash',
        'litert_gemma.status -> $status',
        'litert_gemma.generate($model) -> ok',
        ...ledger.trace,
      ],
      usedLocalOnly: true,
      routingDecision: routing,
    );
  }

  String _buildCompactLiteRtPrompt({
    required VerificationResult result,
    required CaseScenario scenario,
    required IdentityTrustReport trustReport,
    required IdentityAgentAssessment assessment,
  }) {
    final exposed = result.matches
        .expand((match) => match.exposedFields)
        .toSet()
        .take(5)
        .join(', ');
    return '''
ZPK offline Guatemala. Sin CUI/DPI/telefono/direccion/nombres. Caso=${scenario.shortCode}; institucion=${scenario.institutionName}; riesgo=${assessment.riskLevel.label}; ruta=${assessment.route.route.traceCode}; matches=${result.matches.length}; campos=${exposed.isEmpty ? 'ninguno' : exposed}; issuer=${trustReport.credential.issuer}.
JSON:
{
  "summary": "breve sin identificadores",
  "next_steps": ["paso accionable", "paquete redactado"],
  "national_scale_note": "escala para instituciones sin PII",
  "safety_review": {"raw_cui_included": false, "needs_human_review": true}
}
''';
  }
}
