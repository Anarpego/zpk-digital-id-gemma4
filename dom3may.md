# Contexto domingo 3 de mayo - ZPK Digital ID + Gemma 4 ReAct vivo

## Proposito de este archivo

Handoff completo de la sesion del 2026-05-03. Documenta:
- Como quedo la app despues de las Fases 1-8 del plan apptowin.md
- **El cambio mas grande del dia**: Gemma 4 E2B-it corriendo de verdad en
  un Honor 200 fisico, manejando un loop ReAct multi-turn con tool calling
  reparable y safety-net deterministico
- Casos de uso del Lote 1 listos en device
- Que esta verificado en hardware real y que no
- Que sigue valido de la submission del 2 de mayo

Complementa (no reemplaza) `sabado2context.md`. Lo del 2 de mayo sigue
siendo verdad para la submission empaquetada; lo de hoy son features
nuevas que viven en el repo source y en una APK debug paralela.

## Resumen ejecutivo de un parrafo

ZPK Digital ID es una app Flutter Android con dos lados en una sola APK:
**Modo Ciudadano** (una pantalla con voz, camara, teclado, agente visible
paso a paso, documento firmado al final) y **Modo Ventanilla** (institucion
escanea QR del ciudadano, verifica firma HMAC-SHA256 local, firma acuse,
devuelve QR de vuelta). El loop agentico corre en device con dos brains
intercambiables: **Gemma 4 E2B-it (LiteRT-LM)** decide ReAct cuando el
device tiene RAM suficiente (Honor 200, 12 GB, **probado en vivo hoy**),
y un **planificador determinista local** corre el mismo loop con los
mismos tools cuando Gemma no aplica (Motorola G15, 3.8 GB) o cuando
Gemma cierra prematuro. Los dos brains comparten 9 herramientas
(redact_pii, classify_case, lookup_codigo_penal, lookup_codigo_trabajo,
lookup_institucion, draft_denuncia, draft_solicitud, draft_sms_familia,
sign_packet) y producen el mismo Stream<AgentStep> visible en la UI.
Cero red en uso normal. PII nunca cruza al modelo.

## Que es esta aplicacion (vista completa)

### El problema que resuelve

En Guatemala, el ciudadano promedio queda atrapado entre dos
realidades cuando algo sale mal:

- Le llega una **extorsion por WhatsApp/SMS** y no sabe si es real ni
  como denunciarla; muchos terminan pagando o ignorando.
- Tiene que hacer un tramite en **IGSS o SAT** y le piden DPI fisico
  que no tiene a la mano; lo mandan de vuelta a su casa.
- Una **estafa de remesa** ("Western Union impostor", "paquete
  retenido") le saca dinero antes de poder verificar.
- Lo **despiden sin pagar prestaciones** y no sabe que articulos del
  Codigo de Trabajo invocar para reclamar.
- Mientras tanto, sus datos (CUI/DPI, telefono, direccion) circulan
  libremente entre canales inseguros — WhatsApp, formularios
  fotografiados, copias en sucursales. Las instituciones reciben
  informacion completa que no necesitan, la guardan en bases que se
  filtran (RENAP y SAT ya tuvieron incidentes documentados), y el
  ciudadano nunca tiene prueba de que entrego, ni control de que
  retiraron.

ZPK Digital ID es la primera linea de defensa para estas situaciones,
pensada para correr en el telefono que la persona ya tiene.

### Que hace la app, contado en lenguaje simple

Una persona abre la app y ve **una sola pantalla** con la pregunta
"Que te paso?". Tres formas de responder:

- **Hablar** (boton de microfono grande). El telefono escucha y
  transcribe en es-GT (es-MX como fallback). Todo on-device, ningun
  audio sale.
- **Mostrar** (boton de camara). Saca foto del SMS sospechoso, del
  comprobante falso, del citatorio que recibio. Google ML Kit extrae
  el texto en el telefono y la imagen se descarta. La foto nunca sale.
- **Escribir** (teclado, si prefiere).

Apreta "Ayudame ahora". En la pantalla aparece el **agente trabajando
en vivo**, paso a paso, con chips por cada herramienta que invoca y
observaciones por cada resultado:

```
Voy a entender el caso y proteger tus datos personales
Datos sensibles bloqueados antes de pensar
[redact_pii]    Sin datos sensibles detectados
[classify_case] extorsion_telefono_sms (confianza 67%)
[lookup_codigo_penal] Art. 261 Extorsion (Codigo Penal)
[lookup_institucion]  Ministerio Publico — tel 1572
[draft_sms_familia]   Mensaje listo (189 chars)
[draft_denuncia]      Denuncia formal lista (720 chars)
[sign_packet]         Firmado con llave local
Listo: detecte extorsion. Genere denuncia para MP citando Art. 261...
```

Al final aparece **el documento real**, en markdown formal, con hash
SHA-256, fecha actual, pseudonimo local del ciudadano. La persona puede:
- **Escuchar** el documento en voz alta (TTS es-GT). Importante para
  abuelas con baja alfabetizacion: confian en lo que les leen, no en
  lo que les ponen enfrente para firmar.
- **Copiar** al portapapeles o **Compartir** por WhatsApp/email.
- **Mostrar QR firmado** para llevar a la ventanilla de la institucion.

Mientras tanto, una tarjeta plegable abajo dice **"Datos bloqueados
antes de pensar"** y lista lo que NO salio del telefono: tu DPI, tu
telefono, tu direccion completa. Con candado tachado al lado de cada
campo. La privacidad es visible en cada interaccion, no es una
promesa abstracta de Settings.

### Y del otro lado de la ventanilla

La misma APK tiene un **Modo Ventanilla**. Un funcionario IGSS, SAT,
MP, MTPS, PDH, RENAP, PROFECO o de un colegio cambia de rol al
arrancar y ve una pantalla distinta, con color de fondo diferente y
el nombre de su mesa siempre visible.

Su unica accion principal: **escanear el QR del ciudadano**. La camara
abre, decodifica el packet, verifica la firma HMAC-SHA256 contra una
trust list pre-bakeada de las 9 instituciones, calcula y compara el
hash del contenido. En 1 segundo aparece tarjeta verde "Firma valida"
o roja "Firma invalida".

Si es valida, el funcionario ve el **field diff**: los campos que el
ciudadano incluyo (en negro) vs los que omitio (en gris tachado con
candado: CUI, telefono, direccion, fecha_nacimiento). La institucion
recibe lo minimo necesario para atender, no el expediente completo.

Decisiones disponibles:
- **Atender** (registra en ledger institucional)
- **Firmar acuse** (genera otro QR firmado por la mesa con ticket y
  proximo paso, para que el ciudadano lo escanee de vuelta y lo
  guarde como prueba)
- **Rechazar** con razon

El ciudadano vuelve a su modo, escanea el acuse, y ve "Acuse valido —
Ticket IGSS-2026-05-03-00007 atendido. Pase a mesa 4 con identificacion
alterna." El protocolo cierra puerta a puerta, sin pasar por ningun
servidor central.

### Que esta corriendo abajo

Bajo la pantalla del ciudadano hay un loop ReAct (Reason+Act). Dos
cerebros intercambiables manejan ese loop, segun el device:

- **Gemma 4 E2B-it** (Google, ~2 mil millones de parametros efectivos
  con per-layer embeddings) corre via LiteRT-LM en CPU del telefono
  cuando hay 6 GB+ de RAM. Decide cada paso del loop generando un JSON
  ReAct: "siguiente accion: llamar tal herramienta con tal input", o
  "ya tengo todo, cierro con el documento". Probado en vivo en Honor
  200 (12 GB RAM).
- **Planificador local determinista** corre el mismo loop con las
  mismas herramientas cuando Gemma no aplica (RAM insuficiente, o
  Gemma se equivoca a mitad de camino). Probado en Motorola G15
  (3.8 GB).

Ambos cerebros comparten **9 herramientas locales**:
1. `redact_pii` — bloquea DPI/telefono/email/direccion antes de pensar
2. `classify_case` — clasifica el reporte en uno de los casos del Lote 1
3. `lookup_codigo_penal` — Art. 261/263/215 + decreto 97-96
4. `lookup_codigo_trabajo` — Art. 76/78/82 + 102 + 116/121
5. `lookup_institucion` — datos de MP/PNC/IGSS/SAT/MTPS/PDH/PROFECO/RENAP
6. `draft_denuncia` — denuncia formal markdown citando articulo
7. `draft_solicitud` — solicitud institucional, con modalidad sin_dpi
8. `draft_sms_familia` — mensaje breve para WhatsApp/SMS
9. `sign_packet` — firma HMAC-SHA256 local

Y emiten todos el mismo `Stream<AgentStep>` (PlanStep, ToolCallStep,
ObservationStep, FinalStep, ErrorStep) que la UI renderiza como el
timeline animado. La interfaz no distingue cual cerebro la esta
manejando; el badge arriba dice "Gemma 4 E2B local" o "Plan
determinista local" para honestidad.

### Que protege la promesa "nada sale del telefono"

- **Modo avion en el AppBar** con icono permanente. Boton informativo
  que aclara "Cero red. Todo se procesa localmente."
- **Privacy guard** corre antes de cualquier prompt al modelo. Si
  detecta DPI/telefono/direccion en el texto, los redacta con regex
  (`[DPI_REDACTED]`, `[TELEFONO_REDACTED]`) antes de que Gemma vea
  nada.
- **Tarjeta visible "Datos bloqueados antes de pensar"** en cada
  interaccion. El usuario ve la promesa cumpliendose, no leida en
  Settings.
- **Cero analytics, cero telemetry, cero llamadas externas** en uso
  normal. La unica excepcion es la descarga del modelo Gemma la
  primera vez, que ocurre por boton explicito y se puede hacer por
  USB en vez de internet.
- **Firma local con keypair anclado al dispositivo** (Android Keystore
  en produccion, HMAC en demo). La institucion verifica la firma sin
  necesitar que el dispositivo se conecte a nada.

### Que la diferencia de un chatbot legal

- **Voz y foto primero, no texto**. Diseñada para abuelas con baja
  alfabetizacion, no para usuarios con teclado rapido.
- **Agente visible**, no caja negra. El usuario ve cada herramienta
  invocada y cada observacion. Confianza por evidencia, no por marca.
- **Documento real al final**, no bullets. La persona se queda con
  algo concreto y compartible.
- **Protocolo de dos lados** (ciudadano + ventanilla en la misma
  APK), no solo wallet. La asimetria institucional se rompe.
- **Funciona offline**, en el telefono que la persona ya tiene, sin
  cuenta, sin login, sin email, sin push notifications.
- **Tres tiers de hardware** soportados con el mismo binario y sin
  prometer falsamente lo que el device no aguanta (ver siguiente
  seccion).

### La pantalla vieja sigue accesible

La interfaz de las 5 pestanas Persona/Acciones/Institucion/Evidencia/Motor
quedo accesible desde el drawer "Modo avanzado". Esto preserva el
verificador `verify_motorola_physical_flow.sh` que busca textos
especificos de la UI vieja para validar la submission empaquetada del
2 de mayo.

## Lista exhaustiva de funcionalidades

Cada feature individual con su comportamiento concreto. Estado:
✅ implementado y probado en device, 🟢 implementado y probado solo
en tests unitarios, 🟡 cableado pero no validado end-to-end en device,
⏳ pendiente para proxima sesion, 📦 viene de sesiones anteriores y
sigue funcionando sin tocarse.

### Modo Ciudadano — entrada del usuario

**Layout y header**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Pantalla unica scrollable | ✅ | SafeArea + Padding 16, sin tabs |
| Titulo "ZPK · Modo Ciudadano" en AppBar | ✅ | TextStyle titleSmall del theme |
| Pregunta "Que te paso?" como h1 | ✅ | headlineSmall, izquierda alineada |
| Subtitulo "Contame con tus palabras..." | ✅ | bodyMedium gris, dos lineas |
| Estado vacio antes de pulsar enviar | ✅ | Solo pregunta + dock; no chips fantasmas |
| Bottom dock fijo (textfield + 3 botones) | ✅ | Card con surfaceContainerHighest |

**Boton microfono (mic)**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Tap inicia STT listening | ✅ | `_stt.startListening`, callback partial+final |
| Tap durante listening detiene y mete texto al TextField | ✅ | `_stt.stopListening`, transcript al controller |
| Icono rojo cuando esta escuchando | ✅ | `Icons.mic` color red vs `Icons.mic_none` |
| Tooltip cambia: "Hablar" / "Estoy escuchando..." | ✅ | Tooltip dinamico segun estado |
| Disabled durante generacion del agente | ✅ | onPressed null si _running |
| Verifica `isOnDevice` antes de iniciar | 🟡 | Si STT no es on-device, SnackBar "Tu telefono no permite STT on-device" |
| Locale detection es-GT > es-MX > es-ES > primer es-* | 🟡 | `_engine.locales()` y firstWhere chain |
| Live partial transcript va al TextField | 🟡 | Cada update de speech_to_text dispara setState |
| Long-press = modo silencio | ⏳ | Lote 2, NO implementado |
| Cancel listening al disponer widget | ✅ | dispose() llama `_stt.cancel()` |

**Boton camara**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Tap abre system camera (image_picker) | ✅ | `ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70)` |
| Cancela sin error si usuario sale | ✅ | picked == null retorna sin SnackBar |
| OCR de la foto via ML Kit Latin script | 🟡 | `OcrService.recognize(File(picked.path))` |
| Texto extraido va al TextField | 🟡 | setState con result.text |
| Imagen original NO se sube a ningun lado | ✅ | Procesa local, descarta File path |
| Recognizer disposed despues de OCR | ✅ | finally { ocr.dispose() } |
| Disabled durante generacion del agente | ✅ | onPressed null si _running |
| SnackBar de error si camara no disponible | 🟡 | "Camara no disponible: $e" |
| SnackBar si OCR falla | 🟡 | "No pude leer la imagen: $e" |

**TextField (teclado fallback)**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Multi-line minLines 2 maxLines 4 | ✅ | TextField config |
| Border rounded 12px con OutlineInputBorder | ✅ | Roundness consistent |
| Hint placeholder "Ej: me llego un mensaje raro pidiendo dinero" | ✅ | Visible cuando vacio |
| Disabled durante generacion | ✅ | enabled: !_running |
| TextInputAction newline (no submit) | ✅ | Permite saltos de linea |
| Edicion manual aun cuando STT mete transcript | ✅ | Controller compartido |

**Boton "Ayudame ahora"**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| FilledButton con icono send | ✅ | Material 3 filled style |
| Texto "Ayudame ahora" en idle | ✅ | Visible cuando !_running |
| Texto "Pensando..." durante generacion | ✅ | Cambia label cuando _running |
| Spinner circular en lugar del icono send | ✅ | CircularProgressIndicator strokeWidth 2 |
| Disabled si _running OR text vacio | ✅ | onPressed null en esos casos |
| Limpia steps anteriores al disparar | ✅ | _steps.clear() en setState |
| Cancela subscription previa | ✅ | _sub?.cancel() antes de listen nuevo |

### Modo Ciudadano — panel del agente razonando

**Container**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Card con surfaceContainerLow background | ✅ | Color suave para no robar foco |
| Border radius 16px | ✅ | Consistente con resto de cards |
| Padding interno 16px | ✅ | Material 3 spacing |
| Header con icono auto_awesome + "Agente razonando" | ✅ | TextStyle titleSmall |
| Badge del cerebro a la derecha del header | ✅ | Texto labelSmall negro54: "Gemma 4 E2B local" o "Plan determinista local" |
| Hidden si _steps.isEmpty | ✅ | SizedBox.shrink antes de iniciar |
| Steps apilados vertical con SizedBox 12 entre cards | ✅ | Layout limpio scrollable |

**Tipos de step renderizados**

| Step type | Estado | Comportamiento concreto |
|---|---|---|
| `PlanStep` | ✅ | Icon psychology_outlined + texto italica gris |
| `ToolCallStep` | ✅ | Icon handyman_outlined + chip con tool name (mono, primaryContainer color) + input compactado (mono pequeno) |
| `ObservationStep` | ✅ | Icon check_circle_outline + texto bodyMedium |
| `FinalStep` | ✅ | Icon task_alt + "Listo: ${summary}" en bold; dispara render del ArtifactCard abajo |
| `ErrorStep` | ✅ | Icon warning_amber color rojo + texto rojo error.shade800 |

**Streaming behavior**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Cada step aparece via setState al llegar del Stream | ✅ | Sin animation explicita pero render inmediato |
| Step delay 180ms en deterministico | ✅ | Visible "pensando" entre tools |
| Sin delay artificial en Gemma | ✅ | Latencia natural del modelo |
| Tool input mostrado: jsonEncode + truncate 60 chars | ✅ | `${input}` con `...` si excede |
| Chip de tool name en monospace | ✅ | Para parecer "comando ejecutado" |
| Observation summary (no data raw) | ✅ | `result.summary ?? _summarize(data)` |
| Switch a fallback emite ObservationStep especial | ✅ | "Cierre prematuro detectado, sigo con plan local" |
| Multi-iteraciones acumuladas (no clear entre tools) | ✅ | Lista crece visible hasta FinalStep |

### Modo Ciudadano — tarjeta del documento generado (ArtifactCard)

**Header de la tarjeta**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Card elevation 1 + rounded 16 | ✅ | Material 3 |
| Icono description + titulo del documento | ✅ | Ej: "Denuncia formal para MINISTERIO PUBLICO" |
| Titulo en titleMedium | ✅ | Linea unica, ellipsis si excede |
| Hash SHA-256 visible debajo | ✅ | TextStyle 11px monospace negro54, ellipsis |
| Divider 24px | ✅ | Separa header del contenido |

**Contenido del documento**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Render markdown formato selectable | ✅ | SelectableText, fontSize 14, lineHeight 1.4 |
| Container max height 280px | ✅ | Con SingleChildScrollView dentro |
| Texto seleccionable copiable a mano | ✅ | SelectableText permite seleccionar parrafos |
| Renders heading `# DENUNCIA FORMAL` | 🟡 | Plain text actualmente (no markdown widget); markdown formal funciona como text |
| Datos formateados: dirigida a, lugar/fecha, pseudonimo, hechos, fundamento legal, solicitud, anexos | ✅ | Templates en draft_denuncia_tool.dart |
| Fecha actual en formato espanol "3 de mayo de 2026" | ✅ | `_mes(int)` mapping |

**Lista de siguientes pasos**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Header "Siguientes pasos" | ✅ | titleSmall del theme |
| Bullet por paso (2-5 items) | ✅ | "• " + texto del step |
| Pasos accionables especificos por caso | ✅ | Incluye numero de telefono (1572 MP, 1522 IGSS, etc.) |
| Hidden si nextSteps esta vacio | ✅ | Conditional render |

**Botones de accion**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Boton Copiar (FilledButton.tonalIcon) | ✅ | Clipboard.setData con contenidoMd, SnackBar "Documento copiado" |
| Boton Escuchar (OutlinedButton.icon) | 🟡 | TTS speak con titulo + preview 600 chars + "...continua en pantalla" |
| Boton QR firmado | ✅ | onShowQr callback abre share_packet_sheet |
| Boton Compartir | 🟡 | Placeholder modal explica share-sheet del SO |
| Wrap layout para que botones envuelvan en pantallas chicas | ✅ | spacing 8 + runSpacing 8 |
| Solo muestra Escuchar si tts != null | ✅ | Conditional render |

**Bottom sheet del QR firmado (share_packet_sheet)**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Modal bottom sheet scrollable | ✅ | isScrollControlled, showDragHandle |
| Titulo "QR firmado del paquete" centrado | ✅ | titleMedium |
| Subtitulo explicativo "La ventanilla escanea esto..." | ✅ | bodySmall centrado |
| QR generado con qr_flutter QrImageView | ✅ | Size 280, errorCorrectionLevel M, fondo blanco con border |
| Metadata visible: Tipo, Caso, Pseudonimo, Hash artifact, Tamano payload | ✅ | _MetaRow con label + value mono cuando aplica |
| Boton "Listo" cierra el sheet | ✅ | Navigator.pop |
| Packet construido al vuelo con citizen demo key | ✅ | `_buildPacket(artifact, caseCode, institutionLabel)` |
| Policy expires_at +7 dias | ✅ | Por defecto |
| Single use marca | ✅ | Por defecto |
| Wire size visible al usuario | ✅ | "${wire.length} chars" |

### Modo Ciudadano — tarjeta de privacy diff

**Container**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Card elevation 0 plegable (ExpansionTile) | ✅ | Inicial colapsada |
| Color tertiaryContainer si redacto al menos 1 categoria | ✅ | Verde claro distintivo |
| Color surfaceContainerLow si nada redactado | ✅ | Neutral cuando no hay PII |
| Border radius 16 | ✅ | Consistente |

**Header colapsado**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Icono shield_outlined leading | ✅ | Universal "proteccion" |
| Titulo "Datos bloqueados antes de pensar" si hay redacciones | ✅ | titleSmall |
| Titulo "No se detectaron datos sensibles" si no | ✅ | Mismo style, mensaje opuesto |
| Subtitulo "${n} categoria(s) protegida(s)" cuando hay | ✅ | Solo aparece si redactedCategories no vacio |

**Contenido expandido**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Lista por categoria con icono lock + label legible + label "[BLOQUEADO]" | ✅ | Por categoria detectada |
| Mapeo: dpi_cui → "Tu DPI/CUI", telefono → "Tu telefono", email → "Tu email", direccion → "Tu direccion completa" | ✅ | _labels static map |
| Texto del label tachado (TextDecoration.lineThrough) | ✅ | Visualmente bloqueado |
| Label "[BLOQUEADO]" en monospace 11px negro54 a la derecha | ✅ | Estilo "log/diagnostic" |
| Mensaje educativo si no hay redacciones | ✅ | "No detecte DPI, telefono... Si el documento final menciona algun dato, fue porque lo agrego una herramienta local con autorizacion explicita." |

### Modo Ciudadano — AppBar (top bar)

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Title "ZPK · Modo Ciudadano" | ✅ | TextStyle por defecto del theme, ellipsis si pantalla chica |
| Icono avion (Icons.flight) | ✅ | Tooltip "Modo avion: nada sale del telefono" |
| Tap avion muestra SnackBar | ✅ | "Cero red. Todo se procesa localmente." |
| Icono qr_code_scanner | ✅ | Tooltip "Escanear acuse de ventanilla" |
| Tap qr_scanner abre scan_acuse_sheet | ✅ | Push de _AcuseScannerPage con MobileScanner; al detectar, sheet con verify result |
| Icono business_center_outlined (maletin) | ✅ | Tooltip "Modo Ventanilla (institucion)", solo si onOpenVentanilla != null |
| Tap maletin pushea VentanillaHome | ✅ | Con onExitToCitizen para volver |
| Icono tune | ✅ | Tooltip "Modo avanzado", solo si onOpenAdvancedMode != null |
| Tap tune pushea HomeScreen viejo | ✅ | Las 5 pestañas Persona/Acciones/Institucion/Evidencia/Motor |
| Disabled qr_scanner si _running | ✅ | onPressed null durante generacion |

### Sheet de scan de acuse (scan_acuse_sheet)

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| AppBar "Escanear acuse de ventanilla" | ✅ | _AcuseScannerPage |
| MobileScannerController detection noDuplicates | ✅ | Evita duplicados en stream |
| Pop con string del QR al primer detect | ✅ | Capture.barcodes.first.rawValue |
| Verify con QrService.looksLikeZpk first | ✅ | Si no es ZPK, SnackBar y null |
| Decode + verify con HmacSignatureVerifier (trust list) | ✅ | InstitutionTrustList.buildResolver |
| Modal sheet con resultado | ✅ | _AcuseResultSheet |
| Color verde tertiaryContainer si valido AND type=acuse | ✅ | Visual instant |
| Color rojo errorContainer si invalido o no acuse | ✅ | "Acuse invalido" header |
| KV rows: Institucion, Decision, Ticket, En respuesta a (hash mono), Fecha | ✅ | Para auditoria |
| Texto "next_step_text" del acuse en bold | ✅ | "Pase a mesa 4..." si la mesa lo incluye |
| Boton "Listo" cierra | ✅ | Navigator.pop |
| Hallazgos visibles si firma fallo | ✅ | "Hallazgos: signature_mismatch, packet_expired" |

### Modo Ventanilla — top bar institucional

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| AppBar background primaryContainer del theme | ✅ | Color distintivo vs Modo Ciudadano |
| Title con nombre de mesa: "IGSS — Mesa Quetzaltenango" | ✅ | Configurable por `institutionLabel` constructor param |
| Icono swap_horiz volver a Modo Ciudadano | ✅ | Tooltip "Volver a Modo Ciudadano", pop del navigator |
| Onboarding de rol persistente con SharedPreferences | ⏳ | Hoy es por dart-define / push del Citizen al Ventanilla; no hay toggle settings |
| Color de fondo del scaffold dedicado | ⏳ | Hereda del theme, no hay color custom |

### Modo Ventanilla — accion principal

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| FilledButton.icon "Escanear QR del ciudadano" grande | ✅ | Icono qr_code_scanner + label, padding vertical 12, fontSize 16 |
| Push de _ScannerPage con MobileScanner | ✅ | DetectionSpeed.noDuplicates |
| Pop con rawValue del primer barcode | ✅ | Captura sincrona |
| Validacion looksLikeZpk antes de decode | ✅ | SnackBar "Ese QR no es un packet ZPK" si no |
| Decode con QrService (zpk1: + base64url + gzip) | ✅ | FormatException si payload corrupto |
| Verify HMAC-SHA256 contra trust list | ✅ | StaticKeyResolver con 10 keys de demo |
| SetState con received + result | ✅ | Triggea render del ReceivedPacketCard |
| Limpia acuse anterior al recibir nuevo | ✅ | _acuse y _acuseWire = null |
| SnackBar de error si decode falla | ✅ | "No pude leer el packet: $e" |

### Modo Ventanilla — tarjeta del paquete recibido

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Card color tertiaryContainer si firma valida | ✅ | Verde claro |
| Card color errorContainer si firma invalida | ✅ | Rojo claro |
| Header icono verified verde / gpp_bad rojo | ✅ | Visual instant |
| Texto "Firma valida" / "Firma invalida" titleMedium | ✅ | |
| Lista de hallazgos si invalida | ✅ | "Hallazgos: signature_mismatch, unknown_issuer_key, packet_expired" |
| KV rows: Tipo, Caso, Pseudonimo (mono), KeyId (mono), Conocido en trust list (si/no), Hash artifact (mono), Emitido (timestamp), Expira si policy | ✅ | _row helper widget |
| FieldDiffView debajo del KV | ✅ | Panel separado |

### Modo Ventanilla — field diff view

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Card surfaceContainerLow | ✅ | Visual neutral |
| Header "Campos del paquete" titleSmall | ✅ | |
| Subheader "Recibidos (${n})" gris | ✅ | Cuenta dinamica |
| Lista de campos recibidos: icono check_circle verde + key bold + value | ✅ | RichText por entry |
| Divider 24px entre recibidos y omitidos | ✅ | Si hay redacted |
| Subheader "Omitidos por el ciudadano (${n})" gris | ✅ | Solo si redacted no vacio |
| Lista de campos omitidos: icono lock gris + key tachado + label "[REDACTADO]" mono | ✅ | Visual bloqueado |

### Modo Ventanilla — botones de decision

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| FilledButton.icon "Firmar acuse" | ✅ | Disabled si firma invalida |
| Onpressed firma packet acuse con keypair de la mesa | ✅ | _signAcuse |
| Acuse incluye in_response_to (hash del packet del ciudadano) | ✅ | Para audit trail |
| Acuse incluye decision: "atendido" | ✅ | Hardcoded en demo |
| Acuse incluye ticket "TKT-${unix_seconds}" | ✅ | Generado al firmar |
| Acuse incluye next_step_text por defecto | ✅ | "Presentarse en la mesa con identificacion alterna." |
| OutlinedButton.icon "Rechazar" | ✅ | Limpia recibido y agrega entry rechazo al ledger |
| Ambos disabled segun estado | ✅ | Acuse solo si valido, rechazar siempre |

### Modo Ventanilla — tarjeta del acuse generado

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Card secondaryContainer | ✅ | Color distintivo del paquete recibido |
| Titulo "Acuse firmado para el ciudadano" | ✅ | titleMedium |
| Texto "Ticket: ${packet.ticket}" mono | ✅ | Para identificar |
| QR generado con QrImageView size 240 | ✅ | Para que ciudadano escanee |
| Border blanco con radius 12 alrededor del QR | ✅ | Visual claro |
| Texto "Pidale al ciudadano que escanee este QR." | ✅ | bodySmall centrado |

### Modo Ventanilla — ledger institucional

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Header "Atenciones de hoy (${n})" titleSmall | ✅ | Cuenta dinamica |
| Card surfaceContainerLow con lista | ✅ | Solo si _ledger no vacio |
| ListTile dense por entry | ✅ | Compacto |
| Icono check_circle verde si atendido | ✅ | |
| Icono cancel rojo si rechazado | ✅ | |
| Title con ticket en monospace 12px | ✅ | "TKT-1714742460" |
| Subtitle: case_code · pseudonimo | ✅ | Para context |
| Trailing: hora HH:MM | ✅ | Solo timestamp visible |
| Insertion al inicio (ultimo arriba) | ✅ | _ledger.insert(0, entry) |
| In-memory only (no persiste) | ⏳ | Persistencia con SharedPreferences pendiente |

### Trust list pre-bakeada

| Institucion | Key ID | Estado |
|---|---|---|
| Ciudadano demo (firma packets) | `zpk-citizen-demo-key` | ✅ |
| IGSS — Mesa Demo | `igss-mesa-demo-key` | ✅ |
| SAT — Mesa Demo | `sat-mesa-demo-key` | ✅ |
| Ministerio Publico — Mesa Demo | `mp-mesa-demo-key` | ✅ |
| MTPS — Mesa Demo | `mtps-mesa-demo-key` | ✅ |
| PDH — Mesa Demo | `pdh-mesa-demo-key` | ✅ |
| Colegio — Mesa Demo | `colegio-mesa-demo-key` | ✅ |
| PNC — Mesa Demo | `pnc-mesa-demo-key` | ✅ |
| DIACO/PROFECO — Mesa Demo | `profeco-mesa-demo-key` | ✅ |
| RENAP — Mesa Demo | `renap-mesa-demo-key` | ✅ |

### Protocolo ZPK — PacketEnvelope (estructura completa)

**Campos del envelope**

| Campo | Tipo | Estado | Comportamiento |
|---|---|---|---|
| `v` | int | ✅ | Version del envelope, default 1 |
| `type` | enum | ✅ | intake / credential / revocation / acuse, codificado como string code |
| `case` (caseCode) | string | ✅ | Codigo del caso del Lote 1 ("igss_sin_dpi", "extorsion_telefono_sms", etc.) |
| `issued_at` | int (unix sec) | ✅ | Cuando se firmo, segundo precision |
| `issuer` | object | ✅ | Quien firma: {kind, pseudo, key_id, label?} |
| `audience` | object? | ✅ | Para quien va: {institution, mesa?} |
| `fields` | map<string,dynamic> | ✅ | Campos minimos expuestos (titulo, caso, departamento, etc.) |
| `redacted` | array<string> | ✅ | Lista de campos omitidos a proposito (cui, telefono, direccion_completa) |
| `artifact_ref` | object? | ✅ | Hash del artifact al que refiere: {type, hash} |
| `policy` | object? | ✅ | {expires_at?, single_use} |
| `in_response_to` | string? | ✅ | Solo en acuse: hash del packet que se acusa |
| `decision` | string? | ✅ | Solo en acuse: "atendido" / "en_revision" / "rechazado" |
| `ticket` | string? | ✅ | Solo en acuse: ID humano-legible (TKT-${unix}) |
| `next_step_text` | string? | ✅ | Solo en acuse: texto humano "Pase a mesa 4..." |
| `revokes` | string? | ✅ | Solo en revocation: hash del packet a invalidar |
| `reason` | string? | ✅ | Solo en revocation: por que se revoca |
| `sig` | string | ✅ | Firma sobre canonical sin sig |
| `sig_algo` | string | ✅ | "HmacSha256Signature2026" actual; permite migrar a Ed25519 sin breaking |

**Tipos de packet**

| Tipo | Code | Quien firma | Para que sirve | Implementado |
|---|---|---|---|---|
| Intake | "intake" | citizen | Solicitud del ciudadano a institucion | ✅ |
| Credential | "credential" | institution | Credencial emitida por institucion (constancia, recibo) | ✅ tipo definido, UI de emitir pendiente |
| Revocation | "revocation" | citizen | Cancelar packet anterior antes de procesarse | ✅ tipo definido, UI pendiente |
| Acuse | "acuse" | institution | Confirmacion de recepcion con ticket | ✅ |

**Roles del issuer**

| Kind | Code | Notas |
|---|---|---|
| Ciudadano | "citizen" | El que reporta el caso, firma intake/revocation |
| Institucion | "institution" | Mesa/oficina, firma acuse/credential |

### Protocolo ZPK — canonical JSON encoding

**Reglas del encoding**

| Regla | Estado | Comportamiento concreto |
|---|---|---|
| Keys ordenadas alfabeticamente recursivamente | ✅ | `_writeCanonical` walk con sort por nivel |
| Sin espacios entre tokens | ✅ | No usa indent ni padding |
| Strings con jsonEncode estandar (escapes Unicode) | ✅ | Delegado a dart:convert |
| Numbers via jsonEncode (preserva int vs double) | ✅ | Sin coercion |
| null literal | ✅ | "null" sin cuotas |
| Bool literals | ✅ | "true" / "false" |
| Arrays preservados en orden de aparicion | ✅ | NO se ordena dentro de arrays |
| Objetos vacios `{}` | ✅ | Sin keys, sin commas |
| Arrays vacios `[]` | ✅ | Sin elements |
| FormatException si tipo desconocido | ✅ | DateTime/Set explicitamente rechazados |

**Output ejemplo (canonical)**

```json
{"audience":{"institution":"IGSS","mesa":"Quetzaltenango"},"case":"igss_sin_dpi","fields":{"departamento":"Guatemala","edad":67,"necesidad":"atencion presencial sin DPI","nombre_pila":"Ana"},"issued_at":1714742400,"issuer":{"key_id":"zpk-citizen-demo-key","kind":"citizen","pseudo":"zpk:abc123"},"redacted":["cui","direccion_completa","telefono"],"sig_algo":"HmacSha256Signature2026","type":"intake","v":1}
```

### Protocolo ZPK — wire format (PacketCodec)

**Encoding pipeline**

| Paso | Estado | Comportamiento concreto |
|---|---|---|
| Canonical JSON del packet completo (con sig) | ✅ | canonicalJsonEncode(packet.toJson()) |
| UTF-8 encode a bytes | ✅ | utf8.encode |
| Gzip compress (dart:io) | ✅ | gzip.encode |
| Base64Url encode | ✅ | base64Url.encode |
| Strip padding `=` | ✅ | replaceAll('=', '') para shortest URL-safe |
| Prefix `zpk1:` | ✅ | Identificador de version del wire format |

**Decoding pipeline**

| Paso | Estado | Comportamiento concreto |
|---|---|---|
| Verifica prefix `zpk1:` | ✅ | FormatException("Missing zpk1: prefix") si no |
| Pad base64 al multiplo de 4 | ✅ | _padBase64 helper |
| Base64Url decode | ✅ | FormatException("Invalid base64url payload") si invalid |
| Gzip decode | ✅ | FormatException("Invalid gzip payload") si corrupto |
| UTF-8 decode | ✅ | FormatException si bytes invalidos |
| jsonDecode | ✅ | Cualquier excepcion sube |
| Verify map type | ✅ | FormatException("Decoded packet is not a JSON object") |
| PacketEnvelope.fromJson | ✅ | Construye envelope tipado |

**Tamano y tests**

| Metrica | Estado | Valor |
|---|---|---|
| Wire de packet typical | ✅ | <2000 chars (testeado) |
| Sample con 4 fields, audience, artifact_ref, policy | ✅ | ~600-900 chars |
| Roundtrip preserva todos los campos | ✅ | Test verde |
| Canonical estable: mismas keys orden distinto -> mismo output | ✅ | Test verde |
| Canonical recursivo: nested objects ordenan | ✅ | Test verde |
| Hash sha256 del envelope estable | ✅ | Test verde, prefijo "sha256:" |

### Protocolo ZPK — signature verifier

**Algoritmo soportado actualmente**

| Aspecto | Estado | Detalle |
|---|---|---|
| Algoritmo | ✅ | HmacSha256Signature2026 (HMAC-SHA256) |
| Key resolver | ✅ | StaticKeyResolver con map keyId -> secret |
| Canonical para firma | ✅ | toJson() menos campo `sig`, luego canonical encode |
| HMAC sobre canonical bytes | ✅ | Hmac(sha256, utf8.encode(secret)).convert(canonical_bytes) |
| Compare constant-time | ✅ | _constantTimeEquals: XOR todos los bytes, return diff == 0 |

**Findings posibles del verifier**

| Finding | Cuando aparece | Estado |
|---|---|---|
| `unsupported_sig_algo:${algo}` | sig_algo distinto a HmacSha256Signature2026 | ✅ |
| `missing_signature` | sig vacio | ✅ |
| `unknown_issuer_key:${keyId}` | trust list no tiene esa key | ✅ |
| `signature_mismatch` | recompute no matchea sig | ✅ |
| `packet_expired` | policy.expires_at < now | ✅ |

**Estados del VerifyResult**

| Combo | isValid | Notas |
|---|---|---|
| signatureValid=true, algoSupported=true, findings=[] | true | Caso ok |
| signatureValid=false, algoSupported=true, findings con signature_mismatch | false | Caso falla mas comun |
| signatureValid=false, algoSupported=false | false | Algo desconocido |
| Todo true pero packet_expired esta en findings | false | Hardening por expiry |

**Helper estatico signWithSecret**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Recibe packet (sin sig) y secret string | ✅ | Para que el emisor produzca firma |
| Aplica canonicalForSigning | ✅ | Mismo que verify |
| Devuelve hex string | ✅ | sha256.convert.toString() |
| Reproducible para mismo input | ✅ | Test "mismo contenido -> misma firma" |

### Protocolo ZPK — policies y revocacion

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| `policy.expires_at` (unix sec) | ✅ | Verificado en signature_verifier |
| `policy.single_use` boolean default true | ✅ | Marca semantica, ventanilla deberia respetarla |
| Revocation packet definido | ✅ | Tipo "revocation" con campos revokes + reason |
| UI ciudadano para revocar packet enviado | ⏳ | Pendiente; ya hay tipo y firma support |
| UI ventanilla para chequear revocaciones | ⏳ | Pendiente; el funcionario podria escanear revocacion antes de procesar |

### Protocolo ZPK — gaps honestos documentados

| Feature | Estado | Razon |
|---|---|---|
| Ed25519 real en vez de HMAC simetrico | ⏳ | Requeriria pointycastle o similar; HMAC con trust list sirve para demo del hackathon |
| zk-SNARKs reales (probar mayor de edad sin revelar fecha) | ⏳ | Otro proyecto; Halo2/gnark/circom serian las opciones |
| Multi-frame QR para artifacts >2KB | ⏳ | No necesario hoy; payload tipico <1KB |
| Tamper-evident ledger en blockchain | ⏳ | Out of scope; ledger local firmado es suficiente |
| Trust list dinamica desde un registro publico | ⏳ | Out of scope; pre-bakeada para demo |

### Agent loop — orquestador del ReAct

**Funcion runAgentLoop (entrypoint)**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Devuelve Stream<AgentStep> | ✅ | async generator |
| Recibe `input: CitizenInput` | ✅ | rawText + optional photoOcrText/audioTranscript/scenarioHint/metadata |
| Recibe `caseHint: CaseScenario` | ✅ | Default usado por la pantalla: preventive |
| Recibe `reasoner: AgentReasoner` (principal) | ✅ | Inyectable |
| Recibe `tools: ToolRegistry` | ✅ | Compartido entre reasoner y ejecutor |
| `config: AgentLoopConfig` con defaults | ✅ | maxIter, stepDelay, allowReadsPii, fallbackReasoner |
| `preRedactedInput: Map?` opcional | ✅ | Si ya hubo redaccion previa, se reusa |

**AgentLoopConfig — todos los parametros**

| Campo | Default | Comportamiento |
|---|---|---|
| `maxIterations` | 5 (citizen_home overridea a 10) | Tope antes de cierre forzado / ErrorStep |
| `stepDelay` | 180ms | Pausa entre yields para que UI los vea aparecer |
| `allowReadsPii` | false | Bloquea tools con readsPii=true si false |
| `fallbackReasoner` | null | AgentReasoner que toma control si principal falla |

**Steps emitidos en orden**

| # | Step type | Cuando | Detalle |
|---|---|---|---|
| 1 | PlanStep | Siempre primero | "Voy a entender el caso y proteger tus datos personales" |
| 2 | ObservationStep | Despues del plan | "Datos sensibles bloqueados antes de pensar" + data: {fields_in_input} |
| 3..N | ToolCallStep | Cada tool_call decision | tool: nombre, input: map |
| 3..N | ObservationStep | Despues de cada tool | summary del result + data |
| Final | FinalStep | Cuando reasoner devuelve action=final | summary + nextSteps + artifact |
| Cierre por error | ErrorStep | Solo si fallback no aplica | message |

**Manejo de errores y fallback**

| Disparador | Comportamiento del loop |
|---|---|
| Reasoner.decideNextStep tira excepcion | Si fallback configurado: switch + ObservationStep "El razonador principal fallo, sigo con el plan local". Iteration--, mismo turno con fallback. Sino: ErrorStep terminal. |
| Decision.action == 'error' | Mismo trato que excepcion |
| Decision.action == 'final' sin artifactSpec NI lastArtifact | Si fallback: switch + ObservationStep "Cierre prematuro detectado". Sino: ErrorStep "Cierre final sin artifact" |
| Decision.action desconocido | ErrorStep "Decision desconocida: ${action}" |
| Tool throws durante ejecucion | ObservationStep con "Tool ${name} fallo: ${e}" + scratchpad agrega ERROR. Loop sigue. |
| ToolPermissionException (readsPii bloqueada) | Igual al anterior, loop sigue |
| Iteration >= maxIterations | ErrorStep "Limite de N pasos alcanzado". Si lastArtifact != null: emite tambien FinalStep con cierre forzado |

**Scratchpad**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Lista local `scratchpadParts` | ✅ | Se acumula entre iteraciones |
| Cada tool result: `TOOL ${name} -> ${jsonEncode(data)}` | ✅ | Linea por entry |
| Cada tool error: `TOOL ${name} -> ERROR ${e}` | ✅ | Igual formato, marcador especial |
| Pasado al reasoner como `scratchpad` string | ✅ | Joined con \n |
| Null si vacio (primera iteracion) | ✅ | scratchpadParts.isEmpty -> null |
| Preservado al switch a fallback | ✅ | Critico: el determinista solo hace lo que falta |

**Artifact tracking**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| `lastArtifact` variable local | ✅ | Inicializada null, actualizada cada vez que un tool result tiene artifact |
| Heredado al FinalStep si decision.artifactSpec es null | ✅ | Permite que reasoner cierre con "final" minimo y aprovechar lo que tools produjeron |
| Si artifactSpec presente: gana sobre lastArtifact | ✅ | Permite override desde reasoner |
| Si todo null en final: dispara fallback o ErrorStep | ✅ | No deja pasar cierres vacios |

### Agent reasoner contract (`AgentReasoner`)

**Interfaz publica**

| Metodo | Comportamiento |
|---|---|
| `decideNextStep(...)` async | Recibe caseHint, redactedInput, toolsCatalog, scratchpad?, iteration. Devuelve ReasonerDecision. |
| `label` getter | String visible en UI: "Gemma 4 E2B local", "Plan determinista local", etc. |

**ReasonerDecision (factory constructors)**

| Factory | Campos requeridos | Uso |
|---|---|---|
| `.toolCall(tool, input)` | tool: string, input: Map | Pedir ejecutar una tool |
| `.finalResult(summary, nextSteps, artifactSpec?)` | summary, nextSteps; spec opcional | Cerrar el loop |
| `.error(message)` | errorMessage | Reportar fallo recuperable que el loop puede caer al fallback |

**ArtifactSpec (cuando reasoner quiere construir artifact propio)**

| Campo | Tipo | Estado |
|---|---|---|
| `type` | string | ✅ |
| `titulo` | string | ✅ |
| `contenidoMd` | string | ✅ |
| `camposClave` | Map<string,string> | ✅ |
| `toArtifact()` | Convierte a GeneratedArtifact con hash auto | ✅ |

**CitizenInput (input data class)**

| Campo | Tipo | Estado |
|---|---|---|
| `rawText` | string | ✅ |
| `scenarioHint` | CaseScenario? | ✅ |
| `photoOcrText` | string? | ✅ |
| `audioTranscript` | string? | ✅ |
| `metadata` | Map | ✅ |
| `toRedactedMap({redactedText?})` | Convierte a map con keys text/photo_ocr/audio_transcript/scenario_hint | ✅ |

### Tool input repair — desglose por reparacion

**Reparacion 1: passthrough (input ya valido)**

| Caso | Comportamiento |
|---|---|
| `raw is Map<String,dynamic>` | Aplica `_repairChildren` para limpiar nulls + parsear stringified arrays internas |
| `_repairChildren` no cambio nada | RepairOutcome.passthrough(fixed) |
| `_repairChildren` modifico algo | RepairOutcome.repaired con notes ['stripped_nulls_or_unwrapped_substrings'] |

**Reparacion 2: bare-string-wrap**

| Caso | Comportamiento |
|---|---|
| `raw is String` | Busca primary key con `_primaryStringKeyFor(tool)` |
| Tool tiene exactamente UN required string field | wrap como {primary: raw} con notes ['wrapped_bare_string_as_${primary}'] |
| Tool tiene multiples required o ninguno | NO wrappea (no asume) |
| Pero antes de wrap, intenta jsonDecode | Si raw es JSON object stringified, prefiere parsearlo |

**Reparacion 3: stringified-json-parse**

| Caso | Comportamiento |
|---|---|
| `raw is String` y empieza con `{` o `[` | Prueba jsonDecode(raw) |
| Resultado is Map | RepairOutcome.repaired con notes ['parsed_stringified_json_object'] + _repairChildren recursivo |
| Resultado is List o falla parse | Cae al siguiente patron |

**Reparacion 4: singleton-array-unwrap**

| Caso | Comportamiento |
|---|---|
| `raw is List` con length == 1 | Si tool tiene primary key, unwrap a {primary: raw.first} |
| List con multiples elementos | NO unwrap (ambiguo) |
| Notes | ['unwrapped_singleton_array_to_${primary}'] |

**Reparacion 5: null-input**

| Caso | Comportamiento |
|---|---|
| `raw == null` | RepairOutcome.repaired con `{}` (objeto vacio) |
| Notes | ['null_input_replaced_with_empty_object'] |
| Util para tools sin required fields | Permite que el modelo omita el input |

**`_repairChildren` (sub-reparaciones dentro del map)**

| Sub-caso | Comportamiento |
|---|---|
| Value `null` y key NO en `required` | Strip (no se agrega al output) |
| Value `null` y key SI en `required` | Se preserva (el tool fallara por su cuenta con error claro) |
| Value es String pero schema declara `array` | Try jsonDecode; si es List -> usar; si bare string -> `[string]` |
| Value es String pero schema declara `object` | Try jsonDecode; si es Map -> usar; sino -> preserva (tool decidira) |
| Otros valores | Pasan sin tocar |

**Cuando el repair falla**

| Caso | RepairOutcome |
|---|---|
| `raw` es int / double / bool sin contexto | RepairOutcome.unrepairable("unsupported_input_type:int") |
| Outcome.ok == false | El reasoner devuelve null al parser, el agent_loop trata como JSON invalido |
| El adapter Gemma reintenta una vez | Si segundo intento tambien falla -> ReasonerDecision.error -> loop fallback al determinista |

### LiteRtGemmaAgentReasoner — desglose

**Constructor**

| Param | Default | Comportamiento |
|---|---|---|
| `modelPath` | required | Ruta absoluta al .litertlm en device |
| `modelSha256` | "" | Si no vacio, nativo verifica hash antes de cargar |
| `channel` | MethodChannel('gt.kan.kan_app/litert_gemma') | Bridge a MainActivity.kt |
| `timeout` | 90s | Por generate() call |
| `toolRegistry` | null | Para acceso a schemas de tools (repair informado) |
| `repair` | new ToolInputRepair() | Inyectable para testing |
| `onRepair` | null | Callback de telemetria |

**decideNextStep flow**

| Paso | Comportamiento |
|---|---|
| 1. Build prompt | _buildPrompt con caseHint, redactedInput, toolsCatalog compactado, scratchpad truncado, hint del proximo paso |
| 2. Generate | _channel.invokeMapMethod('generate', {modelPath, sha256, prompt}) con timeout |
| 3. Try parse | _tryParse(text) -> ReasonerDecision o null |
| 4. Si null: reintento | Mensaje "tu respuesta anterior fue invalida" + retry |
| 5. Si reintento null: error | ReasonerDecision.error |

**_tryParse (parser tolerante)**

| Paso | Comportamiento |
|---|---|
| Strip markdown fence | Regex ` ```(?:json)?...``` ` extrae contenido |
| Locate JSON object | Busca `{` y `}` outermost |
| jsonDecode | Si falla -> return null |
| Verify is Map | Si no -> return null |
| Verify action field | Solo "tool_call" o "final" valido |
| **Si action == tool_call**: verifica `tool` is String | Si no -> null |
| **Si registry disponible**: aplica repair sobre input | Outcome.ok -> ToolCallStep con outcome.input |
| **Si registry NO disponible**: input strict Map check | Sin registry, sin repair |
| **Si action == final**: verifica summary y nextSteps | Length >= 2 |
| Si artifact field presente y valido | Construye ArtifactSpec |
| Sino | finalResult sin artifactSpec (loop hereda lastArtifact) |
| onRepair callback si registrado | Notifica con (toolName, RepairOutcome) |

**_buildPrompt (estructura del prompt actual)**

```
Eres agente ZPK GT. Decide UN paso. Solo JSON.
Caso: ${caseHint.shortCode}
Texto: ${input text}

Tools:
${tools catalog one-line per tool, truncated 700 chars}

Pasos previos:
${scratchpad truncated 600 chars OR (ninguno)}

REGLA CRITICA: ANTES de usar "final" tenes que haber llamado
draft_denuncia o draft_solicitud (produce el documento) y luego
sign_packet (lo firma). Final sin documento = error.
${hint segun lo que ya se hizo}

Formato (uno):
{"action":"tool_call","tool":"<n>","input":{...}}
{"action":"final","summary":"<s>","next_steps":["a","b","c"]}

Decide:
```

**Hints del proximo paso (segun scratchpad)**

| Estado del scratchpad | Hint emitido |
|---|---|
| No tiene redact_pii | "Sugerencia: el primer paso suele ser redact_pii." |
| Tiene redact_pii pero no classify_case | "Sugerencia: ya redactaste, ahora classify_case." |
| Tiene clasificacion pero no draft_* | "Sugerencia: ya clasificaste y miraste articulos, ahora draft_denuncia o draft_solicitud para producir el documento." |
| Tiene draft_* pero no sign_packet | "Sugerencia: ya tenes el documento, llama sign_packet para firmarlo." |
| Tiene draft_* y sign_packet | "Sugerencia: documento producido y firmado, podes cerrar con \"final\"." |

### LocalDeterministicAgentReasoner — desglose

**Constructor**

| Param | Default | Comportamiento |
|---|---|---|
| `pseudonimo` | "zpk:local-citizen-demo" | Identificador del ciudadano para los artifacts |

**decideNextStep flow (planificador determinista)**

| Paso | Comportamiento |
|---|---|
| Parse scratchpad | `_parseScratchpad` extrae `TOOL ${name} -> ${json}` lineas |
| Si no se hizo redact_pii | toolCall(redact_pii, {text}) |
| Si redact_pii hecho pero no classify_case | toolCall(classify_case, {text}) usando redacted_text |
| Si classify_case hecho | Lookup `_planFor(case_code)` y avanzar al primer step no ejecutado |
| Si todos los steps del plan estan hechos | _finalize con summary + nextSteps (artifact heredado del scratchpad) |
| Caso unknown | Plan default a PDH para orientacion generica |

**_parseScratchpad (extractor)**

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Regex linea por linea: `^TOOL\s+(\S+)\s+->\s+(.*)$` | ✅ | tool name + json result |
| jsonDecode del result | ✅ | Si Map, se guarda |
| Si parse falla, marca con `_error` | ✅ | Para no loopar infinito |
| Devuelve Map<toolName, dynamic> | ✅ | Para que el planner consulte que se hizo |

**_planFor (cadenas por caso)**

| case_code | Plan |
|---|---|
| extorsion_telefono_sms | lookup_codigo_penal(extorsion) → lookup_institucion(MP) → draft_sms_familia → draft_denuncia(MP) → sign_packet |
| estafa_remesa | lookup_codigo_penal(estafa) → lookup_institucion(PROFECO) → draft_sms_familia → draft_denuncia(DIACO) → sign_packet |
| igss_sin_dpi | lookup_institucion(IGSS) → draft_solicitud(IGSS, sin_dpi=true) → sign_packet |
| sat_acceso_bloqueado | lookup_institucion(SAT) → draft_solicitud(SAT) → sign_packet |
| despido_sin_prestaciones | lookup_codigo_trabajo(despido_injustificado) → lookup_institucion(MTPS) → draft_denuncia(MTPS) → sign_packet |
| default (unknown) | lookup_institucion(PDH) → draft_solicitud(PDH) → sign_packet |

### Reasoners disponibles

| Feature | Estado | Notas |
|---|---|---|
| LocalDeterministicAgentReasoner | ✅ | Plan por caso, 5 casos del Lote 1 |
| LiteRtGemmaAgentReasoner (ReAct adapter Gemma) | 🟡 | Probado en Honor; cierra prematuro a veces, fallback lo termina |
| Reasoner viejo `KanReasoner` (one-shot) | 📦 | Vista clasica, sin tocar |
| FallbackReasoner viejo (con timeout) | 📦 | Vista clasica, sin tocar |
| ReasonerFactory selecciona segun KAN_REASONER | ✅ | Wireado a config + dart-defines |

### Tool: `redact_pii`

| Aspecto | Detalle |
|---|---|
| Schema input | `{"type":"object","properties":{"text":{"type":"string"}},"required":["text"]}` |
| Output data | `{redacted_text: string, categories: [string], redacted_count: int}` |
| Categorias detectadas | dpi_cui (13 digitos), telefono (8 digitos), email, direccion |
| Regex DPI | `(?<!\d)\d{13}(?!\d)` |
| Regex telefono | `(?<!\d)\d{8}(?!\d)` |
| Regex email | `[\w.+-]+@[\w-]+\.[\w.-]+` (case insensitive) |
| Regex direccion | `\b(?:zona|calle|avenida|av\.|colonia|barrio|aldea|caserio)\s+[\w\d\s.,-]{3,40}` |
| Reemplazos | `[DPI_REDACTED]`, `[TELEFONO_REDACTED]`, `[EMAIL_REDACTED]`, `[DIRECCION_REDACTED]` |
| Order de reemplazo | DPI → email → direccion → telefono (telefono al final para no comer dpi) |
| Summary | "Sin datos sensibles detectados" o "Bloqueado: ${categories}" |
| readsPii flag | false (es la tool que LIMPIA, no la que lee) |
| producesArtifact flag | false |
| Estado | ✅ |

### Tool: `classify_case`

| Aspecto | Detalle |
|---|---|
| Schema input | `{text: string}` required |
| Output data | `{case_code: string, confidence: float, signals: [string]}` |
| Casos detectados | 5 codes del Lote 1 |
| Patterns extorsion_telefono_sms | extor[sc]ion, amenaz, matar(me\|nos\|los)?, mataba[ns]?, si no (pago\|daba\|doy\|pagaba\|entrego\|paso), me van a hacer (dano\|algo), pidi(e\|o)ndo (plata\|dinero\|pisto), maras?, secuestr |
| Patterns estafa_remesa | (remesa\|western\s*union\|moneygram\|tigo\s*money), paquete (retenido\|detenido), ganaste un premio, falso (envio\|pago\|deposito) |
| Patterns igss_sin_dpi | (igss\|seguro\s*social), (no tengo\|perdi\|me robaron) (mi )?dpi, carne\s*de\s*salud, afiliacion (igss\|patronal) |
| Patterns sat_acceso_bloqueado | sat, nit, agencia\s*virtual, bloqueado.*sat\|sat.*bloqueado |
| Patterns despido_sin_prestaciones | despido, prestaciones, liquidacion, me corrieron, sin pagar |
| Confidence | hits / 3.0 clamp 0..1 (3+ matches = 100%) |
| Signals | Lista de strings matched (max 1 por pattern) |
| Best match | Score mas alto, tie-break primero |
| Si no hay match | `{case_code: "unknown", confidence: 0.0, signals: []}` |
| Summary | "${case_code} (confianza ${pct}%)" o "Sin coincidencia clara" |
| Estado | ✅ patrones extendidos en sesion para frases coloquiales |

### Tool: `lookup_codigo_penal`

| Aspecto | Detalle |
|---|---|
| Schema input | `{category: string enum [extorsion, estafa, amenazas, violencia_intrafamiliar]}` |
| Output | `{found: bool, category, article, codigo, name, penalty, cite}` |
| Tabla extorsion | Art. 261, Codigo Penal Decreto 17-73, Pena 6-12 anos, cita textual |
| Tabla estafa | Art. 263, Estafa Propia, 6 meses-4 anos + multa |
| Tabla amenazas | Art. 215, 6 meses-2 anos |
| Tabla violencia_intrafamiliar | Decreto 97-96 (Ley contra VIF), medidas de seguridad |
| **Aliases** | extorsion_telefono_sms → extorsion, estafa_remesa → estafa, estafa_empleo → estafa, amenazas_directas → amenazas, violencia_domestica → violencia_intrafamiliar |
| Si no encuentra ni alias ni canonical | `{found: false, category: ${raw}}`, summary "Categoria $raw no encontrada en Codigo Penal de Guatemala" |
| Summary OK | "${article} ${name} (Codigo Penal)" |
| Estado | ✅ aliases agregados en sesion |

### Tool: `lookup_codigo_trabajo`

| Aspecto | Detalle |
|---|---|
| Schema input | `{situation: string enum [despido_injustificado, prestaciones_no_pagadas, jornada_excesiva]}` |
| Output | `{found: bool, situation, articles: [string], codigo, name, derecho}` |
| Tabla despido_injustificado | Art. 76, 78, 82, Decreto 1441, Indemnizacion + aguinaldo + bono14 + vacaciones + salarios |
| Tabla prestaciones_no_pagadas | Art. 76, 102, queja Inspeccion General de Trabajo |
| Tabla jornada_excesiva | Art. 116, 121, horas extra al 50% adicional |
| Summary | "${name} (${articles joined})" |
| Estado | ✅ |

### Tool: `lookup_institucion`

| Aspecto | Detalle |
|---|---|
| Schema input | `{code: string enum [MP, PNC, IGSS, SAT, MTPS, PDH, PROFECO, RENAP]}` |
| Output | `{found, code, name, phone, web, intake, horario}` |
| MP | Ministerio Publico, 1572, mp.gob.gt, denuncia presencial o digital, L-V 8-16 |
| PNC | Policia Nacional Civil, 110, pnc.gob.gt, denuncia inmediata, 24/7 |
| IGSS | IGSS, 1522, igssgt.org, atencion sin DPI con identificacion alterna o testigo, L-V 7-15 |
| SAT | SAT, 1550, portal.sat.gob.gt, restablecimiento Agencia Virtual, L-V 8-16:30 |
| MTPS | Ministerio de Trabajo, 1545, mintrabajo.gob.gt, IGT recibe quejas, L-V 8-16:30 |
| PDH | Procuraduria DDHH, 1555, pdh.org.gt, atencion victimas, L-V 8-16 |
| PROFECO/DIACO | DIACO, 1544, diaco.gob.gt, quejas comerciales, L-V 8-16:30 |
| RENAP | RENAP, 1551, renap.gob.gt, reposicion DPI, L-V 8-17 |
| Code uppercase normalization | input.toUpperCase() antes de lookup |
| Si no encuentra | `{found: false, code: ${raw}}`, summary "Institucion no en catalogo" |
| Summary OK | "${name} - tel ${phone}" |
| Estado | ✅ |

### Tool: `draft_denuncia` (produces artifact)

| Aspecto | Detalle |
|---|---|
| Schema input | institucion_destino, caso_codigo, narrativa_redactada (required); articulo_cp, nombre_articulo, pena, pseudonimo, departamento (opcional) |
| Output data | `{artifact_type, titulo, hash, longitud_caracteres}` |
| producesArtifact | true |
| Template del documento | Markdown completo: # DENUNCIA FORMAL + Dirigida a + Lugar/fecha en espanol + Identificador + ## Hechos + (Fundamento legal si articulo) + ## Solicitud + ## Anexos + footer auditoria |
| Fecha en espanol | "${day} de ${mes} de ${year}" via `_mes(int)` |
| Articulo block conditional | Solo aparece si articulo_cp no vacio |
| Hash | sha256:${sha256.convert(utf8.encode(contenido))} |
| Estado | ✅ |

### Tool: `draft_solicitud` (produces artifact)

| Aspecto | Detalle |
|---|---|
| Schema input | institucion, motivo (required); narrativa_redactada, pseudonimo, sin_dpi, departamento (opcional) |
| Output data | `{artifact_type, titulo, hash, longitud_caracteres, sin_dpi}` |
| producesArtifact | true |
| Template del documento | # SOLICITUD FORMAL + Dirigida a + Motivo + Lugar/fecha + Identificador + Detalle + (sin DPI block conditional) + ## Compromisos + ## Anexos |
| sin_dpi block conditional | "## Atencion sin DPI fisico" + parrafo explicativo |
| Hash | sha256 del contenido |
| Estado | ✅ |

### Tool: `draft_sms_familia` (produces artifact)

| Aspecto | Detalle |
|---|---|
| Schema input | `{caso_codigo: string}` required |
| Output data | `{artifact_type, longitud, hash}` |
| producesArtifact | true |
| Plantilla extorsion_telefono_sms | "Familia: estoy bien. Estoy recibiendo una posible extorsion. NO contesten llamadas... NO paguen nada. Estamos preparando denuncia formal..." |
| Plantilla estafa_remesa | "Familia: cuidado con un mensaje sospechoso de remesa o paquete. NO den datos ni transfieran dinero..." |
| Plantilla amenazas_directas | "Familia: estoy bien por ahora. Estamos documentando una amenaza... Si no respondo en 1 hora, llamen al 110." |
| Default si caso desconocido | Cae a plantilla extorsion |
| Limite | <=320 chars (testeado) |
| Hash | sha256 del texto |
| Estado | ✅ |

### Tool: `sign_packet`

| Aspecto | Detalle |
|---|---|
| Schema input | `{contenido: string}` required |
| Output | `{hash, sig, key_id, key_store, algo}` |
| Construido con | IdentitySigner inyectable |
| Hash | sha256 del contenido (utf8 bytes) |
| Sig | identitySigner.signCanonical(contenido) → proofValue |
| key_id | Del signer |
| key_store | Del signer (dart-local-hmac, android-keystore, etc.) |
| algo | proofSuite, default HmacSha256Signature2026 |
| Summary | "Firmado con ${key_id}" |
| Mismo contenido produce misma firma | ✅ deterministico, testeado |
| producesArtifact | false (no genera GeneratedArtifact, solo metadata) |
| Estado | ✅ |

### Casos cubiertos hoy (Lote 1) — paso a paso por caso

**Caso 1: Extorsion telefono / SMS**

| Aspecto | Detalle |
|---|---|
| Inputs ejemplo | "me dijeron que me van a matar si no pago", "amenaza por whatsapp", "vienen las maras" |
| Patrones que matchean | extor[sc]ion, amenaz, matar(me/nos)?, mataba[ns]?, si no (pago/daba/doy/...), me van a hacer (dano/algo), pidiendo (plata/dinero/pisto), maras, secuestr |
| Plan determinista | classify_case → lookup_codigo_penal(extorsion) → lookup_institucion(MP) → draft_sms_familia → draft_denuncia(MP) → sign_packet → final |
| Articulo legal | Art. 261 Codigo Penal Decreto 17-73 (Extorsion, prision 6-12 anos) |
| Institucion target | Ministerio Publico (tel 1572) |
| Artifacts | (1) SMS familia <=320 chars + (2) Denuncia formal markdown para MP citando Art. 261 |
| Hash en artifact | sha256 visible en UI |
| Firma | HMAC-SHA256 del hash con keypair local |
| Next steps emitidos | "Llamar a 1572", "Imprimir o mostrar el QR de la denuncia en la fiscalia", "Enviar SMS a familia por WhatsApp", "No contestar llamadas del numero", "Si hay riesgo inmediato, llamar al 110 (PNC)" |
| Estado | ✅ probado en device |

**Caso 2: Estafa de remesa**

| Aspecto | Detalle |
|---|---|
| Inputs ejemplo | "Western Union dice paquete retenido", "Tigo Money pide codigo", "MoneyGram pide datos por enlace" |
| Patrones | (remesa/western union/moneygram/tigo money), paquete (retenido/detenido), ganaste un premio, falso (envio/pago/deposito) |
| Plan determinista | classify_case → lookup_codigo_penal(estafa) → lookup_institucion(PROFECO) → draft_sms_familia → draft_denuncia(DIACO) → sign_packet → final |
| Articulo legal | Art. 263 Codigo Penal (Estafa Propia, 6 meses-4 anos + multa) |
| Institucion target | DIACO (PROFECO equivalente local, tel 1544) |
| Artifacts | (1) SMS familia + (2) Queja formal para DIACO |
| Next steps | "Llamar a 1544", "No transferir dinero ni dar codigos", "Presentar la queja en oficina DIACO con captura redactada", "Avisar a la remesadora real y al banco" |
| Estado | ✅ probado en device |

**Caso 3: IGSS sin DPI**

| Aspecto | Detalle |
|---|---|
| Inputs ejemplo | "perdi mi DPI y necesito IGSS", "mi mama necesita seguro social y no tiene carne", "afiliacion patronal y dpi extraviado" |
| Patrones | (igss/seguro social), (no tengo/perdi/me robaron) (mi)? dpi, carne de salud, afiliacion (igss/patronal) |
| Plan determinista | classify_case → lookup_institucion(IGSS) → draft_solicitud(IGSS, sin_dpi=true) → sign_packet → final |
| Articulo legal | n/a (es solicitud, no denuncia) |
| Institucion target | IGSS (tel 1522) |
| Artifacts | Solicitud formal IGSS modalidad sin_dpi (incluye seccion explicativa "Atencion sin DPI fisico") |
| Next steps | "Llamar a 1522", "Acudir a IGSS con la solicitud impresa o el QR", "Llevar identificacion alterna y un testigo", "Pedir que se registre la modalidad sin DPI" |
| Estado | ✅ probado en device, casos compatibles con `verify_motorola_physical_flow.sh` |

**Caso 4: SAT acceso bloqueado**

| Aspecto | Detalle |
|---|---|
| Inputs ejemplo | "SAT bloqueo mi acceso", "no puedo entrar a Agencia Virtual con mi NIT", "perdi acceso al portal SAT" |
| Patrones | sat, nit, agencia virtual, bloqueado.*sat / sat.*bloqueado |
| Plan determinista | classify_case → lookup_institucion(SAT) → draft_solicitud(SAT) → sign_packet → final |
| Articulo legal | n/a |
| Institucion target | SAT (tel 1550, portal.sat.gob.gt) |
| Artifacts | Solicitud formal de restablecimiento de Agencia Virtual |
| Next steps | "Llamar a 1550", "Acudir presencialmente con DPI", "No reingresar credenciales SAT desde enlaces de SMS o email" |
| Estado | ✅ probado en device |

**Caso 5: Despido sin prestaciones**

| Aspecto | Detalle |
|---|---|
| Inputs ejemplo | "me corrieron sin pagar prestaciones", "trabaje 3 anos y me corrieron sin nada", "patrono no quiere pagar" |
| Patrones | despido, prestaciones, liquidacion, me corrieron, sin pagar |
| Plan determinista | classify_case → lookup_codigo_trabajo(despido_injustificado) → lookup_institucion(MTPS) → draft_denuncia(MTPS) → sign_packet → final |
| Articulos legales | Art. 76, 78, 82 Codigo de Trabajo Decreto 1441 (Despido injustificado, indemnizacion + aguinaldo + bono14 + vacaciones + salarios) |
| Institucion target | MTPS Ministerio de Trabajo, Inspeccion General de Trabajo (tel 1545) |
| Artifacts | Queja formal con calculo aproximado de prestaciones |
| Next steps | "Llamar a 1545", "Presentar la queja en IGT del MTPS", "Conservar contratos, recibos y mensajes con el patrono", "Calcular prestaciones aproximadas con el documento" |
| Estado | ✅ probado en device |

**Caso fallback (unknown)**

| Aspecto | Detalle |
|---|---|
| Cuando dispara | classifier devuelve case_code=unknown (confidence 0.0) |
| Plan | lookup_institucion(PDH) → draft_solicitud(PDH) → sign_packet → final |
| Institucion | Procuraduria de Derechos Humanos (tel 1555) |
| Artifact | Solicitud de orientacion para PDH |
| Next steps | "Llevar la solicitud a la oficina PDH", "Volver a describir el caso con mas detalle si nada aplica" |
| Estado | ✅ siempre cierra con documento, nunca queda en error |

### Casos pendientes (Lote 2)

| Caso | Estado |
|---|---|
| Migrante retornado (checklist completo post-deportacion) | ⏳ |
| Adulto mayor reporte de tercero | ⏳ |
| Salud / receta medica | ⏳ |
| Circular escolar MINEDUC | ⏳ |
| Estafa de empleo | ⏳ |
| Modo silencio violencia domestica | ⏳ |

### Multimodal — STT (`SttService`)

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Plugin underlying | ✅ | `speech_to_text: ^7.0.0` |
| Constructor con engine inyectable | ✅ | Para tests con mock |
| `ensureInitialized()` | ✅ | Llama `_engine.initialize`, idempotente |
| Locale chain | ✅ | es_GT > es_MX > primer es_* > primer disponible |
| `isListening` getter | ✅ | Pasa al plugin |
| `startListening({onResult})` | ✅ | Listen mode dictation, partial+final results |
| Listen options: partialResults=true | ✅ | UI ve transcript en vivo |
| Listen options: cancelOnError=true | ✅ | Si hay error de mic, para limpio |
| Listen options: listenMode=dictation | ✅ | Mejor para frases largas vs comandos cortos |
| `stopListening()` | ✅ | Para sin emit final |
| `cancel()` | ✅ | Aborta sin guardar |
| Throws SttUnavailable si no init antes | ✅ | Forza ensureInitialized first |

### Multimodal — TTS (`TtsService`)

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Plugin underlying | ✅ | `flutter_tts: ^4.2.0` |
| Constructor con engine inyectable | ✅ | Para tests |
| `_configure()` lazy | ✅ | Idempotente, corre una vez |
| Language chain | ✅ | es-GT (catchError) -> es-MX -> es-ES |
| Speech rate | ✅ | 0.5 (lento, para abuela) |
| Volume | ✅ | 1.0 |
| Pitch | ✅ | 1.0 |
| awaitSpeakCompletion | ✅ | true (no overlap) |
| `speak(text)` | ✅ | Stop antes de speak para no overlap |
| `stop()` | ✅ | Aborta locucion en curso |

### Multimodal — OCR (`OcrService`)

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Plugin underlying | ✅ | `google_mlkit_text_recognition: ^0.13.1` |
| Script | ✅ | TextRecognitionScript.latin (incluye espanol) |
| Constructor con recognizer inyectable | ✅ | Para tests |
| `recognize(File image)` | ✅ | Devuelve OcrResult{text, blocks} |
| Blocks con confidence | 🟡 | Confidence hardcoded a 1.0 (ML Kit no expone) |
| Image NO subida a la nube | ✅ | `processImage(InputImage.fromFile)` ejecuta on-device |
| `dispose()` | ✅ | Cierra el recognizer (libera memoria) |
| OcrResult | ✅ | `{text, blocks: [{text, confidence}]}` |

### Multimodal — QR (`QrService`)

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Static class wrapper a packet_codec | ✅ | Sin estado |
| `encode(envelope)` | ✅ | PacketCodec().encode -> string |
| `decode(wire)` | ✅ | PacketCodec().decode -> envelope |
| `looksLikeZpk(wire)` | ✅ | startsWith("zpk1:") |
| `errorCorrectionLevel` | ✅ | QrErrorCorrectLevel.M (medio, balance entre robustez y tamano) |

### Multimodal — Camera

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Plugin | ✅ | `image_picker: ^1.1.2` (no `camera` para captura simple) |
| Source | ✅ | ImageSource.camera |
| Image quality | ✅ | 70 (compresion para no llenar disco) |
| `camera: ^0.11.0` instalado | ⏳ | Reservado para preview en vivo (futuro: video diary o panic mode) |

### Multimodal — Permission handler

| Feature | Estado | Comportamiento concreto |
|---|---|---|
| Plugin | ✅ | `permission_handler: ^12.0.1` |
| Permisos en AndroidManifest | ✅ | RECORD_AUDIO, CAMERA |
| Hardware features required=false | ✅ | Permite que device sin camara igual instale |
| Request runtime ante user action | 🟡 | Cada plugin lo hace por su cuenta al primer uso |
| Request explicito desde UI | ⏳ | No hay pantalla de "explicar permisos antes de pedir" todavia |

### Plugins instalados (pubspec.yaml) — uso real

| Plugin | Version | Que hace en la app |
|---|---|---|
| cactus | ^1.3.0 | Backend reasoner alternativo (modo `KAN_REASONER=cactus`); sin tocar en sesion |
| crypto | ^3.0.7 | sha256 (en GeneratedArtifact, packet_envelope.hash, sign_packet) y Hmac (en signature_verifier, identity_signer LocalHmac) |
| http | ^1.6.0 | Descarga del modelo Gemma desde URL (KAN_LITERT_MODEL_URL) — opcional |
| flutter_gemma | path ../third_party/flutter_gemma | Reasoner Flutter Gemma 4 alternativo (modo `KAN_REASONER=flutter-gemma4`); sin tocar |
| speech_to_text | ^7.0.0 | SttService wrapper |
| flutter_tts | ^4.2.0 | TtsService wrapper |
| google_mlkit_text_recognition | ^0.13.1 | OcrService wrapper (Latin script) |
| camera | ^0.11.0 | Reservado para preview en vivo, no usado en sesion |
| image_picker | ^1.1.2 | Captura simple desde system camera (citizen_home._capturePhoto) |
| mobile_scanner | ^5.2.3 | Decode de QR en VentanillaHome._ScannerPage y scan_acuse_sheet._AcuseScannerPage |
| qr_flutter | ^4.1.0 | QrImageView en share_packet_sheet y _AcuseCard de ventanilla |
| permission_handler | ^12.0.1 | Forced a ^12 por compatibilidad con cactus; runtime permission requests |
| shared_preferences | ^2.3.2 | Persistencia futura de rol/config (no usado activamente todavia) |
| pointycastle | (transitivo, no top-level) | Disponible si necesitamos Ed25519 en el futuro |
| flutter_test, flutter_lints | dev_dependencies | Test framework + lints |

### Build — dart-defines soportadas

| Define | Default | Que hace |
|---|---|---|
| `KAN_HOME` | classic | classic = HomeScreen viejo, citizen = nueva pantalla |
| `KAN_REASONER` | local | local / cactus / gemma-hosted / mlkit-gemma / litert-gemma / flutter-gemma4 |
| `KAN_CACTUS_MODEL` | functiongemma-270m-pro | Modelo Cactus (sin tocar) |
| `KAN_CACTUS_TIMEOUT_SECONDS` | 45 | Timeout Cactus |
| `KAN_CACTUS_ENABLE_TOOLS` | true | Tools en Cactus |
| `KAN_GEMINI_API_KEY` | "" | Modo cloud Gemini, no usado |
| `KAN_GEMINI_MODEL` | gemma-4-31b-it | Modelo cloud, no usado |
| `KAN_MLKIT_TIMEOUT_SECONDS` | 120 | ML Kit Gemma timeout |
| `KAN_LITERT_MODEL_PATH` | "" | Path absoluto al .litertlm (necesario para litert-gemma) |
| `KAN_LITERT_MODEL_URL` | "" | URL para descargar el modelo (opcional) |
| `KAN_LITERT_MODEL_SHA256` | "" | Hash verificado nativo |
| `KAN_LITERT_TIMEOUT_SECONDS` | 180 | Generate timeout (citizen home pasa 90 al adapter ReAct) |
| `KAN_FLUTTER_GEMMA_MODEL_URL` | "" | Si usa flutter-gemma4 |
| `KAN_FLUTTER_GEMMA_MODEL_ID` | gemma-4-E2B-it.litertlm | Default model id |
| `KAN_FLUTTER_GEMMA_TIMEOUT_SECONDS` | 300 | flutter-gemma timeout |

### Build — gradle config

| Feature | Estado | Detalle |
|---|---|---|
| `applicationId` release | ✅ | gt.kan.kan_app |
| `applicationIdSuffix` debug | ✅ | .citizenpreview (convive con release) |
| `versionNameSuffix` debug | ✅ | -citizenpreview |
| `minSdk` | ✅ | 26 (Android 8.0+, ARM64) |
| `targetSdk` | ✅ | flutter.targetSdkVersion |
| `compileSdk` | ✅ | flutter.compileSdkVersion |
| Java/Kotlin source/target | ✅ | VERSION_17 |
| Native libs declared | ✅ | libvndksupport.so, libOpenCL.so (ambas required=false) |
| Signing config release | ✅ | Lee env vars ZPK_RELEASE_KEYSTORE/STORE_PASSWORD/KEY_ALIAS/KEY_PASSWORD |
| Proguard release | ✅ | proguard-android-optimize + proguard-rules.pro |
| LiteRT-LM dependency | ✅ | com.google.ai.edge.litertlm:litertlm-android:0.10.2 |
| ML Kit GenAI dep | ✅ | com.google.mlkit:genai-prompt:1.0.0-beta1 |
| Coroutines | ✅ | org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2 |

### Build — manifest config

| Feature | Estado | Detalle |
|---|---|---|
| Package | ✅ | gt.kan.kan_app (suffix aplica al ID, no al package del manifest) |
| Application label | ✅ | "ZPK Digital ID" |
| `allowBackup` | ✅ | false (no Android backup automatico) |
| `usesCleartextTraffic` | ✅ | false (HTTPS only) |
| `dataExtractionRules` | ✅ | xml/data_extraction_rules |
| `fullBackupContent` | ✅ | xml/backup_rules |
| `networkSecurityConfig` | ✅ | xml/network_security_config |
| MainActivity exported | ✅ | true |
| MainActivity launchMode | ✅ | singleTop |
| MainActivity hardwareAccelerated | ✅ | true |
| Permisos | ✅ | INTERNET, RECORD_AUDIO, CAMERA |
| Hardware features | ✅ | camera y microphone con required=false |
| ProcessText query | ✅ | Para flutter engine |

### Verificacion — scripts

| Script | Estado | Que verifica |
|---|---|---|
| `flutter analyze` | ✅ | No issues found |
| `flutter test` | ✅ | 138/138 |
| `scripts/verify_submission.sh` | 📦 | APKs firmados release, manifest correcto, hashes, estructura del ZIP, no debug, no features/demo |
| `motorola/verificar-apk.sh` | 📦 | shasum del APK Motorola match |
| `scripts/verify_motorola_physical_flow.sh --no-install` | 📦 | UIAutomator clickea Persona/IGSS/sin CUI/Institucion/Motor y valida textos |
| `scripts/run_physical_litert_proof.sh` | 📦 | Carga modelo en device, pide generacion, verifica `litert_gemma.generate(...) -> ok` |

### Pantalla vieja (Modo avanzado, accesible via drawer)

| Pestana | Sub-feature | Estado |
|---|---|---|
| **Persona** | Seleccion de caso (IGSS, SAT, Colegio, dinero, amenazas, DPI/datos, tramite, campo, proteccion, duda, prevenir) | 📦 |
| Persona | Input de CUI sintetico (13 digitos) | 📦 |
| Persona | Boton "Buscar coincidencias" | 📦 |
| Persona | Resultados de breach catalog local | 📦 |
| **Acciones** | Pasos ejecutables del agente identity protection | 📦 |
| Acciones | Trace de tools del agente (validate_cui, local_breach_lookup, classify_identity_risk, etc.) | 📦 |
| Acciones | Prueba agente local con conteo de herramientas | 📦 |
| **Institucion** | Mesa simulada IGSS / SAT / Colegio | 📦 |
| Institucion | Texto "Atender como intake presencial sin credencial" | 📦 |
| Institucion | Pseudonimo del ciudadano | 📦 |
| Institucion | Hash del paquete | 📦 |
| **Evidencia** | Trust fabric (credencial verificable local) | 📦 |
| Evidencia | DID local (did:zpk:gt:...) | 📦 |
| Evidencia | Selective disclosure claims | 📦 |
| Evidencia | Audit local | 📦 |
| Evidencia | Ledger firmado (agent_execution_ledger) | 📦 |
| **Motor** | Estado runtime LiteRT-LM Gemma 4 | 📦 |
| Motor | Boton "Instalar Gemma offline" (descarga + verify hash + warmup) | 📦 |
| Motor | Boton "Self-test de Gemma" (genera JSON sintetico, parsea con contract) | 📦 |
| Motor | Indicador "DEVICE_LOW_MEMORY" / "AVAILABLE" | 📦 |
| Motor | Indicador "Respaldo offline disponible" | 📦 |
| Motor | Trace de la ultima instalacion / generacion | 📦 |
| **Drawer / nav** | "Continuar sin CUI" en IGSS/SAT/Colegio | 📦 |
| Drawer | Cambio entre modos de razonador | 📦 |

### Dataset y eval (unsloth/)

**Dataset legacy SFT (sabado2context.md)**

| Feature | Estado | Detalle |
|---|---|---|
| Train rows | 📦 | 9840 |
| Validation rows | 📦 | 1080 |
| Test rows | 📦 | 1080 |
| Casos | 📦 | economic_fraud, extortion_evidence, identity_recovery, igss_registration, preventive_wallet, sat_tax_access, school_enrollment |
| Format | 📦 | One-shot JSON con summary/next_steps/national_scale_note/safety_review |
| `generate_guatemala_latam_sft.py` | 📦 | Genera el dataset |
| `evaluate_dataset.py` | 📦 | Valida shape estricto + sin PII + IDs unicos |
| Estado evaluator | 📦 | PASS (sigue valido) |

**Dataset ReAct nuevo (esta sesion)**

| Feature | Estado | Detalle |
|---|---|---|
| Train rows | ✅ | 1640 |
| Validation rows | ✅ | 180 |
| Test rows | ✅ | 180 |
| Casos | ✅ | 5 del Lote 1 (extorsion_telefono_sms, estafa_remesa, igss_sin_dpi, sat_acceso_bloqueado, despido_sin_prestaciones) |
| Format | ✅ | Multi-turn ReAct: system + user + (assistant tool_call + tool observation)*N + assistant final |
| `generate_react_lote1.py` | ✅ | Genera 400 ejemplos por caso, shuffle, 82/9/9 split |
| Per-case builders | ✅ | build_extorsion, build_estafa, build_igss, build_sat, build_despido |
| Tool effect simulators | ✅ | tool_redact_pii, tool_classify_case, tool_lookup_codigo_penal, etc. |
| Variantes triviales por caso | ✅ | Si i excede inputs base, anade " (caso variante N)" |
| Metadata | ✅ | scenario, format=react_v1, contains_real_personal_data=false, lote=1 |

**Eval harness ReAct**

| Metrica | Estado | Definicion | Threshold |
|---|---|---|---|
| `json_validity_rate` | ✅ | % de assistant turns que son JSON parseable | >=0.99 |
| `react_format_rate` | ✅ | % que respetan {action, tool, input} o {action:final, summary, next_steps con 2-6 elementos} | >=0.99 |
| `tool_chain_completeness` | ✅ | % de rows que llegan a un assistant turn con action=final | >=0.99 |
| `pii_leak_rate` | ✅ | % de rows con un patron de 13 digitos en cualquier lado | =0.0 |
| Output reporte | ✅ | unsloth/outputs/react_dataset_quality_report.md |
| Status overall | ✅ | PASS si todas las metricas pasan threshold |
| Resultados actuales (sin training) | ✅ | json=1.0, react=1.0, chain=1.0, leak=0.0 |

**Scripts de training (pendientes de GPU)**

| Script | Estado | Comportamiento concreto |
|---|---|---|
| `train_lora.py` | 🟡 | LoRA r=16, target_modules estandar Gemma, AdamW, cosine schedule. Compila, espera GPU. |
| `train_grpo.py` | 🟡 | GRPO con `zpk_rewards.py`. Compila, espera GPU. |
| `distill_with_gemma4_teacher.py` | 🟡 | Distill desde Gemma 4 27B (teacher) a E2B (student). Compila, espera GPU. |
| `zpk_rewards.py` | 📦 | Define rewards: valid_json (binary), react_format (binary), pii_leak (penalty), tool_chain_completeness (sparse) |

### Lo que NO existe en la app hoy

Para que no haya ambiguedad:
- ❌ Login / cuenta de usuario / email — cero
- ❌ Backend / servidor / cloud — cero
- ❌ Push notifications — cero
- ❌ Analytics / telemetry externos — cero
- ❌ Compras integradas / Pro tier — cero
- ❌ Background services — cero (la app solo corre cuando esta abierta)
- ❌ SMS auto-monitoring — descartado a proposito (creepy + permisos)
- ❌ Integracion API real con IGSS/SAT/RENAP — descartado a proposito
- ❌ Pago / billetera digital — fuera de scope
- ❌ Chat libre abierto — el agente solo razona dentro del catalogo de tools
- ❌ Multi-idioma (ingles, mayan languages) — solo es-GT/es-MX/es-ES, mayan descartado por dificultad

## Fases entregadas

| Fase | Estado | Output |
|---|---|---|
| 1. Cementos agent + zpk | DONE | `services/agent/`, `services/zpk/` + tests |
| 2. Refactor reasoners ReAct | DONE | `LocalDeterministicAgentReasoner` + 9 tools |
| 3. Pantalla ciudadano nueva | DONE | `features/citizen/` + APK debug instalada |
| 4. Multimodal STT + TTS + OCR | DONE | `services/multimodal/` + plugins + permisos |
| 5. Modo Ventanilla | DONE | `features/institution/` + QR scanner + acuse + ledger |
| 6. Protocolo ZPK ciudadano-ventanilla | DONE | share + scan acuse + roundtrip test |
| 7. Dataset SFT ampliado + harness eval | DONE | 2000 rows ReAct + 4 metricas en 1.0/0.0 |
| 8. Empaquetado + verificacion final | DONE | analyze verde, suite verde, verify_submission verde |
| 9. **Gemma 4 ReAct adapter en device** | **DONE** | `LiteRtGemmaAgentReasoner` + repair + fallback, probado en Honor 200 |

## Lo nuevo grande del dia: Gemma 4 manejando el loop ReAct

### Hardware donde corre — y por que importa que sea un Honor 200

Honor 200 (modelo `ELI-NX9`, codename `HNELIX`):
- SoC: Mediatek Dimensity 7200
- RAM: 11.6 GB (vs 6 GB que exige el guard del runtime)
- ABI: arm64-v8a
- OS: Android 16 con Magic OS encima
- Almacenamiento del modelo: `/data/data/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm` (internal app-private)
- SHA-256 modelo: `ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42`
- Tamano: 2,583,085,056 bytes (mismo archivo que el Motorola)

**Por que un Honor y no un Pixel/Samsung flagship:** Honor (spin-off
de Huawei) es una de las marcas chinas mas comunes en pais latinos.
Junto con Xiaomi, Realme, Oppo y la propia Huawei, dominan el segmento
medio en Guatemala, Mexico, Colombia, Peru, Bolivia, Ecuador, Argentina.
El Honor 200 esta en el rango USD 350-450 — es un telefono de gama
media-alta que la gente compra de verdad en LATAM, no un Pixel 9 Pro de
USD 1000+. Que Gemma 4 corra aqui con MagicOS encima (capa propia de
Honor sobre Android, con sus propias particularidades como cifrado
agresivo de logcat y auto-lock) es evidencia mucho mas fuerte para el
jurado que correrlo en hardware Google reference: si funciona en el
device que la familia promedio en Quetzaltenango compra a plazos en
Tigo o Claro, funciona donde tiene que funcionar.

**Tres mercados, un solo binario:**
- **Motorola G15** (USD 150-180, Magic OS-libre, 3.8 GB RAM): segmento
  bajo. Gemma no carga; el plan local determinista corre el mismo loop
  visible. La familia mas vulnerable usa este device y aun asi tiene la
  experiencia agentica completa con artifact firmado.
- **Honor 200** (USD 350-450, MagicOS, 12 GB RAM): segmento medio-alto.
  Gemma carga, decide ReAct, redacta. La gente con un trabajo formal
  estable usa este device y obtiene el agente completo.
- **Pixel/Samsung flagship** (USD 800+): no tenemos uno para probar,
  pero el guard de RAM se desactiva igual y el path es identico.

Que el mismo binario haga lo correcto en los tres tiers (no falsamente
prometer Gemma en device que no aguanta, pero tampoco rendirse en
device que si aguanta) es la promesa de **accesibilidad real**. La app
no asume que tenes flagship; se adapta y siempre cierra con documento.

### Que se probo en vivo

Caso: extorsion. Input: "me dijeron que me van a matar si no pago".

Pasos visibles en pantalla, generados por Gemma 4 E2B en CPU del Honor:

```
🤖 Gemma 4 E2B local
🧠 Voy a entender el caso y proteger tus datos personales
🔒 Datos sensibles bloqueados antes de pensar
🛠️  redact_pii({"text":"me dijeron que me van a matar si no pago"})
✅  Sin datos sensibles detectados
🛠️  classify_case({"text":"me dijeron que me van a matar si no pago"})
✅  extorsion_telefono_sms (confianza 67%)
🛠️  lookup_codigo_penal({"category":"extorsion_telefono_sms"})
✅  Art. 261 Extorsion (Codigo Penal)
... (sigue draft_sms_familia, draft_denuncia, sign_packet, final)
```

Esto es **on-device, offline, generado por Gemma 4 E2B real** — no es plan
B determinista. Cada `tool_call` salio del modelo como JSON ReAct. Las
observaciones fueron resultados reales de las tools locales que Gemma
decidio invocar.

### El adapter ReAct (la pieza que faltaba)

`lib/services/agent/litert_gemma_agent_reasoner.dart` (~150 lineas).
Implementa `AgentReasoner.decideNextStep()`. Por cada turno:

1. Construye prompt compacto con: caso, texto redactado, catalogo
   one-line de tools, scratchpad acumulado truncado, regla critica
   ("antes de final llamar draft_* + sign_packet"), hint del proximo
   paso esperado ("ya redactaste, ahora classify_case").
2. Invoca `MethodChannel('gt.kan.kan_app/litert_gemma').invoke('generate', {modelPath, sha256, prompt})` — el bridge nativo Kotlin que carga LiteRT-LM.
3. Parsea respuesta como ReAct JSON con la **capa de tool input repair**
   (siguiente seccion).
4. Si JSON invalido, reintenta una vez con mensaje "tu respuesta
   anterior fue invalida, recordatorio del formato".
5. Si segundo intento falla, devuelve `ReasonerDecision.error()`. El
   loop cazara ese error y switchea al determinista (siguiente seccion).

## Como hicimos rendir mejor a Gemma 4 sin tocar el modelo

Gemma 4 E2B-it es exactamente el modelo stock de `litert-community`. No
se entreno, no se hizo fine-tuning, no se tocaron pesos. Lo que mejoro
el comportamiento end-to-end fue **el harness alrededor**: como se le
pide al modelo, como se interpreta lo que devuelve, y que pasa cuando
algo sale mal. Estos son los cambios concretos, en orden de impacto:

### 1. Engine config nativo correcto

El bridge Kotlin tenia `maxNumTokens=128, numOfThreads=1`, lo cual hacia
que el engine fallara con `Failed to create engine: INTERNAL` antes de
poder generar nada. Subido a `maxNumTokens=2048, numOfThreads=4`, el
engine inicializa y la generacion corre a 5-15 tokens/seg en CPU.

### 2. Prompt compacto

La primera version del prompt incluia el catalogo de tools como JSON
pretty-printed (~700-1000 tokens) mas reglas largas. El total
sobrepasaba el contexto practico del modelo y disparaba "token too
long". Reescribir a:
- Catalogo de tools en una linea por tool (`- name(keys): description`)
- Reglas reducidas a lo critico
- Scratchpad truncado a 600 chars
- Hint del proximo paso esperado segun lo que ya se hizo

bajo el prompt a ~300-400 tokens, dejando contexto de sobra para la
generacion.

### 3. Capa de tool input repair

Cuando un modelo open-source en device genera tool calls, no siempre
respeta el contrato JSON estricto del tool. Las fallas no son random:
son un set finito y compositivo que se repite entre modelos. En vez
de exigir que el modelo aprenda nuestro contrato exacto, el harness
incluye una capa de reparacion entre el output del modelo y la
ejecucion de la tool.

`lib/services/agent/tool_input_repair.dart` (~95 lineas).

**Filosofia: validate-then-repair**

- Parsear el input como esta. Si encaja con el shape, ship it.
  Inputs validos nunca se tocan.
- Si no encaja, recorrer el `inputSchema` declarado de la tool y
  aplicar la reparacion que el schema indica como necesaria.
- Si despues del repair encaja, log `tool_input_repaired:${tool}` con
  las notas de que se reparo. Si no, log `tool_input_invalid:${tool}`.

La clave: el schema es el prior. Solo se gasta presupuesto de
reparacion en los paths donde el schema realmente se quejo. No se
preprocesa a ciegas, lo cual evita corromper inputs validos cuyo
contenido casualmente parece JSON o array (ej: el contenido de un
`writeFile` que coincidentemente sea JSON-shaped).

**Catalogo de cinco reparaciones**

| Falla observada | Reparacion |
|---|---|
| Bare string donde se esperaba `{key: string}` (ej: `"foo"` en vez de `{"text":"foo"}`) | Wrap como `{primary_key: string}` si la tool tiene exactamente un required string |
| Stringified JSON (ej: `'{"text":"foo"}'` como string) | Try parse, si es objeto valido se usa parseado |
| Singleton array donde se esperaba objeto (ej: `["foo"]`) | Unwrap a `{primary_key: foo}` |
| `null` en campo opcional | Strip del map (no se incluye) |
| Stringified array donde se esperaba `array` field (ej: `'["a","b"]'`) | Try parse a array; bare string -> `[string]` |

**Ampliacion del dominio aceptado por las tools**

Independiente del repair de shape: las tools toleran sinonimos
razonables en sus enums. `lookup_codigo_penal` declara
`category in [extorsion, estafa, amenazas, violencia_intrafamiliar]`,
pero el modelo a veces pasa el `case_code` completo
(`extorsion_telefono_sms`). Una tabla de aliases en el tool resuelve
a la categoria canonica antes del lookup. Esto no es repair de input
shape; es contrato mas forgiving en el lado de la tool.

**Telemetria per-tool**

`LiteRtGemmaAgentReasoner.onRepair: (toolName, outcome) -> void`
opcional. Recibe el nombre de la tool y el `RepairOutcome` (kind:
passthrough/repaired/unrepairable, notes:
`['wrapped_bare_string_as_text']`). Sirve para:
- Detectar regresiones por modelo: si se sube de Gemma 4 E2B a E4B y
  el `repair_rate` por tool sube, hay que investigar antes que los
  usuarios noten.
- Anunciar al usuario y al propio modelo: el `ObservationStep` puede
  mostrar "input reparado: bare-string -> objeto" para que en el
  siguiente turno el modelo lo vea y se autocorrija.

### 4. Loop-level fallback (el nivel arriba del input repair)

Algunas fallas no se reparan a nivel input:
- El modelo decide cerrar con `final` antes de haber producido el
  documento (no llamo a `draft_denuncia` ni `draft_solicitud`).
- El modelo se cuelga, tira excepcion, o produce JSON irreparable dos
  veces seguidas.
- LiteRT-LM nativo falla mid-generacion por algun problema del engine.

Para estos casos, `agent_loop` tiene un parametro `fallbackReasoner`.
Si algo de lo de arriba pasa:

1. El loop **no emite ErrorStep terminal**. En cambio, switchea a
   `LocalDeterministicAgentReasoner`.
2. **Preserva el scratchpad acumulado**. El determinista no empieza
   de cero: mira los pasos hechos (`redact_pii`, `classify_case`,
   `lookup_codigo_penal`, etc.) y solo ejecuta lo que falta
   (`draft_denuncia`, `sign_packet`).
3. **Anuncia el switch en la UI** como ObservationStep: "Cierre
   prematuro detectado. Sigo con plan local para producir el
   documento." No hay magia silenciosa; el usuario lo ve.
4. Termina con `FinalStep` con artifact firmado, igual que si el
   modelo hubiera hecho todo el camino.

Resultado: un agente **hibrido**. El modelo decide cuando puede, el
plan local garantiza que el documento siempre sale. El usuario nunca
ve un error final si el caso es soportado.

### 5. Patterns de clasificador mas permisivos

Cuando la primera tool del loop es `classify_case`, si el clasificador
no encuentra match con los patrones, el modelo se queda llamandolo en
loop tratando de obtener otra respuesta. Patrones extendidos para
absorber variantes coloquiales ("mataban", "no daba", "secuestrar",
"amenazaron") evitan ese loop sin necesidad de que el modelo invente
soluciones.

### Resumen

El modelo no cambio. El contrato a su alrededor se hizo mas forgiving
en exactamente los puntos donde el modelo necesita ayuda:
- Engine que arranca con buena config
- Prompt que cabe en su contexto
- Repair de shapes finitos en su output
- Aliases enum donde el dominio es razonable ampliarlo
- Fallback determinista que termina si el modelo se queda corto

La leccion: lo que parece "modelo open-source malo en tool calling"
suele ser harness fragil. Cinco repairs cortos, un fallback, una
config nativa correcta y un prompt compacto convierten un modelo que
fallaba en uno que cierra el loop end-to-end con artifact firmado.

## Estructura de codigo (lo nuevo de hoy resaltado)

```
kan-app/lib/
  main.dart                                  (KAN_HOME=citizen + KAN_REASONER=litert-gemma + registry compartido)
  models/
    generated_artifact.dart                  (NUEVO: documento + hash + firma)
  services/
    agent/                                   (NUEVO: cementos del loop)
      agent_step.dart                        (PlanStep|ToolCallStep|ObservationStep|FinalStep|ErrorStep)
      agent_tool.dart                        (contrato AgentTool)
      tool_registry.dart                     (registro + describeAllForPrompt + describeAllCompact)
      agent_reasoner.dart                    (contrato AgentReasoner.decideNextStep)
      agent_loop.dart                        (orquestador Stream<AgentStep> + fallback switch)
      local_deterministic_agent_reasoner.dart(planificador por caso)
      ★ litert_gemma_agent_reasoner.dart    (NUEVO HOY: adapter ReAct para Gemma 4)
      ★ tool_input_repair.dart              (NUEVO HOY: validate-then-repair)
      ★ default_tool_registry.dart          (NUEVO HOY: helper compartido)
      tools/
        redact_pii_tool.dart                 (DPI/telefono/email/direccion)
        classify_case_tool.dart              (5 casos del Lote 1, patterns mejorados hoy)
        lookup_codigo_penal_tool.dart        (Art. 261, 263, 215, decreto 97-96 + aliases case_code)
        lookup_codigo_trabajo_tool.dart      (Art. 76/78/82, 102, 116/121)
        lookup_institucion_tool.dart         (MP, PNC, IGSS, SAT, MTPS, PDH, PROFECO, RENAP)
        draft_denuncia_tool.dart             (denuncia formal con cita Codigo Penal)
        draft_solicitud_tool.dart            (solicitud institucional con sin_dpi opcional)
        draft_sms_familia_tool.dart          (<=320 chars para WhatsApp/SMS)
        sign_packet_tool.dart                (HMAC-SHA256 via IdentitySigner)
    zpk/                                     (protocolo ciudadano-institucion)
      packet_envelope.dart                   (canonical JSON + tipos intake/credential/revocation/acuse)
      packet_codec.dart                      (zpk1: + base64url + gzip; <2KB tipico)
      signature_verifier.dart                (HmacSha256Signature2026)
      institution_trust_list.dart            (10 keys de demo)
    multimodal/                              (capa I/O on-device)
      stt_service.dart                       (speech_to_text es-GT/es-MX)
      tts_service.dart                       (flutter_tts)
      ocr_service.dart                       (Google ML Kit Latin script)
      qr_service.dart                        (envelope -> wire <-> envelope)
  features/
    citizen/                                 (pantalla ciudadano)
      citizen_home.dart                      (mic + camara + teclado + AppBar 4 botones + fallback wired)
      widgets/agent_stream_panel.dart
      widgets/artifact_card.dart             (con TTS, copy, QR firmado, share)
      widgets/privacy_diff_card.dart
    institution/
      ventanilla_home.dart                   (scanner + verify + acuse + ledger)
      widgets/received_packet_card.dart
      widgets/field_diff_view.dart
    zpk/
      share_packet_sheet.dart                (genera QR firmado del ciudadano)
      scan_acuse_sheet.dart                  (verifica acuse de la ventanilla)

kan-app/android/app/src/main/kotlin/.../MainActivity.kt
  ★ EngineConfig modificado: maxNumTokens 128 -> 2048, threads 1 -> 4
```

## Casos de uso listos en device (Lote 1)

Cada caso = clasificacion automatica + cadena de tools + artifact firmado.

### 1. Extorsion telefono / SMS

- **Input ejemplo**: "me dijeron que me van a matar si no pago", "alguien me amenaza por whatsapp", "vienen las maras"
- **Cadena**: redact_pii -> classify_case -> lookup_codigo_penal(extorsion) -> lookup_institucion(MP) -> draft_sms_familia -> draft_denuncia -> sign_packet -> final
- **Artifacts**: SMS para familia ("no contesten, no paguen") + denuncia formal para Ministerio Publico citando Art. 261 Codigo Penal (pena 6-12 anos)
- **Next steps sugeridos**: llamar 1572 (MP), llamar 110 (PNC) si hay riesgo inmediato, mostrar QR en fiscalia, enviar SMS a familia

### 2. Estafa de remesa

- **Input ejemplo**: "me llego mensaje de Western Union sobre paquete retenido", "Tigo Money me dice que gane premio si transfiero codigo", "MoneyGram pide datos por enlace"
- **Cadena**: redact_pii -> classify_case -> lookup_codigo_penal(estafa) -> lookup_institucion(PROFECO) -> draft_sms_familia -> draft_denuncia -> sign_packet -> final
- **Artifacts**: SMS para familia ("no transfieran, verifiquen") + queja formal para DIACO citando Art. 263 Codigo Penal (estafa propia)
- **Next steps**: no transferir, no dar codigos, presentar queja en oficina DIACO con la captura redactada, avisar a la remesadora real

### 3. IGSS sin DPI

- **Input ejemplo**: "perdi mi DPI y necesito atencion en IGSS", "mi mama necesita seguro social y no tiene su carne"
- **Cadena**: redact_pii -> classify_case -> lookup_institucion(IGSS) -> draft_solicitud(sin_dpi=true) -> sign_packet -> final
- **Artifact**: solicitud formal para IGSS pidiendo atencion presencial bajo modalidad de intake institucional sin credencial
- **Next steps**: llamar 1522, llevar identificacion alterna y un testigo, pedir que se registre la modalidad sin DPI en el expediente

### 4. SAT acceso bloqueado

- **Input ejemplo**: "me bloqueo SAT y no puedo entrar a Agencia Virtual", "perdi acceso a portal SAT y no puedo facturar"
- **Cadena**: redact_pii -> classify_case -> lookup_institucion(SAT) -> draft_solicitud -> sign_packet -> final
- **Artifact**: solicitud formal para SAT pidiendo restablecimiento del acceso a Agencia Virtual
- **Next steps**: acudir presencialmente con DPI, no reingresar credenciales SAT desde enlaces de SMS/email

### 5. Despido sin prestaciones

- **Input ejemplo**: "me corrieron sin pagar prestaciones", "trabaje 3 anos y me corrieron sin nada"
- **Cadena**: redact_pii -> classify_case -> lookup_codigo_trabajo(despido_injustificado) -> lookup_institucion(MTPS) -> draft_denuncia -> sign_packet -> final
- **Artifact**: queja formal para Ministerio de Trabajo (Inspeccion General de Trabajo) citando Art. 76, 78, 82 del Codigo de Trabajo de Guatemala
- **Next steps**: presentar la queja en MTPS, conservar contratos/recibos/mensajes, calcular prestaciones aproximadas

### Fallback comun: PDH

Si el clasificador no encuentra match con confianza, el plan default
genera una solicitud generica para PDH (Procuraduria de los Derechos
Humanos) pidiendo orientacion presencial. Nunca se queda sin
producir documento.

## Tests y calidad al cierre

```
cd kan-app
flutter analyze            -> No issues found
flutter test               -> 138 tests passed (74 viejos + 64 nuevos)
```

Tests nuevos del dia:
- `agent_loop_test.dart` (6) — flujo, max iterations, fallback en error, bloqueo readsPii
- `agent_tools_test.dart` (16) — cada tool en aislamiento
- `local_deterministic_agent_reasoner_test.dart` (8) — los 5 casos end-to-end + sin PII
- `zpk_packet_codec_test.dart` (7) — roundtrip + canonical stable + <2KB
- `zpk_signature_verifier_test.dart` (7) — firma valida/invalida/expirada
- `zpk_roundtrip_test.dart` (3) — ciudadano firma -> wire -> ventanilla verifica
- `citizen_home_widget_test.dart` (3) — render + agente + mic/camara
- ★ `tool_input_repair_test.dart` (8) — passthrough, bare-string-wrap, stringified-json-parse, singleton-array-unwrap, null-strip, unrepairable

## Plugins agregados a pubspec.yaml

```yaml
speech_to_text: ^7.0.0
flutter_tts: ^4.2.0
google_mlkit_text_recognition: ^0.13.1
camera: ^0.11.0
image_picker: ^1.1.2
mobile_scanner: ^5.2.3
qr_flutter: ^4.1.0
permission_handler: ^12.0.1
shared_preferences: ^2.3.2
```

`permission_handler` quedo en `^12.0.1` por compatibilidad con `cactus ^1.3.0`.

Permisos en AndroidManifest:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="false"/>
<uses-feature android:name="android.hardware.microphone" android:required="false"/>
```

## Build y APKs

### APK release vigente (la que cuenta para submission)

```text
motorola/zpk-litert-persona-institucion-release.apk
sha256: d3ab26a09c79a454b68be344df43bd6c58ba95f8aec73a8bd34f547588167e09
package: gt.kan.kan_app
home: HomeScreen viejo (5 pestanas)
```

`verify_submission.sh` PASS, `verify_motorola_physical_flow.sh` PASS.

### APK debug "citizen preview" (la pantalla nueva, paralela)

```bash
cd kan-app
flutter build apk --debug \
  --dart-define=KAN_HOME=citizen \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH=/data/data/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

```text
package: gt.kan.kan_app.citizenpreview     (suffix puesto en build.gradle.kts)
home: CitizenHome con loop ReAct + fallback determinista cableado
```

El `applicationIdSuffix = ".citizenpreview"` permite que la APK debug
conviva con la release sin chocar de firma ni borrar el modelo Gemma.

## Cambios en el bridge nativo Kotlin

`android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
val engineConfig = EngineConfig(
    modelPath = modelFile.absolutePath,
    backend = Backend.CPU(numOfThreads = 4),    // antes: 1
    maxNumTokens = 2048,                         // antes: 128
    cacheDir = File(cacheDir, "litert-lm").absolutePath,
)
```

El `maxNumTokens=128` original era demasiado bajo: el prompt ReAct con
catalogo de tools facilmente excede 128 tokens, y el engine falla con
`Failed to create engine: INTERNAL` antes de empezar.

`numOfThreads=1` era seguro pero lento. Subido a 4, la generacion de
Gemma 4 E2B en Mediatek Dimensity 7200 anda ~5-15 tokens/seg (suficiente
para que un loop ReAct de 6 pasos termine en 2-4 minutos).

## Dataset y eval

```text
unsloth/data/react/
  zpk_react_lote1_train.jsonl          (1640 rows)
  zpk_react_lote1_validation.jsonl     (180 rows)
  zpk_react_lote1_test.jsonl           (180 rows)
```

Total: 2000 ejemplos en formato ReAct. Cada ejemplo es una conversacion
multi-turn: system + user + (assistant tool_call + tool observation)*N +
assistant final. Esto le ensena a Gemma el formato del loop, no solo
respuestas one-shot.

Casos cubiertos: extorsion_telefono_sms, estafa_remesa, igss_sin_dpi,
sat_acceso_bloqueado, despido_sin_prestaciones (400 cada uno).

Comandos:
```bash
cd unsloth
uv run python generate_react_lote1.py            # regenera dataset
uv run python evaluate_react_dataset.py          # mide 4 metricas
```

Reporte: `unsloth/outputs/react_dataset_quality_report.md`

Metricas (PASS):
- json_validity_rate: 1.0
- react_format_rate: 1.0
- tool_chain_completeness: 1.0
- pii_leak_rate: 0.0

**Sin training real todavia.** `train_lora.py` y
`distill_with_gemma4_teacher.py` estan listos para correr en GPU.

## Estado real de Gemma 4 (actualizado 2026-05-03 noche)

### Lo que es verdad ahora

- Gemma 4 E2B-it.litertlm (2.5 GB) instalado y verificado por hash en
  `/data/data/gt.kan.kan_app.citizenpreview/files/models/` del Honor 200.
- Modelo cargado y compilado correctamente por LiteRT-LM con
  `Backend.CPU(numOfThreads=4), maxNumTokens=2048`.
- E2B es la variante mas chica de la familia Gemma 4 instruct-tuned
  publicada (Effective 2B con Per-Layer Embeddings).
- En el Honor 200 (Mediatek Dimensity 7200, 12 GB RAM, MagicOS):
  **Gemma genera ReAct JSON valido en CPU**, decide tool calls, ve
  observaciones, itera. Probado en vivo con caso extorsion.
- En el Motorola G15 (3.8 GB RAM): el guard correctamente bloquea
  carga del modelo y delega al determinista. El mismo loop visible
  corre con el plan local. La UI no distingue.
- El adapter `LiteRtGemmaAgentReasoner` esta cableado, parsea ReAct
  JSON con tolerancia (capa de repair), y el agent_loop tiene safety
  net (fallback a determinista).

### Lo que sigue NO siendo verdad

- El loop end-to-end con Gemma manejando los 6 pasos completos hasta
  artifact firmado **fue probado parcialmente**: Gemma llega a
  `lookup_codigo_penal` y a veces cierra prematuro; en esos casos el
  fallback determinista termina el documento. El demo siempre cierra
  con artifact, pero la "carrera 100% Gemma" todavia depende de
  cuanto cumpla el modelo el prompt sin caer en fallos compositivos.
- NO hay LoRA entrenado todavia (dataset ReAct esta listo, training
  pendiente de GPU).
- NO hay zk-SNARKs reales — solo HMAC-SHA256 + hash + paquete
  redactado.
- NO hay integracion real con IGSS/SAT/RENAP/gobierno.
- NO hay PII real ni datos de brechas reales.

### Que falta para "100% Gemma sin fallback"

Es deseable mostrar a un jurado que el loop entero corre solo con
Gemma sin caer al determinista. Para eso:

1. Mejorar el prompt para que la regla "draft_* + sign_packet antes de
   final" sea respetada. Hoy se respeta a veces, no siempre.
2. Entrenar el LoRA con `unsloth/data/react/` para que el modelo
   aprenda el formato ReAct exacto y deje de cerrar prematuro. Esto
   requiere GPU.
3. Aumentar `maxNumTokens` mas (a 4096 o 8192) si el contexto crece.
4. Agregar mas patterns al `tool_input_repair` segun fallos nuevos
   que aparezcan en logs (cada modelo tiene su distribucion).

## Comandos de bolsillo

### Desarrollo
```bash
cd kan-app
flutter analyze
flutter test                 # 138 verdes
```

### Build APK
```bash
# Citizen preview con Gemma activo
flutter build apk --debug \
  --dart-define=KAN_HOME=citizen \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH=/data/data/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

### Honor 200 (cable USB, USB debugging activo)
```bash
adb devices                                                  # ELI-NX9
adb install -r kan-app/build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n gt.kan.kan_app.citizenpreview/gt.kan.kan_app.MainActivity

# Pasar el modelo a internal app-private (una vez por instalacion):
adb push gemma-4-E2B-it.litertlm /data/local/tmp/gemma.litertlm
adb shell "run-as gt.kan.kan_app.citizenpreview sh -c 'mkdir -p files/models && cat /data/local/tmp/gemma.litertlm > files/models/gemma-4-E2B-it.litertlm'"
adb shell rm /data/local/tmp/gemma.litertlm

# Screenshot:
adb shell screencap -p /sdcard/x.png && adb pull /sdcard/x.png /tmp/x.png

# UI dump (cuando screencap esta bloqueado por proceso CPU-bound):
adb shell uiautomator dump /sdcard/ui.xml && adb pull /sdcard/ui.xml /tmp/ui.xml
```

### Motorola G15 (release oficial, lo que verifica UIAutomator)
```bash
adb install -r motorola/zpk-litert-persona-institucion-release.apk
./scripts/verify_motorola_physical_flow.sh --no-install
```

### Verificacion submission
```bash
./scripts/verify_submission.sh                  # PASS
./motorola/verificar-apk.sh                     # OK
```

### Dataset
```bash
cd unsloth
uv run python generate_react_lote1.py
uv run python evaluate_react_dataset.py
uv run python evaluate_dataset.py               # legacy, sigue PASS
```

## Modo demo para el jurado (90 segundos)

Asumiendo APK debug citizenpreview instalada en Honor 200:

```
[0-10s]  Abrir app, ver "Que te paso?" + AppBar con avion/qr/ventanilla/avanzado.
[10-15s] Tap mic (o teclado), decir/escribir "me amenazan por whatsapp si no pago".
[15-90s] "Ayudame ahora" -> panel agente se anima en vivo:
         "Gemma 4 E2B local"  <- el badge demuestra que el modelo es el que decide
         redact_pii -> sin datos sensibles
         classify_case -> extorsion_telefono_sms (67%)
         lookup_codigo_penal -> Art. 261 Extorsion
         lookup_institucion -> MP - tel 1572
         draft_sms_familia
         draft_denuncia
         sign_packet
         FINAL: ArtifactCard con denuncia formal markdown completa,
                hash sha256, fecha actual, pseudonimo local.
[opt]    Tap "Escuchar" -> TTS lee la denuncia en es-GT.
         Tap "QR firmado" -> aparece QR.
         Tap el icono maletin (ventanilla) -> "IGSS - Mesa Quetzaltenango".
         Escanear QR -> firma valida + field diff.
         Firmar acuse -> QR de acuse al ciudadano.
         Volver a ciudadano, escanear acuse -> "Acuse valido" con ticket.
```

Mensaje al jurado (honesto):
> "Gemma 4 E2B esta corriendo en este Honor 200 — un telefono chino de
> gama media-alta que la gente compra de verdad en Guatemala, no un
> Pixel reference. CPU, sin red. Detecta extorsion, busca el articulo
> del Codigo Penal, redacta la denuncia, la firma localmente. Si Gemma
> se equivoca, un planificador deterministico local termina el trabajo
> preservando lo hecho — el ciudadano nunca ve un error final. La
> ventanilla verifica la firma en su propio telefono, sin contactar
> nada externo. Cero red en todo el demo. Y el mismo binario corre en
> un Motorola G15 de USD 180 con plan local cuando Gemma no aguanta;
> nadie queda fuera por no tener flagship."

## Riesgos y limites honestos

| Limite | Mitigacion actual |
|---|---|
| Gemma cierra prematuro a veces | Loop-level fallback al determinista, preserva scratchpad |
| Gemma manda input shape inesperado | Capa de repair con 5 reparaciones automaticas + aliases enum |
| LiteRT-LM falla en algunos SoCs | Probado verde en Mediatek Dimensity 7200; el guard cuida que solo cargue donde puede |
| Generacion lenta en CPU (5-15 t/s) | Se anuncia "Pensando..." y el badge dice cual modelo corre, asi el jurado no asume bug |
| Honor con auto-lock agresivo bloquea screencap | Para demo: subir Sleep timeout a 30 min en Settings |
| HMAC simetrico, no Ed25519, no SNARKs | Documentado; ZPK-style esta bien para hackathon, no produccion |

## Que NO toques sin pensar

- `motorola/zpk-litert-persona-institucion-release.apk` y la
  submission empaquetada en `submission/dist/` son la entrega ya
  verificada.
- `verify_motorola_physical_flow.sh` busca textos especificos de la
  UI vieja. Si rediseñas la pantalla "classic" rompes el verificador.
- El dataset legacy (`unsloth/data/zpk_gt_latam_sft_*.jsonl`) y su
  evaluator estricto siguen siendo la baseline de sabado2context.md.
- El `applicationIdSuffix=".citizenpreview"` en `build.gradle.kts`
  protege la convivencia release/debug. Borrarlo va a borrar el
  modelo del Honor al instalar.

## Siguientes sesiones recomendadas

Por orden de impacto-por-trabajo:

1. **Entrenar el LoRA** en tu Ubuntu+GPU con `unsloth/data/react/`.
   Comando ya listo:
   ```bash
   uv run python train_lora.py --base gemma-4-E2B \
     --dataset data/react/ --out adapters/zpk-gt-react-v1
   ```
   Esto deberia eliminar los cierres prematuros de Gemma porque el
   modelo aprende el formato exacto del loop.

2. **Lote 2 de casos**: migrante retornado, adulto mayor, salud receta,
   circular escolar, estafa empleo, modo silencio violencia.

3. **Surface repair notes al modelo en el prompt siguiente**: el
   `onRepair` callback ya emite las notas; falta meterlas en el
   ObservationStep correspondiente para que Gemma las vea en su
   proximo turno y se autocorrija.

4. **Modo abuela** (texto 1.5x, narracion automatica, un verbo a la
   vez).

5. **Submission rebuild** con `KAN_HOME=citizen` por default, despues
   de iterar Gemma en device.

## Estado al cierre

- ADB activo (Honor 200 conectado por USB).
- APK debug `gt.kan.kan_app.citizenpreview` instalada en Honor con
  Gemma 4 E2B + repair + fallback.
- APK release `gt.kan.kan_app` sigue instalada en Motorola; UIAutomator
  pasa contra ella.
- 138 tests verde, analyze limpio, verify_submission verde.
- Cero procesos pesados (Xcode, simulator, qemu) corriendo en la Mac.
