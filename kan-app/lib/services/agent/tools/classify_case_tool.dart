import '../agent_tool.dart';

/// Clasifica un texto del ciudadano en uno de los casos del Lote 1.
///
/// Es keyword-based, no ML. Por diseno: corre 100% local, deterministico,
/// y suficiente para los 5 casos del demo. Cuando Gemma 4 corre, este
/// tool sigue siendo util como ground-truth verificable.
class ClassifyCaseTool extends AgentTool {
  static final _patterns = <String, List<RegExp>>{
    'extorsion_telefono_sms': [
      RegExp(r'\bextor[sc]ion', caseSensitive: false),
      RegExp(r'\bamenaz', caseSensitive: false),
      RegExp(r'\bmatar(?:me|nos|los)?\b', caseSensitive: false),
      RegExp(r'\bmataba[ns]?\b', caseSensitive: false),
      RegExp(
        r'\bsi no (?:pago|daba|doy|pagaba|entrego|paso)',
        caseSensitive: false,
      ),
      RegExp(r'\bme van a hacer (?:dano|dano|algo)', caseSensitive: false),
      RegExp(r'\bpidi(?:e|o)ndo (?:plata|dinero|pisto)', caseSensitive: false),
      RegExp(r'\bmaras?\b', caseSensitive: false),
      RegExp(r'\bsecuestr', caseSensitive: false),
    ],
    'estafa_remesa': [
      RegExp(
        r'\b(remesa|western\s*union|moneygram|tigo\s*money)',
        caseSensitive: false,
      ),
      RegExp(r'\bpaquete (retenido|detenido)', caseSensitive: false),
      RegExp(r'\bganaste un premio', caseSensitive: false),
      RegExp(r'\bfalso (envio|envio|pago|deposito)', caseSensitive: false),
    ],
    'igss_sin_dpi': [
      RegExp(r'\b(igss|seguro\s*social)\b', caseSensitive: false),
      RegExp(r'\b(no tengo|perdi|me robaron) (mi )?dpi', caseSensitive: false),
      RegExp(r'\bcarne\s*de\s*salud', caseSensitive: false),
      RegExp(r'\bafiliacion (igss|patronal)', caseSensitive: false),
    ],
    'sat_acceso_bloqueado': [
      RegExp(r'\bsat\b', caseSensitive: false),
      RegExp(r'\bnit\b', caseSensitive: false),
      RegExp(r'\bagencia\s*virtual\b', caseSensitive: false),
      RegExp(r'\bbloqueado.*sat|sat.*bloqueado', caseSensitive: false),
    ],
    'despido_sin_prestaciones': [
      RegExp(r'\bdespido\b', caseSensitive: false),
      RegExp(r'\bprestaciones\b', caseSensitive: false),
      RegExp(r'\bliquidacion\b', caseSensitive: false),
      RegExp(r'\bme corrieron\b', caseSensitive: false),
      RegExp(r'\bsin pagar', caseSensitive: false),
    ],
  };

  @override
  String get name => 'classify_case';
  @override
  String get description =>
      'Clasifica el caso del ciudadano en uno de: extorsion_telefono_sms, estafa_remesa, igss_sin_dpi, sat_acceso_bloqueado, despido_sin_prestaciones.';

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
    final text = (input['text'] ?? '').toString();
    final scores = <String, int>{};
    final signals = <String, List<String>>{};

    for (final entry in _patterns.entries) {
      var hits = 0;
      final matched = <String>[];
      for (final re in entry.value) {
        final m = re.firstMatch(text);
        if (m != null) {
          hits++;
          matched.add(m.group(0)!);
        }
      }
      if (hits > 0) {
        scores[entry.key] = hits;
        signals[entry.key] = matched;
      }
    }

    if (scores.isEmpty) {
      return const ToolResult(
        data: {
          'case_code': 'unknown',
          'confidence': 0.0,
          'signals': <String>[],
        },
        summary: 'Sin coincidencia clara',
      );
    }

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final confidence = (best.value / 3.0).clamp(0.0, 1.0);
    return ToolResult(
      data: {
        'case_code': best.key,
        'confidence': confidence,
        'signals': signals[best.key] ?? <String>[],
      },
      summary: '${best.key} (confianza ${(confidence * 100).round()}%)',
    );
  }
}
