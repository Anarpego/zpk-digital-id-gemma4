import '../agent_tool.dart';

class LookupCodigoPenalTool extends AgentTool {
  static const _table = <String, Map<String, dynamic>>{
    'extorsion': {
      'article': 'Art. 261',
      'codigo': 'Codigo Penal de Guatemala (Decreto 17-73)',
      'name': 'Extorsion',
      'penalty': 'Prision de 6 a 12 anos',
      'cite':
          'Comete delito de extorsion quien para procurar un lucro injusto u obligar a otro a hacer u omitir algo, le obliga mediante violencia o intimidacion.',
    },
    'estafa': {
      'article': 'Art. 263',
      'codigo': 'Codigo Penal de Guatemala (Decreto 17-73)',
      'name': 'Estafa Propia',
      'penalty': 'Prision de 6 meses a 4 anos y multa',
      'cite':
          'Comete estafa quien induciendo a error a otro mediante ardid o engano lo defraudare en su patrimonio.',
    },
    'amenazas': {
      'article': 'Art. 215',
      'codigo': 'Codigo Penal de Guatemala (Decreto 17-73)',
      'name': 'Amenazas',
      'penalty': 'Prision de 6 meses a 2 anos',
      'cite':
          'Quien amenazare a otro con causarle a el o a sus parientes dentro de los grados de ley, en su persona, honra o bienes, un mal que constituya delito.',
    },
    'violencia_intrafamiliar': {
      'article': 'Decreto 97-96',
      'codigo':
          'Ley para Prevenir, Sancionar y Erradicar la Violencia Intrafamiliar',
      'name': 'Violencia intrafamiliar',
      'penalty': 'Medidas de seguridad y proteccion inmediata',
      'cite':
          'Toda accion u omision que de manera directa o indirecta causare dano o sufrimiento fisico, sexual, psicologico o patrimonial.',
    },
  };

  @override
  String get name => 'lookup_codigo_penal';
  @override
  String get description =>
      'Devuelve articulo, nombre y pena del Codigo Penal de Guatemala para una categoria. Acepta extorsion, estafa, amenazas o violencia_intrafamiliar (tambien acepta case_code completo como extorsion_telefono_sms o estafa_remesa).';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'category': {
        'type': 'string',
        'enum': ['extorsion', 'estafa', 'amenazas', 'violencia_intrafamiliar'],
      },
    },
    'required': ['category'],
  };

  static const _aliases = <String, String>{
    'extorsion_telefono_sms': 'extorsion',
    'estafa_remesa': 'estafa',
    'estafa_empleo': 'estafa',
    'amenazas_directas': 'amenazas',
    'violencia_domestica': 'violencia_intrafamiliar',
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final raw = (input['category'] ?? '').toString();
    final cat = _aliases[raw] ?? raw;
    final entry = _table[cat];
    if (entry == null) {
      return ToolResult(
        data: {'found': false, 'category': raw},
        summary: 'Categoria $raw no encontrada en Codigo Penal de Guatemala',
      );
    }
    return ToolResult(
      data: {'found': true, 'category': cat, ...entry},
      summary: '${entry['article']} ${entry['name']} (Codigo Penal)',
    );
  }
}
