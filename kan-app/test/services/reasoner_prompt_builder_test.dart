import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/privacy_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prompt includes experience prior and local breach context', () async {
    final catalog = await LocalBreachCatalog.loadEmbedded();
    final result = catalog.verify('1234567890101');
    final prompt = await const ReasonerPromptBuilder().build(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );

    expect(prompt, contains('Reglas aprendidas por experiencia'));
    expect(prompt, contains('Primero confirmar exposicion local'));
    expect(prompt, contains('Agente ZPK de proteccion de identidad'));
    expect(prompt, contains('Infraestructura local de identidad'));
    expect(prompt, contains('pseudonimo_ciudadano: emitido_localmente'));
    expect(prompt, contains('prueba_local: firmada_en_dispositivo'));
    expect(prompt, contains('did:zpk:gt:<redacted-local-id>'));
    expect(prompt, isNot(contains('Pseudonimo ciudadano: zpk-gt-')));
    expect(prompt, contains('patron_latam'));
    expect(prompt, contains('boletines_publicos_verificados'));
    expect(prompt, contains('gt-dpi-fraud-ngo-2026-04'));
    expect(prompt, contains('latam-sim-swap-cui-2026-04'));
    expect(prompt, contains('mintrab-tu-empleo-2026-04'));
    expect(prompt, contains('No pidas mas datos'));
    expect(prompt, contains('Responde solo con JSON valido'));
    expect(prompt, contains('"safety_review"'));
    expect(prompt, contains('"raw_cui_included": false'));
    expect(prompt, isNot(contains(result.cui)));
    expect(RegExp(r'(?<!\d)\d{13}(?!\d)').hasMatch(prompt), isFalse);
    expect(
      const PrivacyGuard()
          .requireRedactedModelPrompt(prompt: prompt, result: result)
          .isAllowed,
      isTrue,
    );
  });
}
