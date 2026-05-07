# Como hacer que un modelo open-source sea agentico de verdad en el telefono

Notas tecnicas sobre el harness alrededor de un modelo small (~2B
parametros efectivos) corriendo on-device en CPU, manejando un loop
ReAct con tool calling. El objetivo no es entrenar un modelo mejor: es
construir el contrato a su alrededor de manera que rinda mejor sin
tocar pesos.

---

## La premisa que cambia todo

Cuando un modelo open-source falla haciendo tool calls, la conclusion
facil es "este modelo no sabe tool calling, es chico, hay que esperar
a que salga uno mas grande". Esa lectura te hace perder seis meses.

La lectura mas util es: **lo que parece deficit de capacidad casi
siempre es contrato fragil**. Un schema estricto filtra ruido, pero
tambien filtra **ruido recuperable** — variaciones en el output del
modelo que estan a un parser tolerante de ser exactamente lo que
necesitabas.

Los modelos cerrados grandes (Opus, Sonnet, GPT-4) absorben ese costo
de manera invisible porque vieron suficientes contratos durante
pretraining. Los modelos open-source pequenos lo pagan a pleno y los
ingenieros los tachan de "malos en tool calling" cuando en realidad lo
que falta es trabajo de harness.

Este articulo describe ese trabajo de harness, en cinco capas que se
montan una sobre otra.

---

## Capa 1: la config nativa correcta

Antes de cualquier prompt engineering, antes de cualquier repair,
asegurate de que el engine nativo este configurado para **el caso de
uso real**, no para el "hello world" del SDK.

El runtime que carga el modelo en device tiene parametros como:

- `maxNumTokens` (tamano del context window que se reserva)
- `numOfThreads` (cuantos cores CPU usa para inferencia)
- `cacheDir` (donde escribe sus xnnpack/compiled caches)
- `backend` (CPU vs GPU vs NN API delegate)

El SDK suele venir con defaults conservadores que sirven para validar
que el modelo carga, no para correr un loop ReAct con un catalogo de
tools pasado en el prompt.

```kotlin
// Lo que viene en muchos ejemplos de SDK:
val engineConfig = EngineConfig(
    modelPath = path,
    backend = Backend.CPU(numOfThreads = 1),
    maxNumTokens = 128,
    cacheDir = ...,
)
```

Con `maxNumTokens=128`, cualquier prompt que incluya un catalogo de
tools mas instrucciones mas un poco de scratchpad va a fallar **antes
de generar el primer token**, con un error tipo:

```
Failed to create engine: INTERNAL: ERROR
[third_party/odml/litert_lm/runtime/executor/llm_litert_compiled_model_executor.cc:2045]
```

El error parece un bug profundo. No lo es. Es que el engine reserva
buffers basados en `maxNumTokens` y un contexto util tiene que ser
mucho mayor.

```kotlin
val engineConfig = EngineConfig(
    modelPath = path,
    backend = Backend.CPU(numOfThreads = 4),
    maxNumTokens = 2048,
    cacheDir = ...,
)
```

Con eso, el engine inicializa, el modelo carga, y la generacion corre
a una velocidad usable (5-15 tokens/seg en SoCs medios ARM64).

**Leccion**: revisa los defaults del SDK contra el orden de magnitud
de tu uso real antes de empezar a debuggear el modelo.

---

## Capa 2: el prompt compacto

Aun con el engine configurado bien, hay un techo practico de cuanto
input el modelo procesa con calidad. Para modelos small en device,
prompts de 1500+ tokens degradan visiblemente: respuestas truncadas,
JSON invalido al final, tokens repetidos, o errores explicitos del
runtime tipo "token too long".

Los prompts inflados vienen sobre todo de dos lugares:

### a) El catalogo de tools en JSON pretty

Esto:

```json
[
  {
    "name": "redact_pii",
    "description": "Quita DPI/CUI (13 digitos), telefono (8 digitos), email y direcciones del texto antes de razonar.",
    "input": {
      "type": "object",
      "properties": {
        "text": {
          "type": "string"
        }
      },
      "required": ["text"]
    },
    "reads_pii": false,
    "produces_artifact": false
  },
  ...nueve mas...
]
```

Son ~700-1000 tokens solo para describir herramientas. El modelo no
necesita esa estructura. Lo que necesita es un mapeo nombre →
descripcion → keys de input.

```text
- redact_pii(text): quita DPI/telefono/email/direccion del texto.
- classify_case(text): clasifica en uno de los casos del Lote 1.
- lookup_codigo_penal(category): articulo, nombre, pena.
- ...
```

Eso son ~150 tokens. El modelo entiende lo mismo. La diferencia es
que ahora cabe.

### b) El scratchpad acumulado sin limite

Despues de varias iteraciones del loop, el scratchpad
("HISTORIA DE PASOS PREVIOS") puede crecer mucho. Si lo dejas crecer
sin tope, el prompt de la iteracion 5 puede ser el doble del de la
iteracion 1.

Truncate explicito a un budget razonable, prefiriendo el final del
scratchpad sobre el principio (los pasos recientes son los relevantes
para decidir el siguiente):

```dart
String _truncate(String s, int max) {
  if (s.length <= max) return s;
  return '${s.substring(0, max)}...';
}

final scratch = _truncate(scratchpad ?? '(ninguno)', 600);
final tools = _truncate(toolsCatalog, 700);
```

### c) Reglas + hints del proximo paso

Aprovecha que estas construyendo el prompt en cada iteracion para
incluir un hint contextual:

```dart
String _nextStepHint(String? scratchpad) {
  final s = scratchpad ?? '';
  if (!s.contains('redact_pii')) {
    return 'Sugerencia: el primer paso suele ser redact_pii.';
  }
  if (!s.contains('classify_case')) {
    return 'Sugerencia: ya redactaste, ahora classify_case.';
  }
  final hasDraft = s.contains('draft_denuncia') || s.contains('draft_solicitud');
  if (!hasDraft) {
    return 'Sugerencia: ya clasificaste, ahora draft_denuncia o draft_solicitud.';
  }
  if (!s.contains('sign_packet')) {
    return 'Sugerencia: ya tenes el documento, llama sign_packet.';
  }
  return 'Sugerencia: documento producido y firmado, podes cerrar con final.';
}
```

No le impones una secuencia rigida — el modelo puede ignorar el hint —
pero le bajas la entropia de "que hago ahora" sin spelling out la
respuesta.

**Leccion**: el prompt es budget. Cada token que metes es uno menos
para que el modelo razone y genere.

---

## Capa 3: validate-then-repair (el corazon)

Este es el cambio mas grande. Cuando el modelo genera tool calls, no
respeta el schema estricto el 100% de las veces. Las fallas no son
random; son un set finito y compositivo que se repite entre modelos.

Cuatro fallos que reaparecen casi identicos entre distintos modelos
open-source pequenos:

1. **Bare string** donde el schema espera `{key: string}` (manda
   `"foo"` en vez de `{"text": "foo"}`)
2. **Stringified JSON** (manda `'{"text":"foo"}'` como string en vez
   del objeto)
3. **Stringified array** (manda `'["a","b"]'` como string en vez del
   array)
4. **Singleton array** donde se esperaba objeto (manda `["foo"]` en
   vez de `{key: "foo"}`)

Mas un quinto comun: `null` en field opcional en vez de omitirlo.

### El patron clave: validate primero, reparar despues

La tentacion es preprocesar el input antes de validar: "si es string,
parsealo como JSON; si es null, sustituilo por {}; si es array
unwrappealo". El problema: **inputs validos se corrompen**. Un
`writeFile({content: "{...}"})` cuyo contenido casualmente es JSON
queda reescrito antes de tocar el disco. Falla silenciosa, dificil
de detectar.

Solucion: invertir el orden.

```dart
Future<RepairOutcome> repair({required AgentTool tool, required Object? raw}) {
  // Caso 0: ya es Map valido -> passthrough.
  if (raw is Map<String, dynamic>) {
    final fixed = _repairChildren(tool, Map.from(raw));
    if (_mapsEqual(fixed, raw)) {
      return RepairOutcome.passthrough(fixed);
    }
    return RepairOutcome.repaired(fixed, notes: ['stripped_nulls']);
  }

  // Caso 1: bare string donde se esperaba object con un solo campo string.
  if (raw is String) {
    final primary = _primaryStringKeyFor(tool);
    if (primary != null) {
      // Antes de wrap, intentar parse por si es JSON stringified.
      final parsed = _tryParseJson(raw);
      if (parsed is Map<String, dynamic>) {
        return RepairOutcome.repaired(
          _repairChildren(tool, parsed),
          notes: ['parsed_stringified_json_object'],
        );
      }
      return RepairOutcome.repaired(
        {primary: raw},
        notes: ['wrapped_bare_string_as_$primary'],
      );
    }
  }

  // Caso 2: lista de un elemento -> unwrap.
  if (raw is List && raw.length == 1) {
    final primary = _primaryStringKeyFor(tool);
    if (primary != null) {
      return RepairOutcome.repaired(
        {primary: raw.first},
        notes: ['unwrapped_singleton_array_to_$primary'],
      );
    }
  }

  // Caso 3: null cuando la tool acepta input vacio.
  if (raw == null) {
    return RepairOutcome.repaired(
      const {},
      notes: ['null_input_replaced_with_empty_object'],
    );
  }

  return RepairOutcome.unrepairable(reason: 'unsupported_input_type:${raw.runtimeType}');
}
```

### Por que esto importa

- **El schema es el prior**, no tu preprocesador. Solo gastas
  presupuesto de reparacion en los paths donde el schema realmente
  se quejo.
- **Inputs validos nunca se tocan**. El passthrough es la primera rama.
- **Cada repair es identificable**. La nota `'wrapped_bare_string_as_text'`
  te dice exactamente que paso.
- **El orden de aplicacion importa**: parse-stringified-json antes de
  wrap-bare-string, porque si no `'{"text":"foo"}'` queda como
  `{primary: '{"text":"foo"}'}` en vez de `{text: "foo"}`.

### Ampliacion del dominio aceptado por las tools

Independiente del repair de shape: las tools toleran sinonimos
razonables en sus enums. Si tu tool declara
`category in [extorsion, estafa, amenazas]` pero el modelo a veces
pasa el `case_code` completo (`extorsion_telefono_sms`), una tabla de
aliases en el tool resuelve a la categoria canonica antes del lookup:

```dart
static const _aliases = <String, String>{
  'extorsion_telefono_sms': 'extorsion',
  'estafa_remesa': 'estafa',
  'estafa_empleo': 'estafa',
};

@override
Future<ToolResult> call(Map<String, dynamic> input) async {
  final raw = (input['category'] ?? '').toString();
  final cat = _aliases[raw] ?? raw;  // <-- aqui
  final entry = _table[cat];
  ...
}
```

Esto no es repair de input shape; es **contrato mas forgiving en el
lado de la tool**. Va de la mano con el repair pero opera distinto:
el repair ajusta el shape, el alias ajusta los valores aceptados.

**Leccion**: invertir preprocess-then-validate a validate-then-repair
te convierte el harness fragil en uno forgiving sin cambiar el modelo
ni los tools.

---

## Capa 4: loop-level fallback (extender semantics donde no podes
reparar)

Algunas fallas no se reparan a nivel input:

- El modelo decide cerrar con `final` antes de haber producido el
  documento (no llamo a `draft_denuncia` ni `draft_solicitud`).
- El modelo se cuelga, tira excepcion, o produce JSON irreparable
  dos veces seguidas.
- El runtime nativo falla mid-generacion por algun problema de engine.

Para estos, el patron equivalente al "extender semantics" pero a nivel
del loop entero: en vez de cortar con `ErrorStep` terminal, switchear
a un razonador determinista local que **preserva el scratchpad
acumulado** y termina solo lo que falta.

```dart
class AgentLoopConfig {
  const AgentLoopConfig({
    this.maxIterations = 10,
    this.stepDelay = const Duration(milliseconds: 180),
    this.fallbackReasoner,  // <-- el nuevo campo
  });
  final AgentReasoner? fallbackReasoner;
  ...
}

Stream<AgentStep> runAgentLoop({...}) async* {
  ...
  var activeReasoner = reasoner;
  var didFallback = false;

  for (var iteration = 0; iteration < config.maxIterations; iteration++) {
    final ReasonerDecision decision;
    try {
      decision = await activeReasoner.decideNextStep(...);
    } catch (e) {
      if (!didFallback && config.fallbackReasoner != null) {
        didFallback = true;
        activeReasoner = config.fallbackReasoner!;
        yield ObservationStep(
          content: 'El razonador principal fallo, sigo con el plan local.',
          data: {'switched_to': activeReasoner.label},
        );
        iteration--;  // reintenta la misma iteracion con el fallback
        continue;
      }
      yield ErrorStep('El razonador fallo: $e');
      return;
    }

    if (decision.action == 'final') {
      final artifact = decision.artifactSpec?.toArtifact() ?? lastArtifact;
      if (artifact == null) {
        // El modelo quiso cerrar pero no produjo documento.
        if (!didFallback && config.fallbackReasoner != null) {
          didFallback = true;
          activeReasoner = config.fallbackReasoner!;
          yield ObservationStep(
            content: 'Cierre prematuro detectado. Sigo con plan local para producir el documento.',
            data: {'switched_to': activeReasoner.label},
          );
          continue;
        }
        yield ErrorStep('Cierre final sin artifact.');
        return;
      }
      yield FinalStep(...);
      return;
    }
    ...
  }
}
```

### Por que esto es poderoso

- El usuario **nunca ve un error final** si el caso es soportado por
  el plan local.
- El modelo **mantiene autoridad** mientras esta haciendo bien las
  cosas. Solo se le quita el control cuando se equivoca de forma que
  no se puede reparar a nivel input.
- El plan local **no empieza de cero**. Lee el scratchpad, ve los
  pasos hechos (`redact_pii`, `classify_case`, `lookup_codigo_penal`),
  y solo ejecuta lo que falta (`draft_denuncia`, `sign_packet`). Es
  eficiente y consistente con lo que el modelo ya decidio.
- El switch se **anuncia explicitamente** en el stream con un
  `ObservationStep` ("Cierre prematuro detectado. Sigo con plan
  local."). No es magia silenciosa; el usuario y el desarrollador ven
  que paso.

### El patron en abstracto

```
modelo_principal.decide(input) ?
  → si OK: usar
  → si falla recuperable: ?
    → si hay fallback: switch + preserve state + continue
    → sino: fail con error explicito
```

El plan local no es "peor IA"; es **garantia de cierre**. El modelo
es para razonar sobre situaciones nuevas; el plan local es para
ejecutar el playbook conocido cuando el razonamiento no aterrizo.

**Leccion**: dale al modelo permiso para equivocarse. Tener un
fallback determinista que termina el trabajo te permite poner al
modelo a tomar decisiones reales sin miedo de que el usuario quede
con un error en pantalla.

---

## Capa 5: clasificadores permisivos

Si la primera tool del loop es un `classify_case` (o equivalente que
discrimina la rama del flujo), patterns demasiado estrictos hacen que
el modelo se quede llamando esa tool una y otra vez tratando de
obtener un match.

Caso real:

```dart
// Patrones rigidos:
'extorsion': [
  RegExp(r'\bextorsion\b'),
  RegExp(r'\bvan a matar\b'),
  RegExp(r'\bsi no pago\b'),
  RegExp(r'\bmaras\b'),
],
```

Input del usuario: *"me dijeron que si no daba dinero me mataban"*.

Cero matches. El clasificador devuelve `case_code: unknown`. El modelo
ve el resultado, "no es lo que esperaba", reintenta `classify_case` con
el mismo texto. Loop infinito.

Solucion: extender los patterns para absorber variantes coloquiales:

```dart
'extorsion_telefono_sms': [
  RegExp(r'\bextor[sc]ion', caseSensitive: false),
  RegExp(r'\bamenaz', caseSensitive: false),
  RegExp(r'\bmatar(?:me|nos|los)?\b', caseSensitive: false),
  RegExp(r'\bmataba[ns]?\b', caseSensitive: false),
  RegExp(r'\bsi no (?:pago|daba|doy|pagaba|entrego|paso)', caseSensitive: false),
  RegExp(r'\bme van a hacer (?:dano|algo)', caseSensitive: false),
  RegExp(r'\bpidi(?:e|o)ndo (?:plata|dinero|pisto)', caseSensitive: false),
  RegExp(r'\bmaras?\b', caseSensitive: false),
  RegExp(r'\bsecuestr', caseSensitive: false),
],
```

El clasificador ahora absorbe presente/pasado/imperfecto, sinonimos
locales, formas reflexivas. El modelo recibe un match, sigue al
siguiente paso, no se queda dando vueltas.

**Leccion**: no es trabajo del modelo arreglar tu clasificador
fragil. Si tu first-step tool tiene patterns demasiado estrictos, vas
a quemar tokens del modelo en reintentos en vez de en pasos
productivos.

---

## Telemetria per-tool

Todas las capas de arriba dependen de poder **observar** que esta
pasando. Sin telemetria por tool, no sabes:

- Que repair se aplico mas seguido (y por tanto cual repair tendria
  que estar realmente en el contrato de origen)
- Cuando el modelo regresiona en una tool especifica al subir version
- Cuando el plan local entra mas seguido (signal de que el modelo
  esta cerrando prematuro mas que antes)

```dart
class LiteRtGemmaAgentReasoner implements AgentReasoner {
  LiteRtGemmaAgentReasoner({
    ...
    this.onRepair,
  });

  final void Function(String toolName, RepairOutcome outcome)? onRepair;

  ReasonerDecision? _tryParse(String text) {
    ...
    if (action == 'tool_call') {
      ...
      final outcome = _repair.repair(tool: registry.get(tool), raw: rawInput);
      if (!outcome.ok) return null;
      onRepair?.call(tool, outcome);  // <-- telemetria
      return ReasonerDecision.toolCall(tool: tool, input: outcome.input!);
    }
    ...
  }
}
```

Loggear:
- `tool_input_repaired:${toolName}` cuando outcome.kind == repaired
- `tool_input_passthrough:${toolName}` cuando passthrough (la mayoria)
- `tool_input_invalid:${toolName}` cuando unrepairable
- `loop_fallback_triggered` cuando el switch al determinista pasa

Con eso podes **ver el harness funcionando** y detectar regresiones
antes que los usuarios.

### Surface al modelo

Ademas de loggear, las notas del repair se pueden meter como
`ObservationStep` extra antes de la siguiente iteracion del loop, asi
el modelo en su proximo turn ve:

> Nota: tu input para `redact_pii` fue reparado (bare-string-wrap →
> objeto). En la proxima vez manda objeto JSON con keys.

El modelo puede aprender de eso en una conversacion de 6 turnos sin
necesidad de fine-tuning.

**Leccion**: la observabilidad no es decoracion; es lo que te permite
que el harness mejore con el uso.

---

## Resumen: que cambia y que no

### El modelo no cambia

- No se entreno
- No se hizo fine-tuning
- No se tocaron pesos
- Se uso stock del repositorio de origen

### El harness alrededor cambia en cinco capas

1. **Engine config** que arranca con buenos buffers (maxNumTokens >
   prompt + scratchpad esperado, threads > 1)
2. **Prompt compacto** que cabe en el contexto util del modelo
   (catalogo one-line, scratchpad truncado, hints contextuales)
3. **Capa de tool input repair** con cinco reparaciones automaticas
   ordenadas (passthrough, bare-string-wrap, stringified-json-parse,
   singleton-array-unwrap, null-strip)
4. **Loop-level fallback** que switchea a determinista preservando
   scratchpad cuando el modelo cierra prematuro o falla
5. **Clasificadores permisivos** que absorben variantes coloquiales
   en vez de obligar al modelo a forzar matches

Plus **telemetria per-tool** para ver el harness funcionando.

### El resultado

Un modelo small open-source, corriendo en CPU de un device de gama
media-alta, manejando un loop ReAct multi-turn con tool calling
real, con pasos visibles en pantalla y documento firmado al final.
Sin training, sin fine-tuning, sin GPU.

La leccion de fondo: **lo que parece "modelo malo en tool calling"
casi siempre es harness fragil**. El modelo no sabe tu contrato
exacto; vos podes hacer el contrato mas forgiving en exactamente los
puntos donde el modelo necesita ayuda. Cinco repairs cortos, un
fallback, una config nativa correcta y un prompt compacto convierten
un modelo que fallaba en uno que cierra el loop end-to-end.

El skill issue aplica al harness mas seguido que al modelo.
