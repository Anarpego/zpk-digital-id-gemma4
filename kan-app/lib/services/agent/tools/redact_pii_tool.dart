import '../agent_tool.dart';

/// Redacta CUI, DPI, telefono, email, direccion del input crudo del ciudadano
/// antes de que cualquier otra tool o reasoner lo vea.
///
/// Es la primera tool del loop. Si esto falla, no se llama a nadie mas.
class RedactPiiTool extends AgentTool {
  static final _digits13 = RegExp(r'(?<!\d)\d{13}(?!\d)');
  static final _phone = RegExp(r'(?<!\d)\d{8}(?!\d)');
  static final _email = RegExp(
    r'[\w.+-]+@[\w-]+\.[\w.-]+',
    caseSensitive: false,
  );
  static final _address = RegExp(
    r'\b(?:zona|calle|avenida|av\.|colonia|barrio|aldea|caserio)\s+[\w\d\s.,-]{3,40}',
    caseSensitive: false,
  );

  @override
  String get name => 'redact_pii';

  @override
  String get description =>
      'Quita DPI/CUI (13 digitos), telefono (8 digitos), email y direcciones del texto antes de razonar.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'text': {'type': 'string'},
    },
    'required': ['text'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final raw = (input['text'] ?? '').toString();
    final categories = <String>[];
    var working = raw;

    if (_digits13.hasMatch(working)) {
      categories.add('dpi_cui');
      working = working.replaceAll(_digits13, '[DPI_REDACTED]');
    }
    if (_email.hasMatch(working)) {
      categories.add('email');
      working = working.replaceAll(_email, '[EMAIL_REDACTED]');
    }
    if (_address.hasMatch(working)) {
      categories.add('direccion');
      working = working.replaceAll(_address, '[DIRECCION_REDACTED]');
    }
    if (_phone.hasMatch(working)) {
      categories.add('telefono');
      working = working.replaceAll(_phone, '[TELEFONO_REDACTED]');
    }

    return ToolResult(
      data: {
        'redacted_text': working,
        'categories': categories,
        'redacted_count': categories.length,
      },
      summary: categories.isEmpty
          ? 'Sin datos sensibles detectados'
          : 'Bloqueado: ${categories.join(", ")}',
    );
  }
}
