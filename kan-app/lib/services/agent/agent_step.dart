import '../../models/generated_artifact.dart';

/// Eventos que el agent loop emite a la UI mientras razona.
///
/// La UI los renderiza en orden como un timeline: planes, llamadas a tools,
/// observaciones, error o resultado final. Cada step lleva timestamp para
/// poder ordenar y para auditoria.
sealed class AgentStep {
  AgentStep() : ts = DateTime.now();

  final DateTime ts;
}

class PlanStep extends AgentStep {
  PlanStep(this.content);
  final String content;
}

class ToolCallStep extends AgentStep {
  ToolCallStep({required this.tool, required this.input});
  final String tool;
  final Map<String, dynamic> input;
}

class ObservationStep extends AgentStep {
  ObservationStep({required this.content, this.data});
  final String content;
  final Map<String, dynamic>? data;
}

class FinalStep extends AgentStep {
  FinalStep({
    required this.summary,
    required this.nextSteps,
    required this.artifact,
  });
  final String summary;
  final List<String> nextSteps;
  final GeneratedArtifact artifact;
}

class ErrorStep extends AgentStep {
  ErrorStep(this.message);
  final String message;
}
