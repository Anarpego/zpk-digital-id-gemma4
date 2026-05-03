import 'package:cactus/cactus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/config/app_config.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/local_deterministic_reasoner.dart';
import 'package:kan_app/services/reasoner_factory.dart';

void main() {
  test('default environment uses local deterministic mode', () {
    const config = AppConfig.fromEnvironment();

    expect(config.reasonerMode, ReasonerMode.local);
    expect(config.cactusModel, 'functiongemma-270m-pro');
    expect(config.cactusTimeoutSeconds, 45);
    expect(config.cactusEnableTools, isTrue);
    expect(config.geminiApiKey, isEmpty);
    expect(config.geminiModel, 'gemma-4-31b-it');
    expect(config.mlKitTimeoutSeconds, 120);
    expect(config.litertModelPath, isEmpty);
    expect(config.litertModelUrl, isEmpty);
    expect(config.litertModelSha256, isEmpty);
    expect(config.litertTimeoutSeconds, 180);
    expect(config.flutterGemmaModelUrl, isEmpty);
    expect(config.flutterGemmaModelId, 'gemma-4-E2B-it.litertlm');
    expect(config.flutterGemmaTimeoutSeconds, 300);
    expect(config.label, 'Local deterministic');
  });

  test(
    'factory disables Cactus telemetry and keeps local mode stable by default',
    () {
      CactusConfig.isTelemetryEnabled = true;

      final reasoner = const ReasonerFactory().build(
        const AppConfig(
          reasonerMode: ReasonerMode.local,
          cactusModel: 'functiongemma-270m-pro',
          cactusTimeoutSeconds: 45,
          cactusEnableTools: true,
          geminiApiKey: '',
          geminiModel: 'gemma-4-31b-it',
          mlKitTimeoutSeconds: 120,
          litertModelPath: '',
          litertModelUrl: '',
          litertModelSha256: '',
          litertTimeoutSeconds: 180,
          flutterGemmaModelUrl: '',
          flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
          flutterGemmaTimeoutSeconds: 300,
        ),
      );

      expect(CactusConfig.isTelemetryEnabled, isFalse);
      expect(reasoner, isA<LocalDeterministicReasoner>());
    },
  );

  test('factory wraps Cactus mode with fallback reasoner', () {
    final reasoner = const ReasonerFactory().build(
      const AppConfig(
        reasonerMode: ReasonerMode.cactus,
        cactusModel: 'functiongemma-270m-pro',
        cactusTimeoutSeconds: 45,
        cactusEnableTools: true,
        geminiApiKey: '',
        geminiModel: 'gemma-4-31b-it',
        mlKitTimeoutSeconds: 120,
        litertModelPath: '',
        litertModelUrl: '',
        litertModelSha256: '',
        litertTimeoutSeconds: 180,
        flutterGemmaModelUrl: '',
        flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
        flutterGemmaTimeoutSeconds: 300,
      ),
    );

    expect(reasoner, isA<FallbackReasoner>());
  });

  test('factory wraps hosted Gemma mode with fallback reasoner', () {
    final reasoner = const ReasonerFactory().build(
      const AppConfig(
        reasonerMode: ReasonerMode.gemmaHosted,
        cactusModel: 'functiongemma-270m-pro',
        cactusTimeoutSeconds: 45,
        cactusEnableTools: true,
        geminiApiKey: 'test-key',
        geminiModel: 'gemma-4-31b-it',
        mlKitTimeoutSeconds: 120,
        litertModelPath: '',
        litertModelUrl: '',
        litertModelSha256: '',
        litertTimeoutSeconds: 180,
        flutterGemmaModelUrl: '',
        flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
        flutterGemmaTimeoutSeconds: 300,
      ),
    );

    expect(reasoner, isA<FallbackReasoner>());
  });

  test('factory wraps ML Kit Gemma mode with fallback reasoner', () {
    final reasoner = const ReasonerFactory().build(
      const AppConfig(
        reasonerMode: ReasonerMode.mlKitGemma,
        cactusModel: 'functiongemma-270m-pro',
        cactusTimeoutSeconds: 45,
        cactusEnableTools: true,
        geminiApiKey: '',
        geminiModel: 'gemma-4-31b-it',
        mlKitTimeoutSeconds: 120,
        litertModelPath: '',
        litertModelUrl: '',
        litertModelSha256: '',
        litertTimeoutSeconds: 180,
        flutterGemmaModelUrl: '',
        flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
        flutterGemmaTimeoutSeconds: 300,
      ),
    );

    expect(reasoner, isA<FallbackReasoner>());
  });

  test('factory wraps LiteRT-LM Gemma mode with fallback reasoner', () {
    final reasoner = const ReasonerFactory().build(
      const AppConfig(
        reasonerMode: ReasonerMode.litertGemma,
        cactusModel: 'functiongemma-270m-pro',
        cactusTimeoutSeconds: 45,
        cactusEnableTools: true,
        geminiApiKey: '',
        geminiModel: 'gemma-4-31b-it',
        mlKitTimeoutSeconds: 120,
        litertModelPath: '/sdcard/Download/gemma-4-E2B-it.litertlm',
        litertModelUrl: 'https://example.test/gemma-4-E2B-it.litertlm',
        litertModelSha256: 'abc123',
        litertTimeoutSeconds: 180,
        flutterGemmaModelUrl: '',
        flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
        flutterGemmaTimeoutSeconds: 300,
      ),
    );

    expect(reasoner, isA<FallbackReasoner>());
  });

  test('factory wraps Flutter Gemma 4 mode with fallback reasoner', () {
    final reasoner = const ReasonerFactory().build(
      const AppConfig(
        reasonerMode: ReasonerMode.flutterGemma4,
        cactusModel: 'functiongemma-270m-pro',
        cactusTimeoutSeconds: 45,
        cactusEnableTools: true,
        geminiApiKey: '',
        geminiModel: 'gemma-4-31b-it',
        mlKitTimeoutSeconds: 120,
        litertModelPath: '',
        litertModelUrl: '',
        litertModelSha256: '',
        litertTimeoutSeconds: 180,
        flutterGemmaModelUrl:
            'https://example.test/models/gemma-4-E2B-it.litertlm',
        flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
        flutterGemmaTimeoutSeconds: 300,
      ),
    );

    expect(reasoner, isA<FallbackReasoner>());
  });
}
