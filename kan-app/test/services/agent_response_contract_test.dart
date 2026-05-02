import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/agent_response_contract.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('parses structured agent JSON and records safety trace', () {
    final response = const AgentResponseContract().parse(
      text: '''
```json
{
  "summary": "Coincidencia local encontrada con hechos redactados.",
  "next_steps": [
    "Guarde evidencia sin compartir identificadores.",
    "Prepare denuncia preliminar dentro del dispositivo."
  ],
  "national_scale_note": "El mismo flujo puede operar por municipio sin centralizar CUI.",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
```
''',
      result: LocalBreachCatalog().verify('1234567890101'),
    );

    expect(
      response.summary,
      contains('Coincidencia local encontrada con hechos redactados.'),
    );
    expect(response.nextSteps, hasLength(2));
    expect(response.trace, contains('agent_contract.schema(json) -> ok'));
    expect(
      response.trace,
      contains('agent_contract.safety_review(raw_cui=false) -> ok'),
    );
  });

  test('rejects agent response that leaks raw CUI', () {
    expect(
      () => const AgentResponseContract().parse(
        text: '''
{
  "summary": "El CUI 1234567890101 aparece en el caso.",
  "next_steps": ["No hacer nada", "Cerrar caso"],
  "national_scale_note": "Escala local.",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
''',
        result: LocalBreachCatalog().verify('1234567890101'),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects non-json model text', () {
    expect(
      () => const AgentResponseContract().parse(
        text: 'Respuesta libre sin contrato.',
        result: LocalBreachCatalog().verify('1234567890101'),
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
