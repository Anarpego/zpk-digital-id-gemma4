import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/mock_reasoner.dart';

void main() {
  test('fallback trace includes a useful primary error detail', () async {
    final reasoner = FallbackReasoner(
      primary: const _ThrowingReasoner(),
      fallback: const MockReasoner(),
      primaryLabel: 'cactus:functiongemma-270m',
    );

    final guidance = await reasoner.explain(
      result: LocalBreachCatalog().verify('1234567890101'),
      scenario: CaseScenario.discoveredVictim,
    );

    expect(
      guidance.toolTrace.first,
      contains('fallback: Bad state: Cactus completion failed'),
    );
  });
}

class _ThrowingReasoner implements KanReasoner {
  const _ThrowingReasoner();

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    throw StateError('Cactus completion failed: model missing');
  }
}
