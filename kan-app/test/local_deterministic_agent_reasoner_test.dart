import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/agent/agent_loop.dart';
import 'package:kan_app/services/agent/agent_reasoner.dart';
import 'package:kan_app/services/agent/agent_step.dart';
import 'package:kan_app/services/agent/local_deterministic_agent_reasoner.dart';
import 'package:kan_app/services/agent/tool_registry.dart';
import 'package:kan_app/services/agent/tools/classify_case_tool.dart';
import 'package:kan_app/services/agent/tools/draft_denuncia_tool.dart';
import 'package:kan_app/services/agent/tools/draft_sms_familia_tool.dart';
import 'package:kan_app/services/agent/tools/draft_solicitud_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_codigo_penal_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_codigo_trabajo_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_institucion_tool.dart';
import 'package:kan_app/services/agent/tools/redact_pii_tool.dart';
import 'package:kan_app/services/agent/tools/sign_packet_tool.dart';
import 'package:kan_app/services/identity_signer.dart';

ToolRegistry _buildRegistry() {
  final reg = ToolRegistry();
  reg.registerAll([
    RedactPiiTool(),
    ClassifyCaseTool(),
    LookupCodigoPenalTool(),
    LookupCodigoTrabajoTool(),
    LookupInstitucionTool(),
    DraftDenunciaTool(),
    DraftSolicitudTool(),
    DraftSmsFamiliaTool(),
    SignPacketTool(
      signer: const LocalHmacIdentitySigner(
        issuerKeyId: 'test-key',
        issuerSecret: 'test-secret',
      ),
    ),
  ]);
  return reg;
}

Future<List<AgentStep>> _runFor(
  String text, {
  CaseScenario hint = CaseScenario.preventive,
}) async {
  return runAgentLoop(
    input: CitizenInput(rawText: text),
    caseHint: hint,
    reasoner: LocalDeterministicAgentReasoner(),
    tools: _buildRegistry(),
    config: const AgentLoopConfig(stepDelay: Duration.zero, maxIterations: 12),
  ).toList();
}

void main() {
  test('extorsion: loop genera denuncia MP + sms familia firmados', () async {
    final steps = await _runFor(
      'me dijeron que me van a matar si no pago, vienen las maras',
      hint: CaseScenario.extortionThreat,
    );

    final tools = steps.whereType<ToolCallStep>().map((s) => s.tool).toList();
    expect(tools, contains('redact_pii'));
    expect(tools, contains('classify_case'));
    expect(tools, contains('lookup_codigo_penal'));
    expect(tools, contains('lookup_institucion'));
    expect(tools, contains('draft_denuncia'));
    expect(tools, contains('draft_sms_familia'));
    expect(tools, contains('sign_packet'));

    final fin = steps.whereType<FinalStep>().single;
    expect(fin.summary, contains('extorsion'));
    expect(fin.artifact.titulo, contains('MINISTERIO PUBLICO'));
    expect(fin.artifact.contenidoMd, contains('Art. 261'));
    expect(fin.nextSteps.any((s) => s.contains('110')), isTrue);
  });

  test('estafa remesa: genera queja DIACO con Art. 263', () async {
    final steps = await _runFor(
      'me llego un mensaje de Western Union diciendo que tengo un paquete retenido y debo pagar',
    );
    final fin = steps.whereType<FinalStep>().single;
    expect(fin.summary, contains('estafa'));
    expect(fin.artifact.contenidoMd, contains('DIACO'));
    expect(fin.artifact.contenidoMd, contains('Art. 263'));
  });

  test('IGSS sin DPI: genera solicitud con modalidad sin_dpi', () async {
    final steps = await _runFor(
      'perdi mi DPI y necesito atencion IGSS para mi seguro social',
      hint: CaseScenario.igssRegistration,
    );
    final fin = steps.whereType<FinalStep>().single;
    expect(fin.artifact.titulo, contains('IGSS'));
    expect(fin.artifact.contenidoMd, contains('sin DPI'));
    expect(fin.nextSteps.any((s) => s.contains('1522')), isTrue);
  });

  test('SAT bloqueado: genera solicitud para Agencia Virtual', () async {
    final steps = await _runFor(
      'me bloqueo SAT y no puedo entrar a agencia virtual con mi NIT',
    );
    final fin = steps.whereType<FinalStep>().single;
    expect(fin.artifact.titulo, contains('SAT'));
    expect(fin.artifact.contenidoMd, contains('Agencia Virtual'));
  });

  test(
    'despido sin prestaciones: genera queja MTPS con Codigo de Trabajo',
    () async {
      final steps = await _runFor(
        'me corrieron del trabajo sin pagar prestaciones ni liquidacion',
      );
      final fin = steps.whereType<FinalStep>().single;
      expect(fin.artifact.contenidoMd, contains('TRABAJO'));
      expect(fin.artifact.contenidoMd, contains('Art. 76'));
    },
  );

  test('PII en input no aparece en el contenido del artifact final', () async {
    final steps = await _runFor(
      'me llego mensaje de extorsion, mi dpi 1234567890123 y mi tel 55512345',
    );
    final fin = steps.whereType<FinalStep>().single;
    expect(fin.artifact.contenidoMd, isNot(contains('1234567890123')));
    expect(fin.artifact.contenidoMd, isNot(contains('55512345')));
  });

  test('caso desconocido genera solicitud generica para PDH', () async {
    final steps = await _runFor('hola buen dia hace calor');
    final fin = steps.whereType<FinalStep>().single;
    expect(fin.artifact.titulo, contains('PDH'));
  });

  test('todos los pasos llegan al final sin agotar iteraciones', () async {
    final steps = await _runFor('me dijeron que me van a matar si no pago');
    expect(steps.last, isA<FinalStep>());
    expect(steps.whereType<ErrorStep>(), isEmpty);
  });
}
