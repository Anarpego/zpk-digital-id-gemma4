enum ReasonerMode {
  local,
  cactus,
  gemmaHosted,
  mlKitGemma,
  litertGemma,
  flutterGemma4,
}

class AppConfig {
  const AppConfig({
    required this.reasonerMode,
    required this.cactusModel,
    required this.cactusTimeoutSeconds,
    required this.cactusEnableTools,
    required this.geminiApiKey,
    required this.geminiModel,
    required this.mlKitTimeoutSeconds,
    required this.litertModelPath,
    required this.litertModelUrl,
    required this.litertModelSha256,
    required this.litertTimeoutSeconds,
    required this.flutterGemmaModelUrl,
    required this.flutterGemmaModelId,
    required this.flutterGemmaTimeoutSeconds,
  });

  const AppConfig.fromEnvironment()
    : reasonerMode =
          const String.fromEnvironment('KAN_REASONER', defaultValue: 'local') ==
              'cactus'
          ? ReasonerMode.cactus
          : const String.fromEnvironment(
                  'KAN_REASONER',
                  defaultValue: 'local',
                ) ==
                'gemma-hosted'
          ? ReasonerMode.gemmaHosted
          : const String.fromEnvironment(
                  'KAN_REASONER',
                  defaultValue: 'local',
                ) ==
                'mlkit-gemma'
          ? ReasonerMode.mlKitGemma
          : const String.fromEnvironment(
                  'KAN_REASONER',
                  defaultValue: 'local',
                ) ==
                'litert-gemma'
          ? ReasonerMode.litertGemma
          : const String.fromEnvironment(
                  'KAN_REASONER',
                  defaultValue: 'local',
                ) ==
                'flutter-gemma4'
          ? ReasonerMode.flutterGemma4
          : ReasonerMode.local,
      cactusModel = const String.fromEnvironment(
        'KAN_CACTUS_MODEL',
        defaultValue: 'functiongemma-270m-pro',
      ),
      cactusTimeoutSeconds = const int.fromEnvironment(
        'KAN_CACTUS_TIMEOUT_SECONDS',
        defaultValue: 45,
      ),
      cactusEnableTools = const bool.fromEnvironment(
        'KAN_CACTUS_ENABLE_TOOLS',
        defaultValue: true,
      ),
      geminiApiKey = const String.fromEnvironment('KAN_GEMINI_API_KEY'),
      geminiModel = const String.fromEnvironment(
        'KAN_GEMINI_MODEL',
        defaultValue: 'gemma-4-31b-it',
      ),
      mlKitTimeoutSeconds = const int.fromEnvironment(
        'KAN_MLKIT_TIMEOUT_SECONDS',
        defaultValue: 120,
      ),
      litertModelPath = const String.fromEnvironment('KAN_LITERT_MODEL_PATH'),
      litertModelUrl = const String.fromEnvironment('KAN_LITERT_MODEL_URL'),
      litertModelSha256 = const String.fromEnvironment(
        'KAN_LITERT_MODEL_SHA256',
      ),
      litertTimeoutSeconds = const int.fromEnvironment(
        'KAN_LITERT_TIMEOUT_SECONDS',
        defaultValue: 180,
      ),
      flutterGemmaModelUrl = const String.fromEnvironment(
        'KAN_FLUTTER_GEMMA_MODEL_URL',
      ),
      flutterGemmaModelId = const String.fromEnvironment(
        'KAN_FLUTTER_GEMMA_MODEL_ID',
        defaultValue: 'gemma-4-E2B-it.litertlm',
      ),
      flutterGemmaTimeoutSeconds = const int.fromEnvironment(
        'KAN_FLUTTER_GEMMA_TIMEOUT_SECONDS',
        defaultValue: 300,
      );

  final ReasonerMode reasonerMode;
  final String cactusModel;
  final int cactusTimeoutSeconds;
  final bool cactusEnableTools;
  final String geminiApiKey;
  final String geminiModel;
  final int mlKitTimeoutSeconds;
  final String litertModelPath;
  final String litertModelUrl;
  final String litertModelSha256;
  final int litertTimeoutSeconds;
  final String flutterGemmaModelUrl;
  final String flutterGemmaModelId;
  final int flutterGemmaTimeoutSeconds;

  String get label => switch (reasonerMode) {
    ReasonerMode.local => 'Local deterministic',
    ReasonerMode.cactus => 'Cactus local',
    ReasonerMode.gemmaHosted => 'Gemma 4 API',
    ReasonerMode.mlKitGemma => 'ML Kit Gemma local',
    ReasonerMode.litertGemma => 'LiteRT-LM Gemma 4 local',
    ReasonerMode.flutterGemma4 => 'Flutter Gemma 4 local',
  };
}
