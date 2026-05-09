import 'dart:async';
import 'dart:convert';

import '../../models/kan_case.dart';
import '../../models/generated_artifact.dart';
import 'agent_reasoner.dart';
import 'agent_step.dart';
import 'agent_tool.dart';
import 'tool_registry.dart';

class AgentLoopConfig {
  const AgentLoopConfig({
    this.maxIterations = 5,
    this.stepDelay = const Duration(milliseconds: 180),
    this.allowReadsPii = false,
    this.fallbackReasoner,
  });

  final int maxIterations;

  /// Delay artificial entre steps en modo determinista. Permite que la UI
  /// muestre el agente "pensando" en vez de aparecer todo de golpe.
  /// En 0 se desactiva (modo Gemma o tests).
  final Duration stepDelay;

  final bool allowReadsPii;

  /// Si el reasoner principal (Gemma) cierra `final` sin haber producido
  /// artifact, o si lanza una excepcion durante la generacion, el loop
  /// switchea a este reasoner para terminar el trabajo. Preserva el
  /// scratchpad acumulado, asi el determinista solo ejecuta los pasos
  /// que faltan en vez de empezar de cero. Implementa la idea
  /// "validate-then-repair" pero a nivel de loop entero, no solo input.
  final AgentReasoner? fallbackReasoner;
}

/// Orquesta el ciclo ReAct. Emite cada paso por el stream para que la UI lo
/// renderice mientras pasa.
///
/// Loop:
///   1. anuncia plan inicial
///   2. pide al reasoner la siguiente decision
///   3. si es tool_call, la ejecuta y emite observation
///   4. si es final, emite FinalStep y cierra
///   5. si excede maxIterations, emite ErrorStep y cierra
Stream<AgentStep> runAgentLoop({
  required CitizenInput input,
  required CaseScenario caseHint,
  required AgentReasoner reasoner,
  required ToolRegistry tools,
  AgentLoopConfig config = const AgentLoopConfig(),
  Map<String, dynamic>? preRedactedInput,
}) async* {
  yield PlanStep(
    'Gemma 4 decide un paso en JSON; el harness valida, repara y ejecuta tools locales.',
  );
  if (config.stepDelay > Duration.zero) {
    await Future<void>.delayed(config.stepDelay);
  }

  final redacted = preRedactedInput ?? input.toRedactedMap();
  yield ObservationStep(
    content: 'Datos sensibles bloqueados antes de enviar contexto al modelo.',
    data: {'fields_in_input': redacted.keys.toList()},
  );

  final scratchpadParts = <String>[];
  GeneratedArtifact? lastArtifact;
  var activeReasoner = reasoner;
  var didFallback = false;

  for (var iteration = 0; iteration < config.maxIterations; iteration++) {
    final ReasonerDecision decision;
    try {
      decision = await activeReasoner.decideNextStep(
        caseHint: caseHint,
        redactedInput: redacted,
        toolsCatalog: tools.describeAllCompact(),
        scratchpad: scratchpadParts.isEmpty ? null : scratchpadParts.join('\n'),
        iteration: iteration,
      );
    } catch (e) {
      // Si tenemos fallback y no lo usamos aun, intentar switch en vez de
      // emitir ErrorStep terminal. Preservamos scratchpad para que el
      // determinista solo haga lo que falta.
      if (!didFallback && config.fallbackReasoner != null) {
        didFallback = true;
        activeReasoner = config.fallbackReasoner!;
        yield ObservationStep(
          content:
              'Harness de robustez activo: la respuesta del modelo fue incompleta; continuo con planner local preservando la traza.',
          data: {'switched_to': activeReasoner.label, 'reason': e.toString()},
        );
        iteration--; // reintenta misma iteracion con el fallback
        continue;
      }
      yield ErrorStep('El razonador no pudo continuar: $e');
      return;
    }

    if (decision.action == 'final') {
      final artifact = decision.artifactSpec?.toArtifact() ?? lastArtifact;
      if (artifact == null) {
        // Gemma quiso cerrar sin haber producido el documento. Si hay
        // fallback, lo activamos para que ejecute los draft_* + sign_packet
        // que faltan en vez de tirar ErrorStep.
        if (!didFallback && config.fallbackReasoner != null) {
          didFallback = true;
          activeReasoner = config.fallbackReasoner!;
          yield ObservationStep(
            content:
                'Harness detecto cierre incompleto: faltaba documento firmado. Continuo con tools locales.',
            data: {'switched_to': activeReasoner.label},
          );
          continue;
        }
        yield ErrorStep(
          'Cierre final sin artifact: ninguna tool produjo documento.',
        );
        return;
      }
      yield FinalStep(
        summary: decision.summary!,
        nextSteps: decision.nextSteps!,
        artifact: artifact,
      );
      return;
    }

    if (decision.action == 'error') {
      // Mismo trato que excepcion: si hay fallback, switch.
      if (!didFallback && config.fallbackReasoner != null) {
        didFallback = true;
        activeReasoner = config.fallbackReasoner!;
        yield ObservationStep(
          content:
              'Harness rechazo salida invalida del modelo y continuo con plan local.',
          data: {
            'switched_to': activeReasoner.label,
            'reason': decision.errorMessage ?? '',
          },
        );
        iteration--;
        continue;
      }
      yield ErrorStep(decision.errorMessage ?? 'sin detalle');
      return;
    }

    if (decision.action == 'tool_call') {
      final toolName = decision.tool!;
      final toolInput = decision.input ?? const <String, dynamic>{};

      yield ToolCallStep(tool: toolName, input: toolInput);
      if (config.stepDelay > Duration.zero) {
        await Future<void>.delayed(config.stepDelay);
      }

      final ToolResult result;
      try {
        result = await tools.call(
          toolName,
          toolInput,
          allowReadsPii: config.allowReadsPii,
        );
      } catch (e) {
        yield ObservationStep(
          content: 'Tool $toolName devolvio error controlado: $e',
          data: {'error': e.toString()},
        );
        scratchpadParts.add('TOOL $toolName -> ERROR ${e.toString()}');
        continue;
      }

      yield ObservationStep(
        content: result.summary ?? _summarize(result.data),
        data: result.data,
      );
      if (config.stepDelay > Duration.zero) {
        await Future<void>.delayed(config.stepDelay);
      }

      scratchpadParts.add('TOOL $toolName -> ${jsonEncode(result.data)}');
      if (result.artifact != null) {
        lastArtifact = _selectArtifact(lastArtifact, result.artifact!);
      } else if (toolName == 'sign_packet' && lastArtifact != null) {
        lastArtifact = _attachSignature(lastArtifact, result.data);
      }
      continue;
    }

    yield ErrorStep('Decision desconocida: ${decision.action}');
    return;
  }

  if (lastArtifact == null) {
    yield ErrorStep(
      'Limite de ${config.maxIterations} pasos alcanzado sin cierre. '
      'Ninguna tool produjo documento.',
    );
    return;
  }

  var artifact = lastArtifact;
  if (artifact.sigEd25519.isEmpty && tools.has('sign_packet')) {
    final signInput = {'contenido': artifact.contenidoMd};
    yield ToolCallStep(tool: 'sign_packet', input: signInput);
    try {
      final result = await tools.call(
        'sign_packet',
        signInput,
        allowReadsPii: config.allowReadsPii,
      );
      artifact = _attachSignature(artifact, result.data);
      yield ObservationStep(
        content: result.summary ?? _summarize(result.data),
        data: result.data,
      );
    } catch (e) {
      yield ObservationStep(
        content: 'No pude firmar automaticamente: $e',
        data: {'error': e.toString()},
      );
    }
  }

  final signed = artifact.sigEd25519.isNotEmpty;
  yield ObservationStep(
    content:
        'Cierre seguro del harness: use el ultimo documento valido y lo firme localmente.',
    data: {
      'artifact_hash': artifact.hashSha256,
      'signed': signed,
      'max_iterations': config.maxIterations,
    },
  );
  yield FinalStep(
    summary: signed
        ? 'Genere el documento y lo firme localmente.'
        : 'Genere el documento. Firma local pendiente.',
    nextSteps: const [
      'Revisa el documento antes de compartirlo.',
      'Presentalo en la institucion correspondiente con tu evidencia.',
    ],
    artifact: artifact,
  );
}

String _summarize(Map<String, dynamic> data) {
  if (data.isEmpty) return 'sin datos';
  final entries = data.entries
      .take(3)
      .map((e) {
        final v = e.value;
        final s = v is String ? v : jsonEncode(v);
        final short = s.length > 60 ? '${s.substring(0, 57)}...' : s;
        return '${e.key}=$short';
      })
      .join(', ');
  return entries;
}

GeneratedArtifact _attachSignature(
  GeneratedArtifact artifact,
  Map<String, dynamic> data,
) {
  final sig = (data['sig'] ?? data['proofValue'] ?? '').toString();
  if (sig.isEmpty) return artifact;
  return artifact.copyWith(sigEd25519: sig);
}

GeneratedArtifact _selectArtifact(
  GeneratedArtifact? previous,
  GeneratedArtifact next,
) {
  if (previous == null) return next;
  if (previous.type != next.type) return next;
  if (previous.contenidoMd.length > next.contenidoMd.length) {
    return previous;
  }
  return next;
}
