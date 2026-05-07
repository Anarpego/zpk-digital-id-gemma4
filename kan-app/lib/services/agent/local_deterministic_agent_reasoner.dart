import 'dart:convert';

import '../../models/kan_case.dart';
import 'agent_reasoner.dart';

/// Plan determinista para el agent loop. Cada paso especifica el tool a
/// invocar y como construir su input a partir del scratchpad acumulado.
class _PlanStep {
  const _PlanStep({required this.tool, required this.buildInput});
  final String tool;
  final Map<String, dynamic> Function(Map<String, dynamic> ctx) buildInput;
}

/// Razonador deterministico que ejecuta secuencias de tools predefinidas
/// segun el caso clasificado. Mismo `Stream<AgentStep>` que produciria Gemma.
class LocalDeterministicAgentReasoner implements AgentReasoner {
  LocalDeterministicAgentReasoner({this.pseudonimo = 'zpk:citizen-local'});

  final String pseudonimo;

  @override
  String get label => 'Plan determinista local';

  @override
  Future<ReasonerDecision> decideNextStep({
    required CaseScenario caseHint,
    required Map<String, dynamic> redactedInput,
    required String toolsCatalog,
    String? scratchpad,
    int iteration = 0,
  }) async {
    final ctx = _parseScratchpad(scratchpad);
    final rawText = (redactedInput['text'] ?? '').toString();

    if (!ctx.containsKey('redact_pii')) {
      return ReasonerDecision.toolCall(
        tool: 'redact_pii',
        input: {'text': rawText},
      );
    }

    if (!ctx.containsKey('classify_case')) {
      final cleanText =
          (ctx['redact_pii']?['redacted_text'] as String?) ?? rawText;
      return ReasonerDecision.toolCall(
        tool: 'classify_case',
        input: {'text': cleanText},
      );
    }

    final classification = ctx['classify_case'];
    final caseCode = (classification?['case_code'] ?? 'unknown').toString();

    final plan = _planFor(caseCode);
    for (final step in plan) {
      if (ctx.containsKey(step.tool)) continue;
      return ReasonerDecision.toolCall(
        tool: step.tool,
        input: step.buildInput(ctx),
      );
    }

    return _finalize(caseCode, ctx);
  }

  List<_PlanStep> _planFor(String caseCode) {
    switch (caseCode) {
      case 'extorsion_telefono_sms':
        // SMS familia primero para que la denuncia sea el ultimo artifact
        // y quede como documento principal del FinalStep.
        return [
          _PlanStep(
            tool: 'lookup_codigo_penal',
            buildInput: (_) => {'category': 'extorsion'},
          ),
          _PlanStep(
            tool: 'lookup_institucion',
            buildInput: (_) => {'code': 'MP'},
          ),
          _PlanStep(
            tool: 'draft_sms_familia',
            buildInput: (_) => {'caso_codigo': 'extorsion_telefono_sms'},
          ),
          _PlanStep(
            tool: 'draft_denuncia',
            buildInput: (ctx) => {
              'institucion_destino': 'MINISTERIO PUBLICO',
              'caso_codigo': 'extorsion',
              'narrativa_redactada':
                  'Persona reporta haber recibido amenazas/extorsion via telefono o SMS. Se conserva evidencia digital localmente.',
              'articulo_cp': (ctx['lookup_codigo_penal']?['article'] ?? '')
                  .toString(),
              'nombre_articulo': (ctx['lookup_codigo_penal']?['name'] ?? '')
                  .toString(),
              'pena': (ctx['lookup_codigo_penal']?['penalty'] ?? '').toString(),
              'pseudonimo': pseudonimo,
              'departamento': 'Guatemala',
            },
          ),
          _PlanStep(
            tool: 'sign_packet',
            buildInput: (ctx) => {
              'contenido': (ctx['draft_denuncia']?['hash'] ?? 'sin-hash')
                  .toString(),
            },
          ),
        ];

      case 'estafa_remesa':
        return [
          _PlanStep(
            tool: 'lookup_codigo_penal',
            buildInput: (_) => {'category': 'estafa'},
          ),
          _PlanStep(
            tool: 'lookup_institucion',
            buildInput: (_) => {'code': 'PROFECO'},
          ),
          _PlanStep(
            tool: 'draft_sms_familia',
            buildInput: (_) => {'caso_codigo': 'estafa_remesa'},
          ),
          _PlanStep(
            tool: 'draft_denuncia',
            buildInput: (ctx) => {
              'institucion_destino': 'DIACO',
              'caso_codigo': 'estafa_remesa',
              'narrativa_redactada':
                  'Persona reporta intento de estafa relacionado con remesa, paquete falso o premio inexistente. Se conserva la captura redactada.',
              'articulo_cp': (ctx['lookup_codigo_penal']?['article'] ?? '')
                  .toString(),
              'nombre_articulo': (ctx['lookup_codigo_penal']?['name'] ?? '')
                  .toString(),
              'pena': (ctx['lookup_codigo_penal']?['penalty'] ?? '').toString(),
              'pseudonimo': pseudonimo,
              'departamento': 'Guatemala',
            },
          ),
          _PlanStep(
            tool: 'sign_packet',
            buildInput: (ctx) => {
              'contenido': (ctx['draft_denuncia']?['hash'] ?? 'sin-hash')
                  .toString(),
            },
          ),
        ];

      case 'igss_sin_dpi':
        return [
          _PlanStep(
            tool: 'lookup_institucion',
            buildInput: (_) => {'code': 'IGSS'},
          ),
          _PlanStep(
            tool: 'draft_solicitud',
            buildInput: (_) => {
              'institucion': 'IGSS',
              'motivo': 'Atencion presencial sin DPI fisico disponible',
              'narrativa_redactada':
                  'Solicito atencion en ventanilla bajo modalidad de intake institucional sin credencial, '
                  'con identificacion alterna y testigo presencial.',
              'sin_dpi': true,
              'pseudonimo': pseudonimo,
              'departamento': 'Guatemala',
            },
          ),
          _PlanStep(
            tool: 'sign_packet',
            buildInput: (ctx) => {
              'contenido': (ctx['draft_solicitud']?['hash'] ?? 'sin-hash')
                  .toString(),
            },
          ),
        ];

      case 'sat_acceso_bloqueado':
        return [
          _PlanStep(
            tool: 'lookup_institucion',
            buildInput: (_) => {'code': 'SAT'},
          ),
          _PlanStep(
            tool: 'draft_solicitud',
            buildInput: (_) => {
              'institucion': 'SAT',
              'motivo': 'Restablecimiento de acceso a Agencia Virtual',
              'narrativa_redactada':
                  'Solicito el restablecimiento del acceso a mi cuenta de Agencia Virtual. '
                  'Confirmo mi identidad presencialmente; no enviare credenciales por canales digitales.',
              'sin_dpi': false,
              'pseudonimo': pseudonimo,
              'departamento': 'Guatemala',
            },
          ),
          _PlanStep(
            tool: 'sign_packet',
            buildInput: (ctx) => {
              'contenido': (ctx['draft_solicitud']?['hash'] ?? 'sin-hash')
                  .toString(),
            },
          ),
        ];

      case 'despido_sin_prestaciones':
        return [
          _PlanStep(
            tool: 'lookup_codigo_trabajo',
            buildInput: (_) => {'situation': 'despido_injustificado'},
          ),
          _PlanStep(
            tool: 'lookup_institucion',
            buildInput: (_) => {'code': 'MTPS'},
          ),
          _PlanStep(
            tool: 'draft_denuncia',
            buildInput: (ctx) => {
              'institucion_destino': 'MINISTERIO DE TRABAJO Y PREVISION SOCIAL',
              'caso_codigo': 'despido_sin_prestaciones',
              'narrativa_redactada':
                  'Persona reporta despido sin pago de prestaciones laborales (indemnizacion, '
                  'aguinaldo proporcional, bono 14 proporcional, vacaciones, salarios pendientes). '
                  'Solicita intervencion de la Inspeccion General de Trabajo.',
              'articulo_cp':
                  (ctx['lookup_codigo_trabajo']?['articles'] is List
                          ? (ctx['lookup_codigo_trabajo']!['articles'] as List)
                                .join(' / ')
                          : '')
                      .toString(),
              'nombre_articulo': (ctx['lookup_codigo_trabajo']?['name'] ?? '')
                  .toString(),
              'pena': (ctx['lookup_codigo_trabajo']?['derecho'] ?? '')
                  .toString(),
              'pseudonimo': pseudonimo,
              'departamento': 'Guatemala',
            },
          ),
          _PlanStep(
            tool: 'sign_packet',
            buildInput: (ctx) => {
              'contenido': (ctx['draft_denuncia']?['hash'] ?? 'sin-hash')
                  .toString(),
            },
          ),
        ];

      default:
        return [
          _PlanStep(
            tool: 'lookup_institucion',
            buildInput: (_) => {'code': 'PDH'},
          ),
          _PlanStep(
            tool: 'draft_solicitud',
            buildInput: (_) => {
              'institucion': 'PDH',
              'motivo': 'Orientacion ante caso no clasificado',
              'narrativa_redactada':
                  'Solicito orientacion ante una situacion que no pude clasificar automaticamente. '
                  'Adjunto narrativa redactada y pido atencion presencial.',
              'sin_dpi': false,
              'pseudonimo': pseudonimo,
              'departamento': 'Guatemala',
            },
          ),
          _PlanStep(
            tool: 'sign_packet',
            buildInput: (ctx) => {
              'contenido': (ctx['draft_solicitud']?['hash'] ?? 'sin-hash')
                  .toString(),
            },
          ),
        ];
    }
  }

  ReasonerDecision _finalize(String caseCode, Map<String, dynamic> ctx) {
    return ReasonerDecision.finalResult(
      summary: _summaryFor(caseCode),
      nextSteps: _nextStepsFor(caseCode, ctx),
      // artifactSpec null: el loop hereda el ultimo artifact producido
      // (draft_denuncia o draft_solicitud), preservando el contenido legal
      // formal completo en vez de un summary recortado.
    );
  }

  String _summaryFor(String caseCode) {
    return switch (caseCode) {
      'extorsion_telefono_sms' =>
        'Detecte un caso de posible extorsion. Genere una denuncia formal para el Ministerio Publico citando el Articulo 261 del Codigo Penal, y un mensaje breve para tu familia indicando que no contesten ni paguen. Todo quedo firmado localmente.',
      'estafa_remesa' =>
        'Detecte una posible estafa de remesa o paquete. Prepare una queja para DIACO bajo el Articulo 263 del Codigo Penal (estafa) y un mensaje para alertar a tu familia. Nada salio del telefono.',
      'igss_sin_dpi' =>
        'Genere una solicitud para IGSS pidiendo atencion presencial sin DPI fisico, en modalidad de intake institucional. La solicitud queda firmada localmente y puedes mostrar el QR en ventanilla.',
      'sat_acceso_bloqueado' =>
        'Genere una solicitud formal para SAT pidiendo el restablecimiento del acceso a Agencia Virtual. Tu identidad se confirma en ventanilla, no por canal digital.',
      'despido_sin_prestaciones' =>
        'Detecte un caso de despido sin prestaciones laborales. Genere una queja para el Ministerio de Trabajo (MTPS) citando los Articulos 76, 78 y 82 del Codigo de Trabajo. La denuncia queda firmada localmente.',
      _ =>
        'No pude clasificar el caso con confianza. Genere una solicitud generica para PDH para orientacion. Recomiendo mas detalle en el siguiente intento.',
    };
  }

  List<String> _nextStepsFor(String caseCode, Map<String, dynamic> ctx) {
    final inst = ctx['lookup_institucion'];
    final phone = (inst?['phone'] ?? '').toString();
    final base = phone.isNotEmpty
        ? ['Llamar a $phone para orientacion previa.']
        : <String>[];

    return switch (caseCode) {
      'extorsion_telefono_sms' => [
        ...base,
        'Imprimir o mostrar el QR de la denuncia en la fiscalia mas cercana.',
        'Enviar el mensaje generado a tu familia por WhatsApp.',
        'No contestar llamadas del numero involucrado; conservar capturas en el dispositivo.',
        'Si hay riesgo inmediato a la vida, llamar al 110 (PNC).',
      ],
      'estafa_remesa' => [
        ...base,
        'No transferir dinero ni dar codigos al supuesto remitente.',
        'Presentar la queja en oficina DIACO con la captura redactada.',
        'Avisar a la remesadora real y a tu banco si compartiste algun dato.',
      ],
      'igss_sin_dpi' => [
        ...base,
        'Acudir a la mesa de IGSS con la solicitud impresa o el QR.',
        'Llevar identificacion alterna (carne escolar, licencia, pasaporte) y un testigo si es posible.',
        'Pedir que se registre la modalidad sin DPI en el expediente.',
      ],
      'sat_acceso_bloqueado' => [
        ...base,
        'Acudir presencialmente a la oficina SAT mas cercana con DPI.',
        'No reingresar credenciales SAT desde enlaces recibidos por SMS o email.',
      ],
      'despido_sin_prestaciones' => [
        ...base,
        'Presentar la queja en la Inspeccion General de Trabajo del MTPS.',
        'Conservar contratos, recibos y mensajes con el patrono como evidencia.',
        'Calcular prestaciones aproximadas con el documento generado y exigir pago formal.',
      ],
      _ => [
        ...base,
        'Llevar la solicitud a la oficina PDH mas cercana para orientacion.',
        'Volver a describir el caso con mas detalle si nada aplica.',
      ],
    };
  }

  Map<String, dynamic> _parseScratchpad(String? scratchpad) {
    final out = <String, dynamic>{};
    if (scratchpad == null || scratchpad.isEmpty) return out;
    for (final line in scratchpad.split('\n')) {
      final m = RegExp(r'^TOOL\s+(\S+)\s+->\s+(.*)$').firstMatch(line);
      if (m == null) continue;
      final tool = m.group(1)!;
      final jsonStr = m.group(2)!;
      try {
        final v = jsonDecode(jsonStr);
        if (v is Map<String, dynamic>) out[tool] = v;
      } catch (_) {
        out[tool] = {'_error': jsonStr};
      }
    }
    return out;
  }
}
