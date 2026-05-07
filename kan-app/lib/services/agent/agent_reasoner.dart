import '../../models/kan_case.dart';
import '../../models/generated_artifact.dart';

/// Spec de un artifact que el reasoner pide producir al cerrar el loop.
class ArtifactSpec {
  const ArtifactSpec({
    required this.type,
    required this.titulo,
    required this.contenidoMd,
    this.camposClave = const {},
  });

  final String type;
  final String titulo;
  final String contenidoMd;
  final Map<String, String> camposClave;

  GeneratedArtifact toArtifact() => GeneratedArtifact(
    type: type,
    titulo: titulo,
    contenidoMd: contenidoMd,
    camposClave: camposClave,
  );
}

/// Decision atomica que devuelve el reasoner en cada vuelta del loop.
///
/// O pide ejecutar una tool, o cierra con resultado final, o reporta error.
class ReasonerDecision {
  const ReasonerDecision._({
    required this.action,
    this.tool,
    this.input,
    this.summary,
    this.nextSteps,
    this.artifactSpec,
    this.errorMessage,
  });

  factory ReasonerDecision.toolCall({
    required String tool,
    required Map<String, dynamic> input,
  }) => ReasonerDecision._(action: 'tool_call', tool: tool, input: input);

  /// Cierre del loop. Si [artifactSpec] es null, el loop usa el ultimo
  /// artifact producido por una tool durante esta corrida.
  factory ReasonerDecision.finalResult({
    required String summary,
    required List<String> nextSteps,
    ArtifactSpec? artifactSpec,
  }) => ReasonerDecision._(
    action: 'final',
    summary: summary,
    nextSteps: nextSteps,
    artifactSpec: artifactSpec,
  );

  factory ReasonerDecision.error(String message) =>
      ReasonerDecision._(action: 'error', errorMessage: message);

  final String action;
  final String? tool;
  final Map<String, dynamic>? input;
  final String? summary;
  final List<String>? nextSteps;
  final ArtifactSpec? artifactSpec;
  final String? errorMessage;
}

/// Input del ciudadano que llega al loop.
///
/// Puede venir de voz transcrita, foto OCR'd, o texto. PII ya redactada por
/// el privacy_guard antes de construir esta clase.
class CitizenInput {
  const CitizenInput({
    required this.rawText,
    this.scenarioHint,
    this.photoOcrText,
    this.audioTranscript,
    this.metadata = const {},
  });

  final String rawText;
  final CaseScenario? scenarioHint;
  final String? photoOcrText;
  final String? audioTranscript;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toRedactedMap({String? redactedText}) => {
    'text': redactedText ?? rawText,
    if (photoOcrText != null) 'photo_ocr': photoOcrText,
    if (audioTranscript != null) 'audio_transcript': audioTranscript,
    if (scenarioHint != null) 'scenario_hint': scenarioHint!.shortCode,
    ...metadata,
  };
}

/// Contrato que cualquier reasoner del agent loop debe cumplir.
///
/// El [LocalDeterministicAgentReasoner] lo implementa con switch+plan;
/// el reasoner Gemma lo implementa pidiendo JSON al modelo y parseandolo.
abstract class AgentReasoner {
  Future<ReasonerDecision> decideNextStep({
    required CaseScenario caseHint,
    required Map<String, dynamic> redactedInput,
    required String toolsCatalog,
    String? scratchpad,
    int iteration = 0,
  });

  /// Etiqueta humana ("Gemma 4 local", "Plan determinista", etc.) que la UI
  /// muestra como badge sobre el panel del agente.
  String get label;
}
