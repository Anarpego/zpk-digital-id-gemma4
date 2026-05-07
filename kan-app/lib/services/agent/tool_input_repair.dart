import 'dart:convert';

import 'agent_tool.dart';

/// Repara inputs de tools generados por modelos open-source que no siempre
/// respetan el contrato JSON estricto. Patron validate-then-repair: el
/// schema es el prior, solo gastamos presupuesto de reparacion en los
/// paths donde el schema realmente se quejo.
///
/// Inspirado en la capa de repair que usaron en CommandCodeAI con DeepSeek
/// para superar el modelo cerrado mas grande en tool calling: la mayoria
/// de "open model malo" es harness problem, no capability gap.
///
/// Cuatro fallas finitas y compositivas que vemos repetirse:
///   1. bare string donde el schema espera object/array
///   2. stringified JSON ('"["a","b"]"') en vez del array
///   3. null en campo opcional en vez de omitirlo
///   4. wrapping incorrecto: {} donde se esperaba array
class ToolInputRepair {
  ToolInputRepair();

  /// Devuelve el outcome del intento de reparar [raw] hacia el shape que
  /// espera [tool]. Si raw ya era valido, [outcome] = passthrough.
  RepairOutcome repair({required AgentTool tool, required Object? raw}) {
    // Caso 0: ya es Map<String,dynamic> bien formado -> passthrough.
    if (raw is Map<String, dynamic>) {
      // Repair sub-shape: optional null -> strip, stringified array -> parse.
      final fixed = _repairChildren(tool, Map<String, dynamic>.from(raw));
      if (_mapsEqual(fixed, raw)) {
        return RepairOutcome.passthrough(fixed);
      }
      return RepairOutcome.repaired(
        fixed,
        notes: const ['stripped_nulls_or_unwrapped_substrings'],
      );
    }

    // Caso 1: bare string donde se esperaba object con un solo campo string.
    if (raw is String) {
      final primary = _primaryStringKeyFor(tool);
      if (primary != null) {
        // Antes de wrap, intentar parse como JSON por si el modelo
        // devolvio el objeto stringified.
        final parsed = _tryParseJson(raw);
        if (parsed is Map<String, dynamic>) {
          return RepairOutcome.repaired(
            _repairChildren(tool, parsed),
            notes: const ['parsed_stringified_json_object'],
          );
        }
        return RepairOutcome.repaired(
          {primary: raw},
          notes: ['wrapped_bare_string_as_$primary'],
        );
      }
    }

    // Caso 2: input es null pero la tool acepta inputs vacios.
    if (raw == null) {
      return RepairOutcome.repaired(
        const {},
        notes: const ['null_input_replaced_with_empty_object'],
      );
    }

    // Caso 3: lista en vez de objeto -> intentar mapear a primary key.
    if (raw is List && raw.length == 1) {
      final primary = _primaryStringKeyFor(tool);
      if (primary != null) {
        return RepairOutcome.repaired(
          {primary: raw.first},
          notes: ['unwrapped_singleton_array_to_$primary'],
        );
      }
    }

    return RepairOutcome.unrepairable(
      reason: 'unsupported_input_type:${raw.runtimeType}',
    );
  }

  Map<String, dynamic> _repairChildren(
    AgentTool tool,
    Map<String, dynamic> map,
  ) {
    final out = <String, dynamic>{};
    final props = (tool.inputSchema['properties'] as Map?) ?? const {};
    final required = ((tool.inputSchema['required'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
    for (final entry in map.entries) {
      final value = entry.value;
      // Repair: null en campo no requerido -> strip.
      if (value == null && !required.contains(entry.key)) {
        continue;
      }
      // Repair: stringified array -> parse.
      final propType = (props[entry.key] as Map?)?['type'];
      if (propType == 'array' && value is String) {
        final parsed = _tryParseJson(value);
        if (parsed is List) {
          out[entry.key] = parsed;
          continue;
        }
        // Bare string donde se esperaba array.
        out[entry.key] = [value];
        continue;
      }
      // Repair: stringified object -> parse.
      if (propType == 'object' && value is String) {
        final parsed = _tryParseJson(value);
        if (parsed is Map<String, dynamic>) {
          out[entry.key] = parsed;
          continue;
        }
      }
      out[entry.key] = value;
    }
    return out;
  }

  /// Para tools con un unico campo string requerido, devuelve el nombre
  /// del campo. Permite reparar bare-string -> {primary: string}.
  String? _primaryStringKeyFor(AgentTool tool) {
    final props = (tool.inputSchema['properties'] as Map?) ?? const {};
    final required = ((tool.inputSchema['required'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();
    if (required.length != 1) return null;
    final key = required.first;
    final type = (props[key] as Map?)?['type'];
    if (type == 'string') return key;
    return null;
  }

  Object? _tryParseJson(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Resultado de repair.
class RepairOutcome {
  const RepairOutcome._({
    required this.kind,
    this.input,
    this.notes = const [],
    this.reason,
  });

  factory RepairOutcome.passthrough(Map<String, dynamic> input) =>
      RepairOutcome._(kind: RepairKind.passthrough, input: input);

  factory RepairOutcome.repaired(
    Map<String, dynamic> input, {
    required List<String> notes,
  }) => RepairOutcome._(kind: RepairKind.repaired, input: input, notes: notes);

  factory RepairOutcome.unrepairable({required String reason}) =>
      RepairOutcome._(kind: RepairKind.unrepairable, reason: reason);

  final RepairKind kind;
  final Map<String, dynamic>? input;
  final List<String> notes;
  final String? reason;

  bool get ok => kind != RepairKind.unrepairable;
}

enum RepairKind { passthrough, repaired, unrepairable }
