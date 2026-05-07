import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/generated_artifact.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/agent/agent_loop.dart';
import 'package:kan_app/services/agent/agent_reasoner.dart';
import 'package:kan_app/services/agent/agent_step.dart';
import 'package:kan_app/services/agent/agent_tool.dart';
import 'package:kan_app/services/agent/tool_registry.dart';

class _StubReasoner implements AgentReasoner {
  _StubReasoner(this.script);
  final List<ReasonerDecision> script;
  int _idx = 0;
  @override
  String get label => 'stub';
  @override
  Future<ReasonerDecision> decideNextStep({
    required CaseScenario caseHint,
    required Map<String, dynamic> redactedInput,
    required String toolsCatalog,
    String? scratchpad,
    int iteration = 0,
  }) async {
    if (_idx >= script.length) {
      return ReasonerDecision.error('script exhausted');
    }
    return script[_idx++];
  }
}

class _EchoTool extends AgentTool {
  _EchoTool(this._name);
  final String _name;
  @override
  String get name => _name;
  @override
  String get description => 'echo $_name';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Future<ToolResult> call(Map<String, dynamic> input) async =>
      ToolResult(data: {'echo': input}, summary: 'echoed');
}

class _PiiTool extends AgentTool {
  @override
  String get name => 'reads_pii_tool';
  @override
  String get description => 'requires pii';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  bool get readsPii => true;
  @override
  Future<ToolResult> call(Map<String, dynamic> input) async =>
      const ToolResult(data: {'ok': true});
}

class _BoomTool extends AgentTool {
  @override
  String get name => 'boom';
  @override
  String get description => 'always fails';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    throw StateError('intentional');
  }
}

class _ArtifactTool extends AgentTool {
  _ArtifactTool({
    this.toolName = 'draft_doc',
    this.content = 'contenido final',
  });

  final String toolName;
  final String content;

  @override
  String get name => toolName;
  @override
  String get description => 'produces a test artifact';
  @override
  bool get producesArtifact => true;
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Future<ToolResult> call(Map<String, dynamic> input) async {
    final artifact = GeneratedArtifact(
      type: 'denuncia_test',
      titulo: 'Denuncia formal para MP',
      contenidoMd: content,
      camposClave: const {'caso': 'test'},
    );
    return ToolResult(
      data: {'hash': artifact.hashSha256},
      artifact: artifact,
      summary: 'documento listo',
    );
  }
}

class _SignTool extends AgentTool {
  @override
  String get name => 'sign_packet';
  @override
  String get description => 'signs a packet';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  Future<ToolResult> call(Map<String, dynamic> input) async => const ToolResult(
    data: {'sig': 'proof-123', 'key_id': 'test-key'},
    summary: 'firmado',
  );
}

void main() {
  late ToolRegistry tools;

  setUp(() {
    tools = ToolRegistry();
    tools.registerAll([
      _EchoTool('alpha'),
      _EchoTool('beta'),
      _PiiTool(),
      _BoomTool(),
    ]);
  });

  test('emite plan y observation iniciales antes de pedir decision', () async {
    final reasoner = _StubReasoner([
      ReasonerDecision.finalResult(
        summary: 'listo',
        nextSteps: const ['paso 1', 'paso 2'],
        artifactSpec: const ArtifactSpec(
          type: 't',
          titulo: 'titulo',
          contenidoMd: 'contenido',
        ),
      ),
    ]);

    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'hola'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(stepDelay: Duration.zero),
    ).toList();

    expect(steps.first, isA<PlanStep>());
    expect(steps[1], isA<ObservationStep>());
    expect(steps.last, isA<FinalStep>());
  });

  test('ejecuta tool y agrega scratchpad antes de cierre final', () async {
    final reasoner = _StubReasoner([
      ReasonerDecision.toolCall(tool: 'alpha', input: const {'k': 'v'}),
      ReasonerDecision.finalResult(
        summary: 'cierre',
        nextSteps: const ['1', '2'],
        artifactSpec: const ArtifactSpec(
          type: 't',
          titulo: 'titulo',
          contenidoMd: 'cuerpo',
        ),
      ),
    ]);

    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'caso'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(stepDelay: Duration.zero),
    ).toList();

    expect(steps.whereType<ToolCallStep>().length, 1);
    expect(steps.whereType<ToolCallStep>().first.tool, 'alpha');
    expect(steps.whereType<FinalStep>().single.summary, 'cierre');
  });

  test('observation con error si tool tira excepcion, loop continua', () async {
    final reasoner = _StubReasoner([
      ReasonerDecision.toolCall(tool: 'boom', input: const {}),
      ReasonerDecision.finalResult(
        summary: 'recuperado',
        nextSteps: const ['a', 'b'],
        artifactSpec: const ArtifactSpec(
          type: 't',
          titulo: 'titulo',
          contenidoMd: 'cuerpo',
        ),
      ),
    ]);

    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'x'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(stepDelay: Duration.zero),
    ).toList();

    final obs = steps.whereType<ObservationStep>().toList();
    expect(obs.any((o) => o.content.contains('Tool boom fallo')), isTrue);
    expect(steps.last, isA<FinalStep>());
  });

  test('respeta maxIterations y emite ErrorStep si no cierra', () async {
    final reasoner = _StubReasoner([
      ReasonerDecision.toolCall(tool: 'alpha', input: const {}),
      ReasonerDecision.toolCall(tool: 'beta', input: const {}),
      ReasonerDecision.toolCall(tool: 'alpha', input: const {}),
    ]);

    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'x'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(maxIterations: 3, stepDelay: Duration.zero),
    ).toList();

    expect(
      steps.whereType<ErrorStep>().any((e) => e.message.contains('Limite')),
      isTrue,
    );
  });

  test('cierre por maxIterations firma ultimo artifact valido', () async {
    tools.registerAll([_ArtifactTool(), _SignTool()]);
    final reasoner = _StubReasoner([
      ReasonerDecision.toolCall(tool: 'draft_doc', input: const {}),
    ]);

    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'x'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(maxIterations: 1, stepDelay: Duration.zero),
    ).toList();

    expect(steps.whereType<ErrorStep>(), isEmpty);
    expect(
      steps.whereType<ToolCallStep>().any((s) => s.tool == 'sign_packet'),
      isTrue,
    );
    final finalStep = steps.whereType<FinalStep>().single;
    expect(finalStep.artifact.titulo, 'Denuncia formal para MP');
    expect(finalStep.artifact.sigEd25519, 'proof-123');
    expect(finalStep.summary, contains('firme localmente'));
  });

  test(
    'conserva artifact mas completo si Gemma repite draft mas debil',
    () async {
      tools.registerAll([
        _ArtifactTool(
          toolName: 'draft_long',
          content: 'contenido con hechos y detalles importantes',
        ),
        _ArtifactTool(toolName: 'draft_short', content: 'contenido'),
      ]);
      final reasoner = _StubReasoner([
        ReasonerDecision.toolCall(tool: 'draft_long', input: const {}),
        ReasonerDecision.toolCall(tool: 'draft_short', input: const {}),
      ]);

      final steps = await runAgentLoop(
        input: const CitizenInput(rawText: 'x'),
        caseHint: CaseScenario.preventive,
        reasoner: reasoner,
        tools: tools,
        config: const AgentLoopConfig(
          maxIterations: 2,
          stepDelay: Duration.zero,
        ),
      ).toList();

      final finalStep = steps.whereType<FinalStep>().single;
      expect(finalStep.artifact.contenidoMd, contains('detalles importantes'));
    },
  );

  test('bloquea tool con readsPii cuando allowReadsPii=false', () async {
    final reasoner = _StubReasoner([
      ReasonerDecision.toolCall(tool: 'reads_pii_tool', input: const {}),
      ReasonerDecision.finalResult(
        summary: 's',
        nextSteps: const ['a', 'b'],
        artifactSpec: const ArtifactSpec(
          type: 't',
          titulo: 'titulo',
          contenidoMd: 'cuerpo',
        ),
      ),
    ]);

    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'x'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(stepDelay: Duration.zero),
    ).toList();

    final obs = steps.whereType<ObservationStep>().toList();
    expect(obs.any((o) => o.content.contains('reads_pii_blocked')), isTrue);
  });

  test('emite ErrorStep y cierra si el reasoner explota', () async {
    final reasoner = _ExplodingReasoner();
    final steps = await runAgentLoop(
      input: const CitizenInput(rawText: 'x'),
      caseHint: CaseScenario.preventive,
      reasoner: reasoner,
      tools: tools,
      config: const AgentLoopConfig(stepDelay: Duration.zero),
    ).toList();
    expect(steps.last, isA<ErrorStep>());
  });
}

class _ExplodingReasoner implements AgentReasoner {
  @override
  String get label => 'boom';
  @override
  Future<ReasonerDecision> decideNextStep({
    required CaseScenario caseHint,
    required Map<String, dynamic> redactedInput,
    required String toolsCatalog,
    String? scratchpad,
    int iteration = 0,
  }) async {
    throw StateError('reasoner kaboom');
  }
}
