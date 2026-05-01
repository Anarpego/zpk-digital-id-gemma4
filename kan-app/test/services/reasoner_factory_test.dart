import 'package:cactus/cactus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/config/app_config.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/mock_reasoner.dart';
import 'package:kan_app/services/reasoner_factory.dart';

void main() {
  test('default environment uses mock mode', () {
    const config = AppConfig.fromEnvironment();

    expect(config.reasonerMode, ReasonerMode.mock);
    expect(config.cactusModel, 'functiongemma-270m-pro');
    expect(config.cactusTimeoutSeconds, 45);
    expect(config.cactusEnableTools, isTrue);
    expect(config.geminiApiKey, isEmpty);
    expect(config.geminiModel, 'gemma-4-31b-it');
    expect(config.label, 'Mock local');
  });

  test(
    'factory disables Cactus telemetry and keeps mock stable by default',
    () {
      CactusConfig.isTelemetryEnabled = true;

      final reasoner = const ReasonerFactory().build(
        const AppConfig(
          reasonerMode: ReasonerMode.mock,
          cactusModel: 'functiongemma-270m-pro',
          cactusTimeoutSeconds: 45,
          cactusEnableTools: true,
          geminiApiKey: '',
          geminiModel: 'gemma-4-31b-it',
        ),
      );

      expect(CactusConfig.isTelemetryEnabled, isFalse);
      expect(reasoner, isA<MockReasoner>());
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
      ),
    );

    expect(reasoner, isA<FallbackReasoner>());
  });
}
