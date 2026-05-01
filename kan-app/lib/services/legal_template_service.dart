import '../models/kan_case.dart';

class LegalTemplateService {
  const LegalTemplateService();

  String buildComplaint({
    required VerificationResult result,
    required CaseScenario scenario,
  }) {
    final exposure = result.matches.isEmpty
        ? 'no se encontro coincidencia en el catalogo local consultado'
        : 'se encontro coincidencia en ${result.matches.map((m) => m.name).join(', ')}';

    return '''
DENUNCIA PRELIMINAR

Yo, ______________________________, con CUI ${result.cui}, solicito orientacion por posible uso indebido de mis datos personales.

Verificacion local: $exposure.
Flujo seleccionado: ${scenario.label}.

Solicito que se registre mi caso, se me indique la fiscalia competente y se me informe como ampliar la denuncia si aparecen nuevos indicios.

Firma: ______________________
Fecha: ______________________
''';
  }
}
