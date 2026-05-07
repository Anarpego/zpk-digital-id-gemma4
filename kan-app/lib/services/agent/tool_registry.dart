import 'dart:convert';

import 'agent_tool.dart';

class ToolNotFoundException implements Exception {
  const ToolNotFoundException(this.name);
  final String name;
  @override
  String toString() => 'ToolNotFoundException: $name';
}

class ToolPermissionException implements Exception {
  const ToolPermissionException(this.name, this.reason);
  final String name;
  final String reason;
  @override
  String toString() => 'ToolPermissionException: $name ($reason)';
}

/// Registry centralizado de tools disponibles para el agent loop.
///
/// El reasoner (deterministico o Gemma) consulta [describeAllForPrompt] para
/// saber que tools puede invocar y luego pide ejecucion via [call].
class ToolRegistry {
  ToolRegistry();

  final Map<String, AgentTool> _tools = {};

  void register(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  void registerAll(Iterable<AgentTool> tools) {
    for (final tool in tools) {
      register(tool);
    }
  }

  bool has(String name) => _tools.containsKey(name);

  AgentTool get(String name) {
    final tool = _tools[name];
    if (tool == null) {
      throw ToolNotFoundException(name);
    }
    return tool;
  }

  Iterable<AgentTool> get all => _tools.values;

  Future<ToolResult> call(
    String name,
    Map<String, dynamic> input, {
    bool allowReadsPii = false,
  }) async {
    final tool = get(name);
    if (tool.readsPii && !allowReadsPii) {
      throw ToolPermissionException(name, 'reads_pii_blocked');
    }
    return tool.call(input);
  }

  /// Genera un bloque de texto que describe todas las tools, listo para
  /// inyectar en el prompt de Gemma. Formato JSON-array compacto.
  String describeAllForPrompt() {
    final list = _tools.values.map((tool) {
      return {
        'name': tool.name,
        'description': tool.description,
        'input': tool.inputSchema,
        'reads_pii': tool.readsPii,
        'produces_artifact': tool.producesArtifact,
      };
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  /// Forma ultracompacta del catalogo: una linea por tool. Pensada para
  /// modelos on-device con context window pequeno (Gemma E2B en CPU).
  String describeAllCompact() {
    final lines = <String>[];
    for (final tool in _tools.values) {
      final keys =
          (tool.inputSchema['properties'] as Map?)?.keys.join(',') ?? '';
      lines.add('- ${tool.name}($keys): ${tool.description}');
    }
    return lines.join('\n');
  }
}
