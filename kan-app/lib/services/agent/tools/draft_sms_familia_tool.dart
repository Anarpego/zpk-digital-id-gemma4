import '../../../models/generated_artifact.dart';
import '../agent_tool.dart';

/// Genera un mensaje breve para WhatsApp/SMS dirigido a la familia,
/// adaptado al caso. Util para extorsion (no contesten, no paguen) y
/// estafas de remesa (no transfieran).
class DraftSmsFamiliaTool extends AgentTool {
  static const _plantillas = <String, String>{
    'extorsion_telefono_sms':
        'Familia: estoy bien. Estoy recibiendo una posible extorsion. '
        'NO contesten llamadas de numeros desconocidos y NO paguen nada. '
        'Estamos preparando denuncia formal con apoyo. Mantengamos calma.',
    'estafa_remesa':
        'Familia: cuidado con un mensaje sospechoso de remesa o paquete. '
        'NO den datos ni transfieran dinero. Si reciben algo similar, '
        'reenvienlo y vamos a verificar antes de actuar.',
    'amenazas_directas':
        'Familia: estoy bien por ahora. Estamos documentando una amenaza. '
        'Por favor avisen si reciben llamadas raras y no compartan datos mios. '
        'Si no respondo en 1 hora, llamen al 110.',
  };

  @override
  String get name => 'draft_sms_familia';
  @override
  String get description =>
      'Genera un mensaje breve (<=320 chars) para enviar a la familia en escenarios de extorsion o estafa de remesa.';
  @override
  bool get producesArtifact => true;
  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'caso_codigo': {'type': 'string'},
    },
    'required': ['caso_codigo'],
  };

  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final caso = (input['caso_codigo'] ?? '').toString();
    final texto = _plantillas[caso] ?? _plantillas['extorsion_telefono_sms']!;

    final artifact = GeneratedArtifact(
      type: 'sms_familia_$caso',
      titulo: 'Mensaje para la familia',
      contenidoMd: texto,
      camposClave: {
        'caso': caso,
        'longitud': texto.length.toString(),
        'canal_sugerido': 'WhatsApp/SMS',
      },
    );

    return ToolResult(
      data: {
        'artifact_type': artifact.type,
        'longitud': texto.length,
        'hash': artifact.hashSha256,
      },
      artifact: artifact,
      summary: 'SMS para familia listo (${texto.length} chars)',
    );
  }
}
