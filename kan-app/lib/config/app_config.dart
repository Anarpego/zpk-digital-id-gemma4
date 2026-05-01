enum ReasonerMode { mock, cactus, gemmaHosted, mlKitGemma }

class AppConfig {
  const AppConfig({
    required this.reasonerMode,
    required this.cactusModel,
    required this.cactusTimeoutSeconds,
    required this.cactusEnableTools,
    required this.geminiApiKey,
    required this.geminiModel,
    required this.mlKitTimeoutSeconds,
  });

  const AppConfig.fromEnvironment()
    : reasonerMode =
          const String.fromEnvironment('KAN_REASONER', defaultValue: 'mock') ==
              'cactus'
          ? ReasonerMode.cactus
          : const String.fromEnvironment(
                  'KAN_REASONER',
                  defaultValue: 'mock',
                ) ==
                'gemma-hosted'
          ? ReasonerMode.gemmaHosted
          : const String.fromEnvironment(
                  'KAN_REASONER',
                  defaultValue: 'mock',
                ) ==
                'mlkit-gemma'
          ? ReasonerMode.mlKitGemma
          : ReasonerMode.mock,
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
      );

  final ReasonerMode reasonerMode;
  final String cactusModel;
  final int cactusTimeoutSeconds;
  final bool cactusEnableTools;
  final String geminiApiKey;
  final String geminiModel;
  final int mlKitTimeoutSeconds;

  String get label => switch (reasonerMode) {
    ReasonerMode.mock => 'Mock local',
    ReasonerMode.cactus => 'Cactus local',
    ReasonerMode.gemmaHosted => 'Gemma 4 API',
    ReasonerMode.mlKitGemma => 'ML Kit Gemma local',
  };
}
