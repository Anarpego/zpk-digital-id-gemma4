import 'package:cactus/cactus.dart';

import '../config/app_config.dart';
import 'cactus_reasoner.dart';
import 'digital_identity_fabric.dart';
import 'gemma_api_reasoner.dart';
import 'kan_reasoner.dart';
import 'mlkit_gemma_reasoner.dart';
import 'mock_reasoner.dart';

class ReasonerFactory {
  const ReasonerFactory({this.identityFabric = const DigitalIdentityFabric()});

  final DigitalIdentityFabric identityFabric;

  KanReasoner build(AppConfig config) {
    CactusConfig.isTelemetryEnabled = false;

    return switch (config.reasonerMode) {
      ReasonerMode.mock => MockReasoner(identityFabric: identityFabric),
      ReasonerMode.cactus => FallbackReasoner(
        primary: CactusReasoner(
          model: config.cactusModel,
          enableTools: config.cactusEnableTools,
          identityFabric: identityFabric,
        ),
        fallback: MockReasoner(identityFabric: identityFabric),
        primaryLabel: 'cactus:${config.cactusModel}',
        timeout: Duration(seconds: config.cactusTimeoutSeconds),
      ),
      ReasonerMode.gemmaHosted => FallbackReasoner(
        primary: GemmaApiReasoner(
          apiKey: config.geminiApiKey,
          model: config.geminiModel,
          identityFabric: identityFabric,
        ),
        fallback: MockReasoner(identityFabric: identityFabric),
        primaryLabel: 'gemma-api:${config.geminiModel}',
      ),
      ReasonerMode.mlKitGemma => FallbackReasoner(
        primary: MlKitGemmaReasoner(identityFabric: identityFabric),
        fallback: MockReasoner(identityFabric: identityFabric),
        primaryLabel: 'mlkit-gemma:aicore',
        timeout: Duration(seconds: config.mlKitTimeoutSeconds),
      ),
    };
  }
}
