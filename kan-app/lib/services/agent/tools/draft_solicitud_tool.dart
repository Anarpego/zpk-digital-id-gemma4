import '../../../models/generated_artifact.dart';
import '../agent_tool.dart';

/// Genera una solicitud institucional formal (IGSS, SAT, RENAP, MTPS, etc.)
/// firmable y minimizada.
class DraftSolicitudTool extends AgentTool {
  @override
  String get name => 'draft_solicitud';
  @override
  String get description =>
      'Redacta una solicitud institucional formal lista para presentar en ventanilla.';
  @override
  bool get producesArtifact => true;
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'institucion': {'type': 'string'},
      'motivo': {'type': 'string'},
      'narrativa_redactada': {'type': 'string'},
      'pseudonimo': {'type': 'string'},
      'sin_dpi': {'type': 'boolean'},
      'departamento': {'type': 'string'},
    },
    'required': ['institucion', 'motivo'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final institucion = (input['institucion'] ?? 'INSTITUCION').toString();
    final motivo = (input['motivo'] ?? 'tramite').toString();
    final narrativa = (input['narrativa_redactada'] ?? '').toString();
    final pseudo = (input['pseudonimo'] ?? 'zpk:anonimo').toString();
    final sinDpi = (input['sin_dpi'] as bool?) ?? false;
    final departamento = (input['departamento'] ?? 'Guatemala').toString();

    final fecha = DateTime.now();
    final fechaStr = '${fecha.day} de ${_mes(fecha.month)} de ${fecha.year}';

    final dpiBlock = sinDpi
        ? '''
## Atencion sin DPI fisico

Por encontrarme imposibilitado(a) de presentar mi DPI en este momento,
solicito atencion como **intake institucional sin credencial**, segun los
protocolos de inclusion de la institucion. Adjunto identificacion alterna y
testimonio firmado localmente.
'''
        : '';

    final cuerpo =
        '''# SOLICITUD FORMAL

**Dirigida a:** $institucion
**Motivo:** $motivo
**Lugar y fecha:** $departamento, $fechaStr
**Identificador local del solicitante (pseudonimo):** $pseudo

## Detalle de la solicitud

${narrativa.isEmpty ? "Solicito atencion sobre el motivo arriba indicado." : narrativa}
$dpiBlock
## Compromisos del solicitante

- Confirmar identidad en ventanilla mediante el medio acordado.
- Proporcionar unicamente los datos minimos requeridos para el tramite.
- No compartir documentos sensibles por canales digitales inseguros.

## Anexos

- Hash criptografico de esta solicitud (SHA-256).
- Pseudonimo local con prueba de posesion del dispositivo.
- Identificacion alterna disponible en ventanilla.

---

*Generado localmente por ZPK Digital ID. Firma criptografica adjunta.
La identidad real se entrega unicamente en presencia, no por el canal digital.*
''';

    final artifact = GeneratedArtifact(
      type: 'solicitud_${institucion.toLowerCase()}',
      titulo: 'Solicitud para $institucion',
      contenidoMd: cuerpo,
      camposClave: {
        'institucion': institucion,
        'motivo': motivo,
        'fecha': fechaStr,
        'pseudonimo': pseudo,
        if (sinDpi) 'modalidad': 'sin_dpi',
      },
    );

    return ToolResult(
      data: {
        'artifact_type': artifact.type,
        'titulo': artifact.titulo,
        'hash': artifact.hashSha256,
        'longitud_caracteres': cuerpo.length,
        'sin_dpi': sinDpi,
      },
      artifact: artifact,
      summary: 'Solicitud ${artifact.type} lista${sinDpi ? " (sin DPI)" : ""}',
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
}
