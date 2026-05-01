import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prompt includes experience prior and local breach context', () async {
    final catalog = await LocalBreachCatalog.loadEmbedded();
    final result = catalog.verify('1234567890101');
    final prompt = const ReasonerPromptBuilder().build(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );

    expect(prompt, contains('Reglas aprendidas por experiencia'));
    expect(prompt, contains('Primero confirmar exposicion local'));
    expect(prompt, contains('mintrab-tu-empleo-2026-04'));
    expect(prompt, contains('No pidas mas datos personales'));
  });
}
