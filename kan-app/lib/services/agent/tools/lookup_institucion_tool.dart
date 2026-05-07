import '../agent_tool.dart';

class LookupInstitucionTool extends AgentTool {
  static const _table = <String, Map<String, dynamic>>{
    'MP': {
      'name': 'Ministerio Publico de Guatemala',
      'phone': '1572',
      'web': 'mp.gob.gt',
      'intake':
          'Denuncia presencial o digital. Llevar identificacion y evidencia.',
      'horario': 'Lunes a Viernes 8:00-16:00',
    },
    'PNC': {
      'name': 'Policia Nacional Civil',
      'phone': '110',
      'web': 'pnc.gob.gt',
      'intake':
          'Denuncia inmediata por riesgo de vida. Para extorsion: llamar antes de pagar.',
      'horario': '24/7',
    },
    'IGSS': {
      'name': 'Instituto Guatemalteco de Seguridad Social',
      'phone': '1522',
      'web': 'igssgt.org',
      'intake':
          'Atencion presencial sin DPI: pedir intake institucional con identificacion alterna o testigo.',
      'horario': 'Lunes a Viernes 7:00-15:00',
    },
    'SAT': {
      'name': 'Superintendencia de Administracion Tributaria',
      'phone': '1550',
      'web': 'portal.sat.gob.gt',
      'intake':
          'Restablecimiento de Agencia Virtual: solicitud presencial en oficina con DPI o reposicion temporal.',
      'horario': 'Lunes a Viernes 8:00-16:30',
    },
    'MTPS': {
      'name': 'Ministerio de Trabajo y Prevision Social',
      'phone': '1545',
      'web': 'mintrabajo.gob.gt',
      'intake':
          'Inspeccion General de Trabajo recibe quejas por despidos injustificados y prestaciones no pagadas.',
      'horario': 'Lunes a Viernes 8:00-16:30',
    },
    'PDH': {
      'name': 'Procuraduria de los Derechos Humanos',
      'phone': '1555',
      'web': 'pdh.org.gt',
      'intake':
          'Denuncia por violacion a derechos humanos, atencion a victimas.',
      'horario': 'Lunes a Viernes 8:00-16:00',
    },
    'PROFECO': {
      'name': 'Direccion de Atencion y Asistencia al Consumidor (DIACO)',
      'phone': '1544',
      'web': 'diaco.gob.gt',
      'intake': 'Quejas contra remesadoras, telefonia o comercios.',
      'horario': 'Lunes a Viernes 8:00-16:30',
    },
    'RENAP': {
      'name': 'Registro Nacional de las Personas',
      'phone': '1551',
      'web': 'renap.gob.gt',
      'intake': 'Reposicion DPI, certificaciones, registros vitales.',
      'horario': 'Lunes a Viernes 8:00-17:00',
    },
  };

  @override
  String get name => 'lookup_institucion';
  @override
  String get description =>
      'Devuelve datos de contacto e intake de instituciones guatemaltecas (MP, PNC, IGSS, SAT, MTPS, PDH, PROFECO, RENAP).';
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'code': {
        'type': 'string',
        'enum': ['MP', 'PNC', 'IGSS', 'SAT', 'MTPS', 'PDH', 'PROFECO', 'RENAP'],
      },
    },
    'required': ['code'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final code = (input['code'] ?? '').toString().toUpperCase();
    final entry = _table[code];
    if (entry == null) {
      return ToolResult(
        data: {'found': false, 'code': code},
        summary: 'Institucion no en catalogo',
      );
    }
    return ToolResult(
      data: {'found': true, 'code': code, ...entry},
      summary: '${entry['name']} - tel ${entry['phone']}',
    );
  }
}
