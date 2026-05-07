import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/kan_case.dart';
import 'agent_reasoner.dart';
import 'tool_input_repair.dart';
import 'tool_registry.dart';

/// Adapter que conecta Gemma 4 LiteRT-LM al loop ReAct nuevo.
///
/// Cada llamada a [decideNextStep] hace UN round-trip al modelo nativo
/// pidiendole que devuelva una decision JSON. El loop la ejecuta y vuelve
/// a llamar para el siguiente paso, hasta que Gemma devuelva
/// `{"action":"final",...}`.
///
/// Si Gemma falla (timeout, RAM, JSON invalido tras 1 reintento), devuelve
/// `ReasonerDecision.error(...)` y el agent_loop puede caer al planner
/// deterministico preservando el scratchpad.
class LiteRtGemmaAgentReasoner implements AgentReasoner {
  LiteRtGemmaAgentReasoner({
    required this.modelPath,
    this.modelSha256 = '',
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/litert_gemma'),
    this.timeout = const Duration(seconds: 90),
    ToolRegistry? toolRegistry,
    ToolInputRepair? repair,
    this.onRepair,
  }) : _channel = channel,
       _repair = repair ?? ToolInputRepair(),
       _toolRegistry = toolRegistry;

  final String modelPath;
  final String modelSha256;
  final MethodChannel _channel;
  final Duration timeout;
  final ToolInputRepair _repair;
  final ToolRegistry? _toolRegistry;

  /// Callback para telemetria/observabilidad. Recibe el nombre de la tool,
  /// el outcome del repair y el input final. La UI puede usar esto para
  /// mostrar `tool_input_repaired:redact_pii` como ObservationStep.
  final void Function(String toolName, RepairOutcome outcome)? onRepair;

  @override
  String get label => 'Gemma 4 E2B local';

  @override
  Future<ReasonerDecision> decideNextStep({
    required CaseScenario caseHint,
    required Map<String, dynamic> redactedInput,
    required String toolsCatalog,
    String? scratchpad,
    int iteration = 0,
  }) async {
    final prompt = _buildPrompt(
      caseHint: caseHint,
      redactedInput: redactedInput,
      toolsCatalog: toolsCatalog,
      scratchpad: scratchpad,
      iteration: iteration,
    );

    String text = await _generate(prompt);
    var decision = _tryParse(text);
    if (decision != null) return decision;

    // Reintento: pedir de nuevo aclarando el formato exacto.
    final retryPrompt =
        '$prompt\n\nLa respuesta anterior fue invalida: "$text"\n'
        'Recordatorio: responde SOLO un objeto JSON, sin Markdown, sin texto extra.';
    text = await _generate(retryPrompt);
    decision = _tryParse(text);
    if (decision != null) return decision;

    return ReasonerDecision.error(
      'Gemma no produjo ReAct JSON valido tras 2 intentos: $text',
    );
  }

  Future<String> _generate(String prompt) async {
    final response = await _channel
        .invokeMapMethod<String, Object?>('generate', {
          'modelPath': modelPath,
          'sha256': modelSha256,
          'prompt': prompt,
        })
        .timeout(timeout);
    return (response?['text'] as String?)?.trim() ?? '';
  }

  ReasonerDecision? _tryParse(String text) {
    final cleaned = _stripMarkdownFence(text);
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    final jsonStr = cleaned.substring(start, end + 1);

    final Object? decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    final action = decoded['action'];
    if (action == 'tool_call') {
      final tool = decoded['tool'];
      if (tool is! String) return null;

      // Validate-then-repair: parsea como esta. Si el shape no encaja,
      // recorre los patrones de fallo conocidos para modelos open-source.
      // El registry permite hacer repair informado por el schema de la
      // tool real; sin registry caemos a un check estricto.
      final rawInput = decoded['input'];
      final registry = _toolRegistry;
      if (registry != null && registry.has(tool)) {
        final outcome = _repair.repair(tool: registry.get(tool), raw: rawInput);
        if (!outcome.ok) return null;
        onRepair?.call(tool, outcome);
        return ReasonerDecision.toolCall(tool: tool, input: outcome.input!);
      }
      // Sin registry: solo aceptar input ya bien formado.
      if (rawInput is! Map<String, dynamic>) return null;
      return ReasonerDecision.toolCall(tool: tool, input: rawInput);
    }
    if (action == 'final') {
      final summary = decoded['summary'];
      final next = decoded['next_steps'];
      if (summary is! String || next is! List) return null;
      final nextSteps = next.map((e) => e.toString()).toList(growable: false);
      if (nextSteps.length < 2) return null;
      // El loop hereda el ultimo artifact de las tools si artifactSpec es
      // null. Solo lo armamos si Gemma manda contenido explicito.
      ArtifactSpec? spec;
      final artJson = decoded['artifact'];
      if (artJson is Map<String, dynamic>) {
        final type = artJson['type'];
        final titulo = artJson['titulo'] ?? artJson['title'];
        final contenido = artJson['contenido_md'] ?? artJson['content'];
        if (type is String && titulo is String && contenido is String) {
          spec = ArtifactSpec(
            type: type,
            titulo: titulo,
            contenidoMd: contenido,
          );
        }
      }
      return ReasonerDecision.finalResult(
        summary: summary,
        nextSteps: nextSteps,
        artifactSpec: spec,
      );
    }
    return null;
  }

  String _stripMarkdownFence(String text) {
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```', multiLine: true);
    final m = fence.firstMatch(text);
    if (m != null) return m.group(1)!.trim();
    return text;
  }

  String _buildPrompt({
    required CaseScenario caseHint,
    required Map<String, dynamic> redactedInput,
    required String toolsCatalog,
    required String? scratchpad,
    required int iteration,
  }) {
    final inputText = (redactedInput['text'] ?? redactedInput.toString())
        .toString();
    final scratch = _truncate(scratchpad ?? '(ninguno)', 600);
    final tools = _truncate(toolsCatalog, 700);
    final hint = _nextStepHint(scratchpad);
    return '''Eres agente ZPK GT. Decide UN paso. Solo JSON.
Caso: ${caseHint.shortCode}
Texto: $inputText

Tools:
$tools

Pasos previos:
$scratch

REGLA CRITICA: ANTES de usar "final" tenes que haber llamado draft_denuncia o draft_solicitud (produce el documento) y luego sign_packet (lo firma). Final sin documento = error.
$hint
Formato (uno):
{"action":"tool_call","tool":"<n>","input":{...}}
{"action":"final","summary":"<s>","next_steps":["a","b","c"]}

Decide:''';
  }

  /// Calcula el siguiente paso esperado segun lo que ya se hizo.
  /// Es una nota suave (no fuerza), para guiar a Gemma sin hardcodear.
  String _nextStepHint(String? scratchpad) {
    final s = scratchpad ?? '';
    if (!s.contains('redact_pii')) {
      return 'Sugerencia: el primer paso suele ser redact_pii.';
    }
    if (!s.contains('classify_case')) {
      return 'Sugerencia: ya redactaste, ahora classify_case.';
    }
    final hasDraft =
        s.contains('draft_denuncia') || s.contains('draft_solicitud');
    final hasSign = s.contains('sign_packet');
    if (!hasDraft) {
      return 'Sugerencia: ya clasificaste y miraste articulos, ahora draft_denuncia o draft_solicitud para producir el documento.';
    }
    if (!hasSign) {
      return 'Sugerencia: ya tenes el documento, llama sign_packet para firmarlo.';
    }
    return 'Sugerencia: documento producido y firmado, podes cerrar con "final".';
  }

  String _truncate(String s, int max) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}...';
  }
}
