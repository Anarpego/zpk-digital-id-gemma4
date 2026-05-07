import '../../../models/generated_artifact.dart';
import '../agent_tool.dart';

/// Genera el texto formal de una denuncia para Ministerio Publico u otra
/// autoridad guatemalteca, citando articulo del Codigo Penal cuando aplica.
class DraftDenunciaTool extends AgentTool {
  @override
  String get name => 'draft_denuncia';
  @override
  String get description =>
      'Redacta una denuncia formal en espanol para MP/PNC/PDH citando el articulo del Codigo Penal aplicable.';
  @override
  bool get producesArtifact => true;
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'institucion_destino': {'type': 'string'},
      'caso_codigo': {'type': 'string'},
      'narrativa_redactada': {'type': 'string'},
      'articulo_cp': {'type': 'string'},
      'nombre_articulo': {'type': 'string'},
      'pena': {'type': 'string'},
      'pseudonimo': {'type': 'string'},
      'departamento': {'type': 'string'},
    },
    'required': ['institucion_destino', 'caso_codigo', 'narrativa_redactada'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final institucion = _firstString(input, const [
      'institucion_destino',
      'institucion',
      'institution',
      'destino',
    ], fallback: 'MINISTERIO PUBLICO');
    final caso = _firstString(input, const [
      'caso_codigo',
      'case_code',
      'caseCode',
      'category',
    ], fallback: 'caso');
    final narrativa = _firstString(input, const [
      'narrativa_redactada',
      'narrativa',
      'hechos',
      'descripcion',
      'details',
      'original_text',
      'text',
    ], fallback: 'La persona reporta un caso de $caso y solicita apoyo.');
    final articulo = _firstString(input, const [
      'articulo_cp',
      'articulo',
      'article',
    ]);
    final nombreArt = _firstString(input, const [
      'nombre_articulo',
      'nombre',
      'name',
    ]);
    final pena = _firstString(input, const ['pena', 'penalty']);
    final pseudo = _firstString(input, const [
      'pseudonimo',
      'pseudo',
    ], fallback: 'zpk:anonimo');
    final departamento = _firstString(input, const [
      'departamento',
      'department',
    ], fallback: 'Guatemala');

    final fecha = DateTime.now();
    final fechaStr = '${fecha.day} de ${_mes(fecha.month)} de ${fecha.year}';

    final articuloBlock = articulo.isEmpty
        ? ''
        : '\n## Fundamento legal\n\n'
              '$articulo del Codigo Penal de Guatemala (Decreto 17-73): $nombreArt.\n'
              '${pena.isEmpty ? '' : "Pena aplicable: $pena.\n"}';

    final cuerpo =
        '''# DENUNCIA FORMAL

**Dirigida a:** $institucion
**Lugar y fecha:** $departamento, $fechaStr
**Identificador del denunciante (pseudonimo local):** $pseudo

## Hechos

$narrativa
$articuloBlock
## Solicitud

Solicito al $institucion:

1. Recibir formalmente la presente denuncia y otorgar numero de expediente.
2. Iniciar investigacion conforme a la legislacion vigente.
3. Brindar medidas de proteccion si correspondiera.
4. Notificar al denunciante por el medio designado en este expediente.

## Anexos

- Hash criptografico de esta denuncia (SHA-256) generado al momento de firma.
- Identificacion personal disponible en ventanilla.
- Evidencia digital redactada conservada en dispositivo del denunciante.

---

*Documento generado localmente por la app ZPK Digital ID.
La firma criptografica acompana este documento como prueba de integridad.
La identidad real del denunciante se conserva en su dispositivo y se libera
solo cuando el denunciante autoriza expresamente la presentacion fisica.*
''';

    final artifact = GeneratedArtifact(
      type: 'denuncia_$caso',
      titulo: 'Denuncia formal para $institucion',
      contenidoMd: cuerpo,
      camposClave: {
        'institucion': institucion,
        'caso': caso,
        if (articulo.isNotEmpty) 'articulo': articulo,
        'fecha': fechaStr,
        'pseudonimo': pseudo,
      },
    );

    return ToolResult(
      data: {
        'artifact_type': artifact.type,
        'titulo': artifact.titulo,
        'hash': artifact.hashSha256,
        'longitud_caracteres': cuerpo.length,
      },
      artifact: artifact,
      summary: 'Denuncia ${artifact.type} lista (${cuerpo.length} chars)',
    );
  }

  static String _mes(int m) => const [
    '',
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ][m];

  static String _firstString(
    Map<String, dynamic> input,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = input[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }
}
