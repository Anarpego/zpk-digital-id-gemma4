import '../agent_tool.dart';

class LookupCodigoTrabajoTool extends AgentTool {
  static const _table = <String, Map<String, dynamic>>{
    'despido_injustificado': {
      'articles': ['Art. 76', 'Art. 78', 'Art. 82'],
      'codigo': 'Codigo de Trabajo de Guatemala (Decreto 1441)',
      'name': 'Despido injustificado',
      'derecho':
          'Indemnizacion por tiempo servido, aguinaldo proporcional, bono 14 proporcional, vacaciones no gozadas, salarios pendientes.',
    },
    'prestaciones_no_pagadas': {
      'articles': ['Art. 76', 'Art. 102'],
      'codigo': 'Codigo de Trabajo de Guatemala (Decreto 1441)',
      'name': 'Prestaciones laborales no pagadas',
      'derecho':
          'Pago de prestaciones adeudadas con intereses; queja ante Inspeccion General de Trabajo (MTPS).',
    },
    'jornada_excesiva': {
      'articles': ['Art. 116', 'Art. 121'],
      'codigo': 'Codigo de Trabajo de Guatemala (Decreto 1441)',
      'name': 'Jornada laboral excesiva',
      'derecho':
          'Pago de horas extras al 50% adicional; descanso semanal obligatorio.',
    },
  };

  @override
  String get name => 'lookup_codigo_trabajo';
  @override
  String get description =>
      'Devuelve articulos del Codigo de Trabajo aplicables a una situacion conocida (despido injustificado, prestaciones no pagadas, etc.).';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'situation': {
        'type': 'string',
        'enum': [
          'despido_injustificado',
          'prestaciones_no_pagadas',
          'jornada_excesiva',
        ],
      },
    },
    'required': ['situation'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final s = (input['situation'] ?? '').toString();
    final entry = _table[s];
    if (entry == null) {
      return ToolResult(
        data: {'found': false, 'situation': s},
        summary: 'Situacion no mapeada',
      );
    }
    return ToolResult(
      data: {'found': true, 'situation': s, ...entry},
      summary: '${entry['name']} (${(entry['articles'] as List).join(", ")})',
    );
  }
}
