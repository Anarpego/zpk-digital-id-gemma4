import '../../models/generated_artifact.dart';

/// Resultado que devuelve una tool al ser invocada por el agent loop.
class ToolResult {
  const ToolResult({required this.data, this.artifact, this.summary});

  /// Datos estructurados que se pasan al modelo en la siguiente vuelta del
  /// loop. Deben ser serializables a JSON.
  final Map<String, dynamic> data;

  /// Si la tool produce un documento concreto (denuncia, solicitud, etc.),
  /// va aqui. Solo las tools con [AgentTool.producesArtifact] pueden setearlo.
  final GeneratedArtifact? artifact;

  /// Resumen humano corto, para mostrar como ObservationStep en la UI.
  final String? summary;
}

/// Contrato comun de las tools del agent loop.
///
/// Una tool es codigo local que el agent puede invocar. Nunca hace red,
/// nunca lee PII bruta sin autorizacion explicita y siempre devuelve datos
/// que se pueden serializar a JSON.
abstract class AgentTool {
  String get name;
  String get description;

  /// JSON-schema-lite del input, para que el modelo sepa que pedir.
  Map<String, dynamic> get inputSchema;

  /// True si la tool necesita acceso a PII bruta (CUI, telefono, direccion).
  /// El loop bloquea estas tools si el modo de privacidad no las permite.
  bool get readsPii => false;

  /// True si la tool genera un GeneratedArtifact en su resultado.
  bool get producesArtifact => false;

  Future<ToolResult> call(Map<String, dynamic> input);
}
