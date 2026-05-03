import 'package:cactus/cactus.dart';

import '../config/app_config.dart';
import 'cactus_reasoner.dart';
import 'digital_identity_fabric.dart';
import 'flutter_gemma4_reasoner.dart';
import 'gemma_api_reasoner.dart';
import 'kan_reasoner.dart';
import 'litert_gemma_reasoner.dart';
import 'local_deterministic_reasoner.dart';
import 'mlkit_gemma_reasoner.dart';

class ReasonerFactory {
  const ReasonerFactory({this.identityFabric = const DigitalIdentityFabric()});

  final DigitalIdentityFabric identityFabric;

  KanReasoner build(AppConfig config) {
    CactusConfig.isTelemetryEnabled = false;

    return switch (config.reasonerMode) {
      ReasonerMode.local => LocalDeterministicReasoner(
        identityFabric: identityFabric,
      ),
      ReasonerMode.cactus => FallbackReasoner(
        primary: CactusReasoner(
          model: config.cactusModel,
          enableTools: config.cactusEnableTools,
          identityFabric: identityFabric,
        ),
        fallback: LocalDeterministicReasoner(identityFabric: identityFabric),
        primaryLabel: 'cactus:${config.cactusModel}',
        timeout: Duration(seconds: config.cactusTimeoutSeconds),
      ),
      ReasonerMode.gemmaHosted => FallbackReasoner(
        primary: GemmaApiReasoner(
          apiKey: config.geminiApiKey,
          model: config.geminiModel,
          identityFabric: identityFabric,
        ),
        fallback: LocalDeterministicReasoner(identityFabric: identityFabric),
        primaryLabel: 'gemma-api:${config.geminiModel}',
      ),
      ReasonerMode.mlKitGemma => FallbackReasoner(
        primary: MlKitGemmaReasoner(identityFabric: identityFabric),
        fallback: LocalDeterministicReasoner(identityFabric: identityFabric),
        primaryLabel: 'mlkit-gemma:aicore',
        timeout: Duration(seconds: config.mlKitTimeoutSeconds),
      ),
      ReasonerMode.litertGemma => FallbackReasoner(
        primary: LiteRtGemmaReasoner(
          modelPath: config.litertModelPath,
          modelUrl: config.litertModelUrl,
          modelSha256: config.litertModelSha256,
          identityFabric: identityFabric,
        ),
        fallback: LocalDeterministicReasoner(identityFabric: identityFabric),
        primaryLabel: 'litert-gemma:gemma-4-e2b-it',
        timeout: Duration(seconds: config.litertTimeoutSeconds),
      ),
      ReasonerMode.flutterGemma4 => FallbackReasoner(
        primary: FlutterGemma4Reasoner(
          modelUrl: config.flutterGemmaModelUrl,
          modelId: config.flutterGemmaModelId,
          identityFabric: identityFabric,
        ),
        fallback: LocalDeterministicReasoner(identityFabric: identityFabric),
        primaryLabel: 'flutter-gemma4:${config.flutterGemmaModelId}',
        timeout: Duration(seconds: config.flutterGemmaTimeoutSeconds),
      ),
    };
  }
}
