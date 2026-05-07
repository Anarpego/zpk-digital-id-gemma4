# apptowin.md — Plan tecnico para ganar el Gemma 4 Good Hackathon

Documento de implementacion. Cubre lado ciudadano y lado institucion (Modo Ventanilla). No es marketing. Asume el contexto de `sabado2context.md`.

Repo base: `/Users/anibalperez/Code/AI/kaggle/`. App: `kan-app/`.

---

## 0. Promesa de la app en una linea

> Te paso algo. Lo contas, lo mostras o lo escribis. El agente Gemma 4 te dice que hacer y te firma los papeles. La institucion los recibe verificables y minimos. Nada sale del telefono salvo lo que vos decidis compartir.

Dos lados, una sola APK:
- **Modo Ciudadano** (default): pantalla unica, voz / camara / texto, agente, artefacto firmado, QR para compartir.
- **Modo Ventanilla** (toggle en onboarding): escanea QR del ciudadano, verifica firma localmente, lee paquete redactado, firma acuse, lo devuelve por QR.

---

## 0.1 Por que importa esta app (la historia que el jurado tiene que sentir)

### El problema real, no el problema bonito

Guatemala tiene 17 millones de personas. La mayoria interactua con el Estado en condiciones de desventaja brutal:

- **Brechas de PII recurrentes**: RENAP y SAT han sufrido filtraciones documentadas. Cuando una institucion guatemalteca pide tu CUI por WhatsApp o lo teclea un funcionario sin auditoria, el dato vive para siempre fuera de tu control.
- **Tramites en papel y en cola**: para reponer un DPI perdido, atender una urgencia IGSS sin carne, denunciar una extorsion, registrar una queja MTPS, tenes que ir fisicamente, esperar horas, llevar copias de copias, y si el funcionario "pierde" tus papeles no hay rastro.
- **Estafas masivas por SMS/WhatsApp**: extorsion telefonica, falsa Western Union, "tu paquete esta retenido", premios falsos. La poblacion mas vulnerable (adultos mayores, migrantes retornados, gente con baja alfabetizacion digital) cae con frecuencia. Hoy no hay primera linea de defensa.
- **Asimetria institucional**: si el MP "no recibe" tu denuncia, no podes probar que la entregaste. Si IGSS te niega atencion sin DPI, no hay un segundo intento facil. La institucion tiene memoria selectiva y vos no tenes prueba.
- **Brecha tecnologica**: una abuela en Quetzaltenango con un Motorola G15 no va a aprender Flutter ni a navegar 5 pestanas. La existencia tecnica de la solucion no equivale a su uso real.

### Por que la combinacion Gemma 4 + ZPK es nueva

Hay apps de tramites. Hay apps de denuncia. Hay wallets de identidad. Lo que **no existe** en Guatemala es una herramienta donde:

1. **El razonamiento legal y burocratico vive en el telefono** (Gemma 4 offline) y entiende como redactar una denuncia citando el Codigo Penal correcto, sin enviar el caso a un servidor.
2. **Lo que sale del telefono es matematicamente verificable y minimo** (firma + hash + paquete redactado), de modo que la institucion puede atender sin coleccionar mas PII y sin poder negar despues que recibio.
3. **Funciona sin internet**, lo que importa porque las zonas rurales y los momentos de crisis (extorsion, robo, deportacion reciente) suelen coincidir con conectividad mala o riesgo de exponer datos por canales inseguros.
4. **La interaccion es por voz y foto**, lo que importa porque la persona promedio que mas necesita esto **no escribe rapido en un telefono y a veces no lee bien**.

Cualquier solucion que falle en una de esas cuatro condiciones excluye al usuario que mas la necesita.

### Por que importa para el jurado

El hackathon premia "Gemma 4 Good". Eso significa, en la lectura honesta:
- **On-device real**: no es chat con API en la nube disfrazado.
- **Agentic real**: el modelo decide pasos, no solo completa texto.
- **Impacto real**: una persona concreta resuelve un problema concreto, no una demo abstracta.
- **Honestidad**: lo que no funciona se dice; lo que funciona se prueba.

Esta app marca los cuatro. La parte ZPK ademas le da algo que ningun otro proyecto del hackathon va a tener: una historia de **protocolo entre ciudadano e institucion**, con dos lados visibles en la misma demo. El jurado puede sacar su telefono, escanear el QR del ciudadano desde el modo ventanilla, ver la firma verificarse en vivo, y entender en 10 segundos por que esto vale.

### Por que importa para el usuario final

Un usuario no abre esta app porque le interesen los SNARKs ni la IA on-device. La abre porque:
- "Me llego un mensaje raro y no se si es estafa."
- "Mi mama necesita IGSS y no tiene su DPI a la mano."
- "Despidieron a mi hijo sin pagarle nada."
- "Mi tio llego deportado ayer."
- "El colegio me mando una circular que no entiendo."

Si la app, en menos de 60 segundos sin tener que aprender nada, le devuelve **un papel listo para usar y le explica que hacer en voz alta**, gana. Todo lo demas (la cripto, el agente, el ledger) es invisible y deberia serlo.

---

## 0.2 Como pienso la UI/UX para que sea una app real, no un demo

### Tres principios que mandan sobre todo lo demas

**1. Una pantalla, una decision a la vez.**
Cada pantalla tiene un solo trabajo. Si el usuario tiene que elegir mas de una cosa al mismo tiempo, la pantalla esta mal. La home es: *"contame que paso"*. Eso es todo. Las pestanas (Persona / Acciones / Institucion / Evidencia / Motor) que tiene la app actual son utiles para auditar pero matan a la abuela. Por eso quedan en un drawer "Modo avanzado" para el power-user (y el verificador UIAutomator), pero no son la cara de la app.

**2. Verbos antes que sustantivos.**
El menu no dice "Identidad / Tramites / Casos / Documentos". Dice **Hablar / Mostrar / Escribir**. La accion lleva al usuario, no la categoria. Esto es directamente robado del modelo mental de WhatsApp (mensaje / foto / nota de voz), que es el unico patron de UI que la mayoria de guatemaltecos ya domina.

**3. Hacer visible el trabajo del agente.**
La trampa de las apps con IA es que parece que "presionas un boton y aparece magia". Eso es malo en dos sentidos: el usuario no confia (porque parece caja negra), y el jurado no puede juzgar (porque no ve agentic behavior). Solucion: **el panel de razonamiento del agente se anima paso a paso**, con cada llamada a herramienta y cada observacion. Es como ver a un abogado pensando en voz alta. Le da confianza al usuario y demuestra capacidad al jurado al mismo tiempo.

### El usuario mental que dirige el diseno

No diseno para "el usuario promedio". Diseno para **una abuela de 67 anos en Quetzaltenango con un Motorola G15, mano temblorosa, vista cansada, espanol como segunda lengua despues de K'iche', que le tiene desconfianza a las apps porque su sobrino ya le robo plata por WhatsApp**. Si esta app le funciona a ella, le funciona a todos. Si esta app le falla a ella, no le sirve a nadie que importa.

Reglas que salen de tomar a esa persona en serio:
- Texto base 18sp, no 14. (Modo Abuela 1.5x = 27sp.)
- Contraste WCAG AAA en todo, no AA.
- Tap targets minimos 56dp, idealmente 64. El boton del mic es 96dp.
- Cero dropdowns. Cero modales anidados. Cero checkboxes pequenitos.
- Cada paso confirma antes de continuar si tiene consecuencias visibles ("Listo, te leo los papeles?").
- Cero jerga en la UI ("CUI" se reemplaza por "tu numero de DPI", "intake" se reemplaza por "lo que vas a llevar a la ventanilla").
- El loading nunca es spinner abstracto: siempre es texto narrado ("Estoy revisando si es estafa conocida...").

### El layout y por que cada elemento esta donde esta

```
+--------------------------------------------------+
| [Avion ON] [es-GT]              [≡]              |  <- top bar minima, no roba foco
+--------------------------------------------------+
|                                                  |
|  Que te paso?                                    |  <- pregunta directa, segunda persona
|                                                  |
|  [ panel agente, vacio al inicio ]              |
|                                                  |
|  [ artifact_card, oculta hasta que hay algo ]   |
|                                                  |
|  [ privacy_diff_card, plegable ]                |
|                                                  |
+--------------------------------------------------+
|     [📷]         [🎤 GRANDE]          [Aa]      |  <- bottom dock, pulgar derecho
+--------------------------------------------------+
```

- **Top bar minima**: solo lo critico para confianza (modo avion encendido = "esto no esta hablando con internet"). Nada de logos, nada de tabs.
- **Pregunta directa "Que te paso?"**: invita a hablar, no a clasificar. Si la pregunta fuera "Selecciona el tipo de tramite", el usuario se pierde antes de empezar.
- **Mic en el centro**: pulgar derecho, ergonomicamente optimo, mismo lugar que el shutter de camara nativo Android. El mic es 96dp, los otros dos botones 64dp. Esto no es accidental: el mic es la accion preferida.
- **Camara izquierda**: para foto de SMS, recibo, documento. Es el segundo verbo en frecuencia.
- **Teclado a la derecha**: ultimo recurso, mas pequeno. La gente que sabe escribir rapido en un telefono no es el usuario objetivo.

### Por que voz primero, no chat abierto

Un chat por turnos parece la opcion obvia para una IA. Pero:
- Escribir en un teclado de telefono es lento y frustrante.
- La gente que mas necesita esto **no escribe bien**.
- El chat sugiere conversacion abierta. Eso aumenta la chance de que el usuario diga PII por accidente ("aqui esta mi CUI: 1234...").
- Una sola entrada hablada + agente que actua + artefacto al final cierra el ciclo en menos pasos.

Voz primero tambien hace el demo del jurado mas legible: el jurado escucha lo que el usuario dijo, ve al agente actuar, y obtiene el documento. No hay scroll de chat que leer.

### Por que TTS importa tanto

Mucho del valor es **la app leyendote tus propios papeles**. La razon profunda: una persona con baja alfabetizacion no confia en lo que no puede leer. Si la app solo *muestra* la denuncia, la persona la firma sin entenderla, lo cual es exactamente el problema que tienen hoy con los formularios de papel. Si la app **se la lee en voz alta en su acento**, gana confianza y comprension al mismo tiempo. TTS no es un nice-to-have; es parte del valor.

### Privacidad como elemento de UI

La mayoria de apps tratan la privacidad como una pantalla legal de Settings que nadie lee. Aqui es **una tarjeta visible en cada interaccion**:

> **Lo que NO sale de tu telefono:**
> - Tu numero de DPI: 2547... (oculto)
> - Tu telefono: 5012... (oculto)
> - Tu direccion completa (oculta)

Esa tarjeta convierte la privacidad de promesa abstracta a evidencia concreta cada vez que el agente actua. Para el jurado: *"esta app demuestra su privacidad en cada uso, no solo la afirma."* Para el usuario: *"esta cosa de verdad esta cuidando mis datos."*

### El loop del agente como teatro educativo

Cuando el agente esta trabajando, el panel central muestra:

```
🔒 Bloque tu numero de DPI antes de pensar
🔍 Estoy revisando si es estafa conocida
✅ Si: extorsion telefonica, alta probabilidad
📚 Buscando articulo del Codigo Penal aplicable
✅ Articulo 261 CP, pena 6 a 12 anos
✍️  Te estoy escribiendo la denuncia
📄 Borrador listo
✍️  Firmando con tu llave local
✅ Listo
```

Cada linea aparece con 180ms de delay (en modo deterministico, donde no hay latencia natural). El efecto es **el agente pensando en vivo**. Eso transforma "presione un boton y salio un papel" en "vi a un agente trabajar para mi". Para el jurado, ese delay es la diferencia entre un script y una demostracion de capacidad agentic.

### El artefacto como recompensa concreta

El cierre de cada interaccion es **un documento real, con titulo, formato formal, firma**. No es una lista de bullets. Es algo que la persona puede:
- **Escuchar** (TTS).
- **Copiar** (al portapapeles).
- **Compartir** (WhatsApp, email).
- **Imprimir** (PDF).
- **Mostrar como QR** (al funcionario).

Esa redondez es lo que hace que la app se sienta como **producto** y no como prototipo. Si al final del flujo el usuario no se queda con algo concreto y compartible, la app pierde valor mas alla del demo.

### Por que el Modo Ventanilla es UX, no solo backend

Podria existir un protocolo ZPK perfecto sin Modo Ventanilla — los funcionarios verificarian con un script en su PC. Pero entonces:
- El demo del jurado se vuelve abstracto ("imaginate que existe un sistema institucional...").
- El protocolo no se prueba puerta a puerta.
- La asimetria persiste: el ciudadano tiene una app, el funcionario tiene Word.

**Modo Ventanilla en la misma APK** convierte la app de "wallet del ciudadano" en "protocolo de dos lados". Para el jurado, esto es la diferencia entre "interesante" y "memorable". El jurado puede agarrar su propio telefono, hacerse pasar por funcionario IGSS, escanear el QR del demostrador, y ver la firma verificarse en su pantalla. Esa interactividad es la jugada de UX mas alta de toda la demo.

UI del Modo Ventanilla intencionalmente diferente:
- **Color de fondo cambia** (azul institucional vs blanco ciudadano) para que el funcionario nunca dude en que rol esta.
- **Header con nombre de la mesa** ("IGSS - Quetzaltenango") siempre visible.
- **Boton de escanear es lo unico grande**, igual que el mic en ciudadano. Una accion principal por pantalla.
- **Field diff visualmente claro**: campos recibidos en negro, campos redactados en gris tachado con candado. Esto es la "victoria" del protocolo y debe verse al instante.

### Modo Abuela como filosofia, no como flag

El toggle "Modo Abuela" no es un easter egg. Es la forma de hacer explicito **el modo en el que la app deberia operar siempre**. Lo que hace: texto mas grande, narracion automatica de cada step, confirmacion antes de cada decision, ocultar los verbos no preferidos. Si el toggle convirtiera la app en algo radicalmente distinto, la app base estaria mal disenada. Aqui solo amplifica.

### Errores y casos borde, tratados con dignidad

- **Sin permiso de mic/camara**: pantalla con explicacion clara, no popup tecnico. "Para escucharte necesito tu permiso del microfono. Solo tu telefono te escucha, nunca sale el audio."
- **STT no on-device**: bloqueo explicito. "Tu telefono enviaria el audio a Google. Lo cancele. Probemos por foto o teclado."
- **Gemma falla**: el panel dice "Mi cerebro grande se canso, sigo con el cerebro chico." Sigue funcionando.
- **Sin internet pero la app necesita descargar el modelo**: pantalla clara con el tamano (2.5 GB), advertencia de wifi, y opcion de transferir el modelo desde otro dispositivo via USB.
- **CUI invalido**: nunca dice "ERROR". Dice "Ese numero no parece DPI guatemalteco, podes seguir igual sin DPI."

### Lo que NO esta en la UI a proposito

- **Sin login con email/password.** La identidad es el keypair local. Cero cuentas, cero servidor.
- **Sin tracking, sin analytics.** Cero llamadas a red en uso normal.
- **Sin modal de "actualizar a Pro".** No hay Pro.
- **Sin notificaciones push.** Cero canal externo.
- **Sin compartir social directo.** Compartir es siempre via share-sheet del SO, decision del usuario.

Cada una de esas ausencias es deliberada y refuerza el mensaje "esto no es Big Tech".

### Como la UI se traduce en el demo del jurado

Una buena UX de la app produce automaticamente un buen demo. No hay que "preparar el demo", la app **es** el demo:

1. Abrir app -> abuela podria usarla -> jurado entiende.
2. Hablar -> agente actua visible -> jurado ve agentic.
3. Documento aparece -> jurado ve resultado concreto.
4. QR -> jurado escanea desde su telefono en Modo Ventanilla -> jurado **interactua**.
5. Privacy card visible todo el tiempo -> jurado ve la promesa cumplirse.

Si el demo necesita un guion separado de la app real, la UX esta mal. Esta diseno garantiza que el demo es solo "usar la app dos veces seguidas, una por lado."

---

## 1. Mapeo a tracks del hackathon

| Bloque | On-Device | Agentic | Impacto | Multimodal | Fine-tuned |
|---|---|---|---|---|---|
| A. UX una pantalla | x | | x | x | |
| B. Casos de uso | | x | x | | x (dataset) |
| C. ReAct loop | x | x | | | x |
| D. Multimodal (STT/TTS/OCR) | x | x | x | x | |
| E. Modo Ventanilla | x | | x | x | |
| F. Protocolo ZPK ciudadano-institucion | x | | x | | |
| G. Dataset SFT + eval harness | | | | | x |

Cada bloque suma a por lo menos dos tracks. Eso es la apuesta.

---

## 2. Arquitectura objetivo

```
kan-app/
  lib/
    main.dart                          (entrypoint, role switch)
    config/
      app_config.dart                  (existente, agrega ROLE)
      role.dart                        (NUEVO: Citizen | Institution)
    features/
      citizen/
        citizen_home.dart              (NUEVO: una pantalla)
        widgets/
          big_mic_button.dart          (NUEVO)
          camera_capture_button.dart   (NUEVO)
          agent_stream_panel.dart      (NUEVO: timeline ReAct)
          artifact_card.dart           (NUEVO: documento generado)
          privacy_diff_card.dart       (NUEVO: lo que NO sale)
          share_packet_sheet.dart      (NUEVO: QR + share)
      institution/
        ventanilla_home.dart           (NUEVO)
        widgets/
          qr_scanner_view.dart         (NUEVO)
          received_packet_card.dart    (NUEVO)
          field_diff_view.dart         (NUEVO)
          sign_acuse_button.dart       (NUEVO)
          institution_ledger_view.dart (NUEVO)
      identity_wallet/
        home_screen.dart               (existente, queda como Modo Avanzado en drawer)
    services/
      agent/
        agent_step.dart                (NUEVO: tipo de evento del loop)
        agent_loop.dart                (NUEVO: orquesta ReAct)
        agent_tool.dart                (NUEVO: contrato de herramienta)
        tool_registry.dart             (NUEVO: registra todas las tools)
        tools/
          ocr_image_tool.dart          (NUEVO)
          transcribe_audio_tool.dart   (NUEVO, wrapper)
          classify_case_tool.dart      (NUEVO)
          lookup_codigo_penal_tool.dart(NUEVO)
          lookup_codigo_trabajo_tool.dart (NUEVO)
          lookup_institucion_tool.dart (NUEVO)
          draft_denuncia_tool.dart     (NUEVO)
          draft_solicitud_tool.dart    (NUEVO)
          draft_sms_familia_tool.dart  (NUEVO)
          draft_checklist_tool.dart    (NUEVO)
          redact_pii_tool.dart         (NUEVO, envuelve privacy_guard)
          sign_packet_tool.dart        (NUEVO, envuelve identity_signer)
          build_timeline_tool.dart     (NUEVO)
      reasoners/
        kan_reasoner.dart              (existente, refactor: emite Stream<AgentStep>)
        litert_gemma_reasoner.dart     (existente, agrega ReAct multi-turn)
        local_deterministic_reasoner.dart (existente, refactor: planificador con steps)
        reasoner_factory.dart          (existente)
      multimodal/
        stt_service.dart               (NUEVO: speech_to_text wrapper)
        tts_service.dart               (NUEVO: flutter_tts wrapper)
        ocr_service.dart               (NUEVO: ml_kit wrapper)
        camera_service.dart            (NUEVO)
      zpk/
        packet_envelope.dart           (NUEVO: shape + canonical encoding)
        packet_codec.dart              (NUEVO: JSON -> gzip -> base64url)
        packet_qr.dart                 (NUEVO: encode/decode QR payloads, chunking)
        institution_trust_list.dart    (NUEVO: pubkeys de demo IGSS/SAT/MP/Colegio)
        signature_verifier.dart        (NUEVO)
        revocation_record.dart         (NUEVO)
        acuse_record.dart              (NUEVO)
      identity_signer.dart             (existente)
      digital_identity_fabric.dart     (existente)
      recovery_packet_service.dart     (existente)
      agent_execution_ledger.dart      (existente, agrega entradas de ventanilla)
      privacy_guard.dart               (existente)
      ...                              (resto existente sin tocar)
    models/
      kan_case.dart                    (existente, agrega nuevos casos)
      generated_artifact.dart          (NUEVO: tipo + contenido + hash)
      institutional_packet.dart        (NUEVO: campos + redactados)
  android/
    app/src/main/kotlin/.../MainActivity.kt  (existente, sin cambio en este sprint)
  test/
    services/agent_loop_test.dart      (NUEVO)
    services/zpk_packet_codec_test.dart(NUEVO)
    services/signature_verifier_test.dart (NUEVO)
    widget/citizen_home_test.dart      (NUEVO)
    widget/ventanilla_home_test.dart   (NUEVO)
```

---

## 3. Bloque A — UX una pantalla, tres verbos (Modo Ciudadano)

### 3.1 Layout

```
+--------------------------------------------------+
| [Modo avion ON] [es-GT] [Modo Ventanilla...]    |  <- top bar minima
+--------------------------------------------------+
|                                                  |
|  Que te paso?                                    |
|                                                  |
|  [ panel agente razonando, vacio al inicio ]    |
|                                                  |
|  [ tarjeta documento generado, oculta inicio ]  |
|                                                  |
|  [ tarjeta privacidad: que NO sale, oculta ]    |
|                                                  |
+--------------------------------------------------+
|        [Camara]    [  MIC GRANDE  ]    [Aa]      |  <- bottom bar 3 verbos
+--------------------------------------------------+
```

- **MIC GRANDE**: hold-to-talk. Suelta y se transcribe. Long-press 2s = Modo Silencio.
- **Camara**: foto, OCR local, texto entra al agente.
- **Aa**: teclado fallback.

### 3.2 Estados visibles del agente (en `agent_stream_panel.dart`)

Cada `AgentStep` se renderiza apilado, con animacion de fade-in:
- `plan` -> texto en italica gris.
- `tool_call` -> chip con icono + nombre + input compactado.
- `observation` -> texto en mono pequeno.
- `final` -> dispara render del artifact_card y privacy_diff_card.

En modo determinista se introduce delay de 180ms entre steps para que el ojo los siga. En modo Gemma no hay delay porque la generacion ya tarda.

### 3.3 Modo Silencio (long-press mic)

- Pantalla queda igual (no muestra que esta grabando).
- Audio se guarda cifrado en disco local.
- Se construye `incident_record` firmado con timestamp + hash.
- El usuario los ve solo en el drawer "Mis incidentes" cuando quiere.
- Caso de uso: violencia domestica, evidencia para PDH/PNC cuando la victima decida.

### 3.4 Lectura en voz alta

Cada artifact tiene boton "Escuchar". Usa `tts_service` con voz `es-GT` o `es-MX` como fallback. Velocidad reducida en Modo Abuela.

### 3.5 Modo Abuela (toggle drawer)

- Texto 1.5x.
- Solo el verbo MIC visible, los otros se ocultan.
- Cada step del agente se narra automatico ("Estoy revisando que sea estafa...", "Te voy a escribir la denuncia ahora...").
- Confirmacion antes de cualquier accion ("Listo, queres que te lea los papeles?").

### 3.6 Navegacion vieja

`features/identity_wallet/home_screen.dart` (las 5 pestanas) se mantiene accesible desde drawer "Modo avanzado". Esto preserva los tests existentes y el script `verify_motorola_physical_flow.sh` que busca textos en esa UI.

---

## 4. Bloque B — Casos de uso con artefacto real

Cada caso = `KanCase` extendido + tool chain definido + plantilla de artefacto. Lista priorizada para esta sesion (5 fuertes) y el resto en backlog.

### Lote 1 (esta sesion)

| Caso | Input tipico | Tools llamadas | Artefacto final |
|---|---|---|---|
| **Extorsion telefono/SMS** | foto SMS o voz | ocr_image, classify_case, lookup_codigo_penal, draft_denuncia, draft_sms_familia, redact_pii, sign_packet | Denuncia MP (PDF-able) + SMS familia |
| **Estafa de remesa** | foto comprobante o voz | ocr_image, classify_case, lookup_institucion(PROFECO/DIACO), draft_denuncia, sign_packet | Queja DIACO + checklist |
| **IGSS sin DPI** | voz | classify_case, lookup_institucion, draft_solicitud, redact_pii, sign_packet | Solicitud presencial sin CUI + intake institucional |
| **SAT acceso bloqueado** | voz | classify_case, lookup_institucion, draft_solicitud, sign_packet | Solicitud restablecimiento |
| **Despido sin prestaciones** | voz | classify_case, lookup_codigo_trabajo, draft_denuncia, build_timeline, sign_packet | Queja MTPS + calculo aproximado |

### Lote 2 (proxima sesion)

- Migrante retornado (checklist completo)
- Adulto mayor reporte tercero
- Salud receta
- Circular escolar
- Estafa empleo
- Modo panico violencia domestica

### 4.1 Estructura de un caso

```dart
// kan-app/lib/models/kan_case.dart (extension)
class KanCase {
  final String code;             // 'igss_sin_dpi'
  final String label;            // 'IGSS no me atiende sin DPI'
  final String institutionTarget;// 'IGSS'
  final List<String> toolChain;  // hint para el reasoner
  final ArtifactTemplate artifact;
  final bool requiresVoice;
  final bool requiresPhoto;
  final bool allowsNoCui;
}
```

### 4.2 Plantilla de artefacto

```dart
// kan-app/lib/models/generated_artifact.dart
class GeneratedArtifact {
  final String type;          // 'denuncia_mp' | 'solicitud_igss' | 'sms_familia' | ...
  final String titulo;        // visible al usuario
  final String contenidoMd;   // markdown listo para renderizar/imprimir
  final Map<String,String> camposClave; // pseudonimo, fecha, articulo citado
  final String hashSha256;    // sobre contenidoMd canonical
  final String sigEd25519;    // firma local
}
```

Renderizado en `artifact_card.dart`:
- Titulo grande.
- Contenido markdown.
- Botones: **Escuchar**, **Copiar**, **Compartir**, **QR firmado**, **Imprimir**.

---

## 5. Bloque C — Loop ReAct (determinista + Gemma)

### 5.1 Tipo de evento

```dart
// kan-app/lib/services/agent/agent_step.dart
sealed class AgentStep {
  final DateTime ts;
}
class PlanStep extends AgentStep   { final String content; }
class ToolCallStep extends AgentStep { final String tool; final Map<String,dynamic> input; }
class ObservationStep extends AgentStep { final String content; final Map<String,dynamic>? data; }
class FinalStep extends AgentStep  { final String summary; final List<String> nextSteps; final GeneratedArtifact artifact; }
class ErrorStep extends AgentStep  { final String message; }
```

### 5.2 Contrato de herramienta

```dart
// kan-app/lib/services/agent/agent_tool.dart
abstract class AgentTool {
  String get name;
  String get description;        // descripcion para el prompt de Gemma
  Map<String,dynamic> get inputSchema; // JSON-schema-lite
  Future<Map<String,dynamic>> call(Map<String,dynamic> input);
  bool get readsPii;             // si lee PII, no se llama bajo cleartext con Gemma
  bool get producesArtifact;
}
```

`tool_registry.dart` registra todas y expone `describeAllForPrompt()` que genera el bloque de tools que se incluye en el prompt de Gemma.

### 5.3 Orquestador

```dart
// kan-app/lib/services/agent/agent_loop.dart
Stream<AgentStep> runAgentLoop({
  required CitizenInput input,           // texto + foto + audio
  required KanCase caseHint,             // el clasificador puede cambiarlo
  required Reasoner reasoner,            // Gemma o deterministico
  required ToolRegistry tools,
  int maxIterations = 5,
}) async* {
  yield PlanStep(content: 'Voy a entender el caso y proteger tu PII');

  // 1. Redaccion previa siempre (PII nunca cruza al modelo)
  final redacted = await tools.call('redact_pii', {'raw': input.toRawMap()});
  yield ObservationStep(content: 'PII bloqueada', data: redacted);

  // 2. Loop ReAct
  String? scratchpad;
  for (var i = 0; i < maxIterations; i++) {
    final decision = await reasoner.decideNextStep(
      caseHint: caseHint,
      redactedInput: redacted,
      scratchpad: scratchpad,
      tools: tools.describeAllForPrompt(),
    );

    if (decision.action == 'final') {
      yield FinalStep(
        summary: decision.summary!,
        nextSteps: decision.nextSteps!,
        artifact: await tools.callArtifact(decision.artifactSpec!),
      );
      return;
    }

    if (decision.action == 'tool_call') {
      yield ToolCallStep(tool: decision.tool!, input: decision.input!);
      final result = await tools.call(decision.tool!, decision.input!);
      yield ObservationStep(content: _summarize(result), data: result);
      scratchpad = (scratchpad ?? '') + '\nTOOL ${decision.tool} -> ${jsonEncode(result)}';
    }
  }

  yield ErrorStep(message: 'Limite de iteraciones alcanzado, fallback determinista');
}
```

### 5.4 Reasoner contract para ReAct

```dart
class ReasonerDecision {
  final String action;           // 'tool_call' | 'final'
  final String? tool;
  final Map<String,dynamic>? input;
  final String? summary;
  final List<String>? nextSteps;
  final ArtifactSpec? artifactSpec;
}

abstract class Reasoner {
  Future<ReasonerDecision> decideNextStep({
    required KanCase caseHint,
    required Map<String,dynamic> redactedInput,
    String? scratchpad,
    required String tools,
  });
}
```

### 5.5 Implementacion deterministica (planificador real)

`local_deterministic_reasoner.dart` se reescribe como planificador, no switch:

```dart
class LocalDeterministicReasoner implements Reasoner {
  Future<ReasonerDecision> decideNextStep(...) async {
    // 1. Si no hay clasificacion, llamar classify_case
    if (!scratchpad.contains('TOOL classify_case')) {
      return ReasonerDecision(action: 'tool_call', tool: 'classify_case', input: redactedInput);
    }
    // 2. Si caso es extorsion y no hay articulo CP, lookup_codigo_penal
    final caso = _extractClassification(scratchpad);
    if (caso == 'extorsion' && !scratchpad.contains('TOOL lookup_codigo_penal')) {
      return ReasonerDecision(action: 'tool_call', tool: 'lookup_codigo_penal', input: {'category':'extorsion'});
    }
    // 3. Si tenemos clasificacion + articulo y no hay denuncia, draft_denuncia
    if (!scratchpad.contains('TOOL draft_denuncia')) { ... }
    // 4. Final
    return ReasonerDecision(action: 'final', summary: '...', nextSteps: [...], artifactSpec: ArtifactSpec(...));
  }
}
```

Cada caso tiene su `_planFor(case)` que es una secuencia ordenada de tool_calls con guardas. Es determinista, pero **emite el mismo Stream<AgentStep>** que Gemma. El juez no nota la diferencia salvo por el badge "Reasoner: local-deterministic" arriba del panel.

### 5.6 Implementacion Gemma (ReAct multi-turn)

`litert_gemma_reasoner.dart` reescribe el prompt:

```text
Sos ZPK Agent. Trabajas offline en Guatemala. Nunca pidas CUI ni datos sensibles; ya fueron filtrados.

HERRAMIENTAS DISPONIBLES:
{{tool_registry.describeAllForPrompt()}}

Caso reportado: {{case_hint.label}}
Input redactado: {{redactedInput}}

Historia de pasos previos:
{{scratchpad}}

Decide el siguiente paso. Responde SOLO con JSON valido en una de estas dos formas:
{"action":"tool_call","tool":"<nombre>","input":{...}}
{"action":"final","summary":"...","next_steps":["..."],"artifact":{"type":"...","content":"..."}}
```

Parser estricto en `agent_response_contract.dart` (ya existe, se extiende para nuevos shapes). Si el JSON es invalido, se reintenta una vez con mensaje "JSON invalido, repite". Si falla dos veces, se delega a determinista preservando el scratchpad.

### 5.7 Fallback gradual

- Si Gemma fail-cerrado por hash, RAM, timeout: el loop se reinicia desde scratch en determinista.
- Si Gemma decide bien hasta paso 3 y luego falla: el loop continua en determinista con el scratchpad acumulado.
- Esto se llama **graceful fallback** y se anuncia con un step `ObservationStep(content: 'Gemma se cayo, sigo en modo local')`.

### 5.8 Tests

```
test/services/agent_loop_test.dart
  - loop_terminates_with_final_in_deterministic
  - loop_falls_back_when_reasoner_throws
  - loop_respects_max_iterations
  - loop_emits_steps_in_order
  - tool_call_with_redacted_input_never_contains_cui
```

---

## 6. Bloque D — Multimodal on-device

### 6.1 Voz a texto (STT)

- Plugin: `speech_to_text: ^7.x`.
- Locales: `es-GT`, `es-MX` (fallback), `es-ES` (fallback).
- 100% on-device en Android moderno (verificar `isOnDevice` flag al iniciar).
- `stt_service.dart`:
  ```dart
  Stream<String> transcribePartial();
  Future<String> finalize();
  Future<bool> get isOnDevice;
  ```
- Si `isOnDevice == false`, mostrar warning "Tu telefono enviaria audio a Google. Cancelado." Bloquea la accion.

### 6.2 Texto a voz (TTS)

- Plugin: `flutter_tts: ^4.x`.
- Setea `setSharedInstance(false)`, `awaitSpeakCompletion(true)`.
- Voces preferidas: `es-GT-SoniaNeural` (si Google la sirve), fallback `es-MX`.

### 6.3 OCR

- Plugin: `google_mlkit_text_recognition: ^0.x` (offline, modelo Latin script).
- `ocr_service.dart`:
  ```dart
  Future<OcrResult> recognize(File image);
  ```
- Result incluye texto + bounding boxes (utiles para resaltar lo extraido al usuario).
- La imagen original se borra del cache despues de OCR. Solo el texto entra al agente.

### 6.4 Camara

- Plugin: `camera: ^0.x`.
- Captura JPEG, la pasa a OCR, descarta archivo.
- Permisos en `AndroidManifest.xml` ya gestionados por plugin; agregar `<uses-permission android:name="android.permission.CAMERA"/>` y `RECORD_AUDIO` para mic.

### 6.5 Privacidad

- Privacy guard se ejecuta sobre el texto extraido por OCR/STT antes de mostrarse al usuario.
- Si detecta CUI/telefono/email, los marca con tachado en la UI ("se redacto antes de pensar").

---

## 7. Bloque E — Modo Ventanilla (institucion)

### 7.1 Onboarding y switching

Primera vez que abre la app: pregunta rol.
- "Soy ciudadano" -> guarda `role=citizen` en SharedPreferences.
- "Soy ventanilla institucion" -> pide elegir institucion (IGSS / SAT / MP / Colegio / MTPS / Otro) y carga su keypair de demo.

Cambio de rol despues: drawer -> "Cambiar a Modo Ventanilla". Confirmacion explicita.

### 7.2 UI Ventanilla

```
+--------------------------------------------------+
| Mesa: IGSS - Quetzaltenango   [logout/role swap] |
+--------------------------------------------------+
|                                                  |
|  [ Boton grande: ESCANEAR QR DEL CIUDADANO ]    |
|                                                  |
|  [ Tarjeta paquete recibido, oculto al inicio ]  |
|    - Pseudonimo                                  |
|    - Caso                                        |
|    - Hash                                        |
|    - Firma valida? OK / FALLA                    |
|    - Campos incluidos vs redactados (diff view)  |
|    - Boton: ATENDER                              |
|    - Boton: FIRMAR ACUSE                         |
|    - Boton: RECHAZAR (con razon)                 |
|                                                  |
|  [ Ledger: ultimas 10 atenciones de hoy ]        |
|                                                  |
+--------------------------------------------------+
```

### 7.3 Flujo de atencion

1. Funcionario tap "Escanear QR".
2. Camara abre, `mobile_scanner` decodifica.
3. Payload se decodifica (`packet_codec.dart`): base64url -> gunzip -> JSON.
4. Se verifica firma con `signature_verifier.dart` contra el pubkey embebido en el packet (auto-anchor) o contra el trust list local si es credencial emitida por institucion.
5. Se calcula y compara hash del contenido.
6. Si todo OK: muestra `received_packet_card` con `field_diff_view`.
7. Funcionario revisa, decide:
   - **Atender**: marca paquete como atendido en ledger institucional.
   - **Firmar acuse**: genera `acuse_record` firmado con keypair institucion, se muestra como QR para que el ciudadano lo escanee. Alternativa: share-sheet (envio por WhatsApp).
   - **Rechazar**: pide razon corta, registra en ledger.
8. Cada accion se persiste en `agent_execution_ledger.dart` con campo `role: institution`.

### 7.4 Trust list

```dart
// kan-app/lib/services/zpk/institution_trust_list.dart
class InstitutionTrustList {
  static const Map<String, String> demoPublicKeys = {
    'IGSS_DEMO': 'ed25519:...',
    'SAT_DEMO': 'ed25519:...',
    'MP_DEMO': 'ed25519:...',
    'COLEGIO_DEMO': 'ed25519:...',
    'MTPS_DEMO': 'ed25519:...',
  };
  bool isKnownInstitution(String pubkey);
  String? labelFor(String pubkey);
}
```

Para demo, los keypairs de institucion se generan al primer arranque del modo ventanilla y se publica el pubkey en un archivo `submission/trust-list.json` que se incluye en el ZIP. En produccion real, vendrian de un registro publico institucional.

### 7.5 Tests

```
test/widget/ventanilla_home_test.dart
  - opens_camera_when_scan_pressed
  - rejects_packet_with_invalid_signature
  - rejects_packet_with_invalid_hash
  - shows_field_diff_correctly
  - signs_acuse_with_institution_keypair
  - persists_acuse_in_ledger
```

---

## 8. Bloque F — Protocolo ZPK ciudadano-institucion

### 8.1 Shape canonico del paquete

```json
{
  "v": 1,
  "type": "intake|credential|revocation|acuse",
  "case": "igss_sin_dpi",
  "issued_at": 1714742400,
  "issuer": {
    "kind": "citizen|institution",
    "pseudo": "zpk:abc123...",
    "pubkey": "ed25519:..."
  },
  "audience": {
    "institution": "IGSS",
    "mesa": "Quetzaltenango"
  },
  "fields": {
    "nombre_pila": "Ana",
    "edad": 67,
    "departamento": "Quetzaltenango",
    "necesidad": "atencion presencial sin DPI"
  },
  "redacted": ["cui","telefono","direccion_completa","fecha_nacimiento"],
  "artifact_ref": {
    "type": "solicitud_igss",
    "hash": "sha256:..."
  },
  "policy": {
    "expires_at": 1714828800,
    "single_use": true
  },
  "sig": "ed25519:...over canonical(packet without sig)..."
}
```

Canonicalizacion: JSON con keys ordenadas alfabeticamente, sin espacios. Se firma sobre los bytes UTF-8 de eso. Bibliotecas: `pointycastle` ya esta en el proyecto para firmas Ed25519 (verificar en `pubspec.yaml`).

### 8.2 Codec QR

```dart
// kan-app/lib/services/zpk/packet_codec.dart
String encode(PacketEnvelope p) {
  final canonical = canonicalJson(p.toJson());
  final gz = gzip.encode(utf8.encode(canonical));
  return 'zpk1:' + base64UrlEncode(gz);
}

PacketEnvelope decode(String s) {
  if (!s.startsWith('zpk1:')) throw FormatException();
  final gz = base64UrlDecode(s.substring(5));
  final canonical = utf8.decode(gzip.decode(gz));
  return PacketEnvelope.fromJson(jsonDecode(canonical));
}
```

Tamano objetivo: <1KB tras gzip+base64. Si excede, el `artifact_ref` apunta solo al hash y el contenido se transmite por share-sheet aparte (WhatsApp, AirDrop, NFC).

### 8.3 Multi-frame QR (futuro)

Si algun caso pasa de 2KB, soportar multi-QR animado con `qr_flutter`'s `QrImage` rotando frames. No prioritario en lote 1.

### 8.4 Acuse de recibo

```json
{
  "v": 1,
  "type": "acuse",
  "in_response_to": "sha256:<hash del packet ciudadano>",
  "issued_at": 1714742460,
  "issuer": { "kind": "institution", "pubkey": "ed25519:...", "label": "IGSS_DEMO" },
  "decision": "atendido|en_revision|rechazado",
  "ticket": "IGSS-2026-05-03-00042",
  "next_step_text": "Presentarse mesa 4, viernes 9am",
  "sig": "ed25519:..."
}
```

El ciudadano lo escanea con la misma camara (modo "Escanear acuse"). Se guarda en su ledger personal.

### 8.5 Revocacion

```json
{
  "v": 1,
  "type": "revocation",
  "revokes": "sha256:<hash del packet original>",
  "issued_at": 1714742500,
  "issuer": { "kind": "citizen", "pseudo": "zpk:abc..." },
  "reason": "ya_no_aplica",
  "sig": "ed25519:..."
}
```

La ventanilla, antes de procesar, escanea cualquier revocacion. Si recibe una que cancela un packet pendiente, lo marca como `revoked` en su ledger.

### 8.6 Auditoria cruzada

Si hay disputa, ambos ledgers (ciudadano e institucion) se exportan y se comparan: cada packet debe tener su acuse, cada acuse debe tener packet.

### 8.7 Tests

```
test/services/zpk_packet_codec_test.dart
  - encode_then_decode_roundtrip
  - rejects_bad_prefix
  - rejects_corrupted_gzip
  - canonical_json_is_stable

test/services/signature_verifier_test.dart
  - verifies_valid_signature
  - rejects_tampered_field
  - rejects_wrong_pubkey
  - hash_matches_canonical_content
```

---

## 9. Bloque G — Dataset SFT ampliado + harness eval

(Sin entrenar todavia, sin GRPO, sin maya.)

### 9.1 Expandir dataset

`unsloth/generate_guatemala_latam_sft.py` ya genera 9840/1080/1080 sobre 7 escenarios. Extender:

- Agregar escenarios: `migrante_retornado`, `derechos_laborales`, `salud_receta`, `circular_escolar`, `estafa_empleo`, `adulto_mayor_terceros`.
- Cambiar formato de assistant content: en vez de un JSON final, secuencia ReAct:
  ```json
  [
    {"role":"assistant","content":"{\"action\":\"tool_call\",\"tool\":\"classify_case\",\"input\":{...}}"},
    {"role":"tool","name":"classify_case","content":"{...}"},
    {"role":"assistant","content":"{\"action\":\"tool_call\",\"tool\":\"lookup_codigo_penal\",\"input\":{...}}"},
    {"role":"tool","name":"lookup_codigo_penal","content":"{...}"},
    {"role":"assistant","content":"{\"action\":\"final\",...}"}
  ]
  ```
- Esto le ensena al modelo el formato ReAct, no solo respuestas one-shot.
- Target: 18000 train / 2000 val / 2000 test.

### 9.2 Harness eval

`unsloth/evaluate_dataset.py` ya pasa. Agregar metricas:
- `json_validity_rate`: % de outputs que son JSON parseable.
- `react_format_rate`: % que respetan `{action, tool, input}` o `{action:final, ...}`.
- `pii_leak_rate`: % donde aparece un patron CUI/telefono en la respuesta del modelo.
- `tool_chain_completeness`: % donde la cadena llega a `final` sin loops.

Reportar al jurado como tabla en el writeup. Sin training, los numeros son los del modelo base Gemma 4 E2B; sirven como baseline para mostrar el delta cuando se entrene.

### 9.3 Scripts listos para GPU externo

`unsloth/train_lora.py` ya existe. Asegurar que con un solo comando arranca:
```bash
uv run python train_lora.py --base gemma-4-E2B --dataset data/ --out adapters/zpk-gt-v1
```

`unsloth/distill_with_gemma4_teacher.py` igualmente. Documentar en README de `unsloth/` que esto se corre en Colab/RTX GPU, no en Mac.

### 9.4 Sin training en esta sesion

Honestidad al jurado en el writeup:
> "Dataset SFT de 22K ejemplos en formato ReAct para Gemma 4 E2B. Harness de evaluacion con 4 metricas. Scripts de LoRA + distill listos. Pesos entrenados pendientes de corrida en GPU; baseline reportado con modelo base."

---

## 10. Plan de ejecucion por fases

### Fase 1 — Cimientos (sin romper nada)
1. Crear `services/agent/` con `agent_step.dart`, `agent_tool.dart`, `tool_registry.dart`, `agent_loop.dart`.
2. Crear `services/zpk/` con `packet_envelope.dart`, `packet_codec.dart`, `signature_verifier.dart`.
3. Tests unitarios para los dos modulos.
4. `flutter analyze` y `flutter test` deben quedar verdes.

### Fase 2 — Reasoners refactor
1. Refactor `local_deterministic_reasoner.dart` a `Reasoner` con `decideNextStep`.
2. Mantener wrapper de compatibilidad para que `home_screen.dart` viejo siga funcionando (no se rompe `verify_motorola_physical_flow.sh`).
3. Implementar 5 tools del lote 1.
4. Tests del loop end-to-end.

### Fase 3 — UI ciudadano nueva
1. Crear `features/citizen/citizen_home.dart` y widgets.
2. Wire al `agent_loop`.
3. Switch en `main.dart` segun rol guardado en SharedPreferences (default `citizen`).
4. Drawer con "Modo avanzado" -> vista vieja.
5. Widget tests.

### Fase 4 — Multimodal
1. Agregar plugins en `pubspec.yaml`: `speech_to_text`, `flutter_tts`, `google_mlkit_text_recognition`, `camera`, `mobile_scanner`, `qr_flutter`.
2. Permisos Android en manifest.
3. Wrappers en `services/multimodal/`.
4. Probar en Motorola.

### Fase 5 — Modo Ventanilla
1. Crear `features/institution/ventanilla_home.dart` y widgets.
2. Trust list + acuse codec.
3. Flujo escanear -> verificar -> firmar acuse -> mostrar QR.
4. Widget tests.

### Fase 6 — Protocolo ZPK puerta a puerta
1. Conectar lado ciudadano con `share_packet_sheet` que muestra QR del packet.
2. Conectar lado ventanilla con scanner.
3. Probar end-to-end con dos telefonos (o un telefono y un emulador).

### Fase 7 — Dataset y eval (sin training)
1. Extender `generate_guatemala_latam_sft.py`.
2. Agregar metricas a `evaluate_dataset.py`.
3. Documentar en `unsloth/README.md`.

### Fase 8 — Empaquetado y verificacion
1. `./scripts/package_demo.sh` actualizado para incluir trust list.
2. `./scripts/verify_submission.sh` actualizado:
   - Verifica que `citizen_home.dart` existe.
   - Verifica que `ventanilla_home.dart` existe.
   - Verifica que `tool_registry` registra >= 8 tools.
   - Verifica que pubspec contiene los plugins requeridos.
3. Reinstalar APK en Motorola, correr `verify_motorola_physical_flow.sh`.
4. Regenerar checksums.

---

## 11. Dependencias nuevas en pubspec

```yaml
dependencies:
  speech_to_text: ^7.0.0
  flutter_tts: ^4.2.0
  google_mlkit_text_recognition: ^0.13.0
  camera: ^0.11.0
  mobile_scanner: ^5.2.0
  qr_flutter: ^4.1.0
  pointycastle: ^3.9.1     # ya puede estar
  archive: ^3.6.1          # gzip
  shared_preferences: ^2.3.0  # role storage
```

Verificar tamano del APK despues. ML Kit anade ~10 MB. Aceptable.

---

## 12. Permisos AndroidManifest

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
```

`INTERNET` se sigue manteniendo si la instalacion del modelo requiere descarga, pero se puede revocar despues de instalar via runtime check. Documentarlo.

`allowBackup=false`, `usesCleartextTraffic=false` ya estan y se mantienen.

---

## 13. Verificacion que no se rompa lo verde

Despues de cada fase, correr:

```bash
cd kan-app && flutter analyze
cd kan-app && flutter test
./scripts/verify_submission.sh
./motorola/verificar-apk.sh
./scripts/verify_motorola_physical_flow.sh --no-install
```

Lista de invariantes:
- `flutter analyze` -> No issues found.
- `flutter test` -> al menos 74 tests pasan (los nuevos suman, no restan).
- `verify_submission.sh` -> PASS.
- Vista vieja sigue accesible y los textos buscados por UIAutomator (`Mesa institucional IGSS`, `Continuar sin CUI`, etc.) siguen vivos en el "Modo avanzado".
- APK release sigue firmado, sin `kan-debug.apk`, sin `features/demo`.

---

## 14. Riesgos y cortes honestos

| Riesgo | Mitigacion | Si no se mitiga |
|---|---|---|
| Plugins STT no son on-device en algunos devices | Verificar `isOnDevice` al iniciar y bloquear si no | Mostrar warning explicito, permitir solo texto |
| ML Kit OCR descarga modelo Latin la primera vez | Pre-empaquetar con `play-services` o documentar primer-uso con conexion | Aceptar primer-uso online, despues offline |
| Gemma E2B no emite ReAct JSON valido el 100% del tiempo | Reintentar 1 vez, fallback a determinista | Determinista cubre el demo |
| QR muy grande para algunos artefactos | `artifact_ref` por hash + share-sheet del documento | Documentar limite |
| Ventanilla y Ciudadano en mismo APK confunde al jurado | Onboarding explicito + colores distintos por rol | Hacer dos APKs separados (mas trabajo) |
| Permiso de camara/mic asusta al usuario | Pantalla de explicacion antes de pedir permiso | Aceptar friction |
| Tiempo: 8 fases es mucho para una sesion | Cortar en Fase 6 si se necesita; Fase 7 es separable | Documentar lo que queda |

Cortes honestos al jurado:
- Sin SNARKs reales (firma + hash + minimizacion, no zk-proofs).
- Sin Gemma 4 vision on-device (OCR via ML Kit).
- Sin training del LoRA en esta entrega (dataset y harness listos).
- Sin maya (queda fuera, demasiado).
- Sin background SMS monitoring (decision de privacidad).

---

## 15. Guion de demo para el jurado (60 segundos)

```
[0-5s]
Pantalla unica. Modo avion ON. Boton MIC grande.
Voz: "Me llego un mensaje raro pidiendo dinero."
[5-15s]
Panel agente se anima:
  plan: "Voy a clasificar y proteger tu PII"
  tool_call: redact_pii
  observation: "PII bloqueada"
  tool_call: classify_case
  observation: "extorsion telefonica, confianza alta"
  tool_call: lookup_codigo_penal
  observation: "Art. 261 CP"
  tool_call: draft_denuncia
  observation: "Borrador listo"
  tool_call: sign_packet
  final: muestra documento
[15-25s]
Tarjeta documento: "Denuncia para MP" con texto formal completo.
Panel privacidad: "Lo que NO sale del telefono: CUI, telefono, direccion."
Boton "Escuchar" -> TTS lee el resumen en es-GT.
[25-35s]
Tap "QR firmado" -> aparece QR.
Cambio de telefono al Modo Ventanilla MP.
Tap "Escanear QR" -> camara -> verifica firma OK -> hash OK.
Field diff: "Recibido: 4 campos. Redactado: CUI, telefono, direccion, fecha_nacimiento."
[35-45s]
Tap "Firmar acuse" -> genera QR de acuse "MP-2026-05-03-00007 atendido".
Vuelve al telefono ciudadano, escanea acuse.
Ledger ciudadano muestra: paquete enviado + acuse recibido + ambas firmas.
[45-60s]
Mostrar Motor: "DEVICE_LOW_MEMORY, Respaldo offline, runtime.local_deterministic ready".
Decir: "Hoy Gemma 4 esta instalado y verificado por hash. En este Motorola la RAM no alcanza, asi que el plan B determinista corrio el mismo loop. En un telefono de 6GB+, Gemma habria llevado el loop. La interfaz no cambia."
Modo Avion sigue ON todo el tiempo. Cero red.
```

---

## 16. Que queda fuera (proxima sesion)

- Lote 2 de casos (5 mas).
- Modo Abuela completo.
- Modo Silencio / panico.
- Multi-frame QR para artefactos grandes.
- Training real del LoRA (necesita GPU).
- Gemma 4 vision on-device cuando flutter_gemma lo exponga.
- Mayan languages.
- Background SMS monitoring (descartado a proposito).
- Integracion API real con instituciones (descartado a proposito; siempre artefacto local + share-sheet).

---

## 17. Glosario rapido para el writeup

- **ReAct**: patron Reason + Act. El modelo alterna pensamiento y llamadas a herramientas.
- **PII**: Personally Identifiable Information. Aqui CUI, DPI, telefono, email, direccion.
- **ZPK**: en este proyecto significa "zero-PII-knowledge" en estilo: minimizacion + firma + hash + auditoria. No SNARKs.
- **Pseudonimo**: identificador derivado del pubkey local del ciudadano. Estable por dispositivo, no liga a CUI.
- **Acuse**: comprobante firmado por la institucion de que recibio un packet.
- **Trust list**: lista de pubkeys institucionales conocidas para verificar credenciales emitidas.

---

## 18. Decisiones que necesito confirmadas antes de codear

1. Onboarding de rol: ok que pregunte al primer arranque y guarde en SharedPreferences? (alternativa: dos APKs separados, mas trabajo).
2. Plugins propuestos en seccion 11: ok meter `speech_to_text`, `flutter_tts`, `google_mlkit_text_recognition`, `camera`, `mobile_scanner`, `qr_flutter`?
3. Mantener la vista vieja (`features/identity_wallet/home_screen.dart`) accesible desde drawer "Modo avanzado": ok? (necesario para no romper UIAutomator).
4. Trust list de demo con keypairs autogenerados al primer arranque del modo ventanilla: ok? (alternativa: pre-bakear pubkeys institucionales falsos en el codigo, mas reproducible).
5. Acuse de vuelta al ciudadano por QR escaneado: ok? (alternativa: NFC, mas demo-friendly pero mas codigo).
6. Lote 1 de 5 casos confirmado, Lote 2 va en proxima sesion: ok?

Cuando me confirmes los 6 puntos arranco con Fase 1.
