import 'package:cactus/cactus.dart';

import '../config/app_config.dart';
import 'cactus_reasoner.dart';
import 'gemma_api_reasoner.dart';
import 'kan_reasoner.dart';
import 'mlkit_gemma_reasoner.dart';
import 'mock_reasoner.dart';

class ReasonerFactory {
  const ReasonerFactory();

  KanReasoner build(AppConfig config) {
    CactusConfig.isTelemetryEnabled = false;

    return switch (config.reasonerMode) {
      ReasonerMode.mock => const MockReasoner(),
      ReasonerMode.cactus => FallbackReasoner(
        primary: CactusReasoner(
          model: config.cactusModel,
          enableTools: config.cactusEnableTools,
        ),
        fallback: const MockReasoner(),
        primaryLabel: 'cactus:${config.cactusModel}',
        timeout: Duration(seconds: config.cactusTimeoutSeconds),
      ),
      ReasonerMode.gemmaHosted => FallbackReasoner(
        primary: GemmaApiReasoner(
          apiKey: config.geminiApiKey,
          model: config.geminiModel,
        ),
        fallback: const MockReasoner(),
        primaryLabel: 'gemma-api:${config.geminiModel}',
      ),
      ReasonerMode.mlKitGemma => FallbackReasoner(
        primary: const MlKitGemmaReasoner(),
        fallback: const MockReasoner(),
        primaryLabel: 'mlkit-gemma:aicore',
        timeout: Duration(seconds: config.mlKitTimeoutSeconds),
      ),
    };
  }
}
