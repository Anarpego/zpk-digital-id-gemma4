# Contexto actual ZPK Digital ID + Gemma 4

Actualizado: 2026-05-07, America/Guatemala.
Repo: `/Users/anibalperez/Code/AI/kaggle`.
App activa: `kan-app/`.

Este archivo es el handoff para una sesion futura. No asumir que todo esta
committeado: el working tree esta sucio con cambios grandes despues del commit
`772b83b feat: harden offline Gemma identity app`.

## Objetivo del proyecto

Ganar el Gemma 4 Good Hackathon con una app real de identidad digital y ayuda
institucional para Guatemala. La historia tecnica debe ser:

- Gemma 4 corre local/offline en el telefono cuando el hardware lo permite.
- El agente no es chatbot: decide pasos ReAct y llama herramientas locales.
- La persona recibe documentos accionables: denuncia, solicitud, SMS familiar,
  QR firmado.
- La institucion tiene un modo ventanilla para verificar paquetes firmados y
  devolver acuse.
- PII no sale del dispositivo; la app muestra lo bloqueado antes de razonar.

No enviar ni verificar submission de Kaggle desde la herramienta de desarrollo. El usuario lo hara
manualmente.

## Estado real al 2026-05-07

### Verificado hoy en Honor fisico

Dispositivo conectado por USB:

```text
serial: AJ4UVB4C25000283
model: ELI-NX9
device: HNELIX
abi: arm64-v8a
ram: MemTotal 11602968 kB (~11.6 GB)
```

Paquete instalado y corriendo:

```text
package: gt.kan.kan_app.citizenpreview
apk: kan-app/build/app/outputs/flutter-apk/app-debug.apk
apk sha256: 5a6d15c75a6615c6f740ba1200126858e6f2b57afbb5795bc9a227b251857a5c
versionName: 1.0.0-citizenpreview
debuggable: true
lastUpdateTime: 2026-05-07 11:33:35
```

La app arranca en `CitizenHome` con:

```text
KAN_HOME=citizen
KAN_REASONER=litert-gemma
KAN_LITERT_MODEL_PATH=/data/data/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm
KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
KAN_LITERT_TIMEOUT_SECONDS=240
```

Permisos concedidos por ADB para preparar pruebas fisicas:

```bash
adb shell pm grant gt.kan.kan_app.citizenpreview android.permission.CAMERA
adb shell pm grant gt.kan.kan_app.citizenpreview android.permission.RECORD_AUDIO
```

### Modelo Gemma 4 instalado

El modelo esta dentro del sandbox privado de la app debug:

```text
/data/user/0/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm
size: 2583085056 bytes (~2.4 GB)
sidecar sha256 file: gemma-4-E2B-it.litertlm.sha256
sha256: ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

Comandos para reinstalar el modelo si se borra la app:

```bash
adb push gemma-4-E2B-it.litertlm /data/local/tmp/gemma.litertlm
adb shell "run-as gt.kan.kan_app.citizenpreview sh -c 'mkdir -p files/models && cat /data/local/tmp/gemma.litertlm > files/models/gemma-4-E2B-it.litertlm'"
adb shell "run-as gt.kan.kan_app.citizenpreview sh -c 'printf ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42 > files/models/gemma-4-E2B-it.litertlm.sha256'"
adb shell rm /data/local/tmp/gemma.litertlm
```

El modelo sobrevivio al `adb install -r` de la APK debug reconstruida hoy.

### Prueba fisica ejecutada hoy

Comandos ejecutados:

```bash
cd kan-app
flutter build apk --debug \
  --dart-define=KAN_HOME=citizen \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH=/data/data/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42 \
  --dart-define=KAN_LITERT_TIMEOUT_SECONDS=240
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n gt.kan.kan_app.citizenpreview/gt.kan.kan_app.MainActivity
```

UIAutomator confirmo pantalla ciudadana:

- `ZPK · Modo Ciudadano`
- `Que te paso?`
- `Modo avion: nada sale del telefono`
- `Modo Ventanilla (institucion)`
- `Modo avanzado`
- `Tomar foto (OCR local)`
- `Ayudame ahora`
- `Hablar (STT on-device)`

Se lanzo un caso por ADB. Nota: `adb shell input text` dejo `%20` literal en
vez de espacios, asi que el texto visible fue `Me%20amenazan...`; esto es un
artefacto de automatizacion, no de entrada manual.

Resultado observado:

- A los pocos segundos: panel `Agente razonando`, badge `Gemma 4 E2B local`,
  texto `Voy a entender el caso y proteger tus datos personales`, privacy card
  `No se detectaron datos sensibles`.
- Luego de ~60 s: artifact final `Denuncia formal para MINISTERIO PUBLICO`,
  hash `sha256:da0e9743680f1fcc15994af87d0f78b4376503ba4685d883750353162f4739f2`,
  botones `Copiar`, `Escuchar`, `QR firmado`, `Compartir`.

Evidencia guardada:

```text
docs/evidence/honor-citizen-gemma-thinking-2026-05-07.png
docs/evidence/honor-citizen-gemma-thinking-2026-05-07.uiautomator.xml
docs/evidence/honor-citizen-gemma-artifact-2026-05-07.png
docs/evidence/honor-citizen-gemma-artifact-2026-05-07.uiautomator.xml
```

Importante para claims: esto prueba flujo ciudadano fisico con badge Gemma local
y artifact final. No afirmar todavia "100% de todos los tool calls fueron hechos
por Gemma sin fallback", porque la UI final reemplaza el timeline y logcat del
Honor sale cifrado/oculto (`HKS...HKE`). La arquitectura tiene fallback
deterministico para cerrar cuando Gemma falla o cierra temprano.

### Release ciudadana fisica verificada

Tambien se instalo por USB la APK release exacta de submission:

```text
package: gt.kan.kan_app
apk: submission/live-demo/zpk-citizen-gemma4-release.apk
versionName: 1.0.0
versionCode: 2001
citizen apk sha256: 7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb
installed base.apk sha256: 7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb
```

Modelo usado por la release:

```text
/sdcard/Android/data/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm
size: 2583085056 bytes
sha256: ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

El bridge Android copia el modelo externo a `filesDir/models/` antes de abrir
LiteRT-LM, porque la release crasheaba nativamente al usar directamente la ruta
externa. La release tambien tiene `isMinifyEnabled=false` y
`isShrinkResources=false`; con minify activo el flujo Gemma release era inestable.

Prueba final fisica sobre la release:

- Entrada: amenaza por WhatsApp, pago forzado y solicitud de foto de tarjeta.
- Gemma 4 E2B local ejecuto `redact_pii`, `classify_case`,
  `lookup_codigo_penal`, `draft_denuncia` y `sign_packet`.
- El modelo repitio algunas llamadas; el loop aplico cierre seguro, firmo el
  ultimo artifact valido con Android Keystore y mantuvo el documento mas
  completo.
- Artifact visible: `Denuncia formal para MINISTERIO PUBLICO`.
- Hechos no queda vacio: menciona amenaza por WhatsApp y solicitud de foto de
  tarjeta.
- Firma observada: `zpk-android-keystore-issuer-key-2026-05`.

Evidencia release guardada:

```text
docs/evidence/honor-release-citizen-gemma-final-2026-05-07.xml
```

Nota: `adb shell screencap` fallo en este Honor para la release final; usar el
XML de UIAutomator y/o captura manual del usuario para video.

## Validacion local

Ejecutado hoy en `kan-app/`:

```bash
flutter analyze
# No issues found.

flutter test
# 142 tests passed.
```

Tambien se reconstruyo la APK debug actual:

```bash
flutter build apk --debug ... # PASS, 49.6 s
```

Despues se reemplazo el dialogo falso de `Compartir` por un share-sheet real
Android via `gt.kan.kan_app/platform_share`. Se verifico con:

```bash
flutter test test/artifact_card_test.dart
flutter build apk --debug --dart-define=KAN_HOME=citizen ...
```

Tambien se elimino el fallback muerto de `QR firmado` que mencionaba una
"Fase 5"; en produccion el boton aparece solo cuando la pantalla inyecta el
handler real de QR firmado.

La herramienta agentica `sign_packet` ahora usa Android Keystore por default en
builds release Android (`KAN_DEVICE_KEYSTORE_SIGNING`, default `kReleaseMode`).
Tests/debug siguen usando HMAC local deterministico para no depender de plugins
nativos en CI.

Dependencias directas actualizadas y resueltas:

```text
camera ^0.12.0+1
google_mlkit_text_recognition ^0.15.1
mobile_scanner ^7.2.0
```

`flutter pub outdated` quedo sin direct dependencies outdated. Quedan
transitivas viejas solo donde el solver las restringe.

## Estructura de codigo actual

Entrada principal:

```text
kan-app/lib/main.dart
```

`HomeMode` se elige por dart-define:

- `KAN_HOME=classic`: UI vieja `HomeScreen`, default para no romper verificadores.
- `KAN_HOME=citizen`: UI nueva ciudadana.

Features principales:

```text
kan-app/lib/features/citizen/
  citizen_home.dart
  widgets/agent_stream_panel.dart
  widgets/artifact_card.dart
  widgets/privacy_diff_card.dart

kan-app/lib/features/institution/
  ventanilla_home.dart
  widgets/received_packet_card.dart
  widgets/field_diff_view.dart

kan-app/lib/features/zpk/
  share_packet_sheet.dart
  scan_acuse_sheet.dart

kan-app/lib/features/identity_wallet/
  home_screen.dart  # UI vieja / modo avanzado
```

Servicios agenticos:

```text
kan-app/lib/services/agent/
  agent_loop.dart
  agent_reasoner.dart
  agent_step.dart
  tool_registry.dart
  default_tool_registry.dart
  tool_input_repair.dart
  litert_gemma_agent_reasoner.dart
  local_deterministic_agent_reasoner.dart
  tools/
```

Herramientas locales compartidas por Gemma y fallback:

```text
redact_pii
classify_case
lookup_codigo_penal
lookup_codigo_trabajo
lookup_institucion
draft_denuncia
draft_solicitud
draft_sms_familia
sign_packet
```

Multimodal/local:

```text
kan-app/lib/services/multimodal/
  ocr_service.dart  # ML Kit OCR local
  stt_service.dart  # speech_to_text
  tts_service.dart  # flutter_tts
  qr_service.dart
```

ZPK/paquetes:

```text
kan-app/lib/services/zpk/
  packet_codec.dart
  packet_envelope.dart
  signature_verifier.dart
  institution_trust_list.dart
```

Bridge Android nativo:

```text
kan-app/android/app/src/main/kotlin/gt/kan/kan_app/MainActivity.kt
```

Canales relevantes:

- `gt.kan.kan_app/litert_gemma`: status, warmup, generate, downloadModel.
- El engine LiteRT-LM usa `Backend.CPU(numOfThreads = 4)` y
  `maxNumTokens = 2048`.
- Hay guard contra emulador Android y contra dispositivos con poca RAM.

## Tests importantes

Nuevos o relevantes:

```text
kan-app/test/agent_loop_test.dart
kan-app/test/agent_tools_test.dart
kan-app/test/citizen_home_widget_test.dart
kan-app/test/local_deterministic_agent_reasoner_test.dart
kan-app/test/tool_input_repair_test.dart
kan-app/test/zpk_packet_codec_test.dart
kan-app/test/zpk_roundtrip_test.dart
kan-app/test/zpk_signature_verifier_test.dart
```

Cobertura de comportamiento:

- loop ReAct con fallback
- repair de inputs de tools
- cierre seguro: firma el ultimo artifact valido si Gemma repite tools
- casos Guatemala: extorsion, IGSS sin DPI, SAT bloqueado, remesas, laboral
- UI ciudadana inicial
- codec QR/ZPK
- firma/verificacion HMAC
- guards LiteRT: emulador, low-memory, install failures

## APKs y empaquetado

Estado actual:

- APK debug actual probada en Honor:
  `kan-app/build/app/outputs/flutter-apk/app-debug.apk`
- APK release ciudadana Gemma 4 generada para submission:
  `submission/live-demo/zpk-citizen-gemma4-release.apk`
- Hash release ciudadana:
  `7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb`
- ZIP final de demo:
  `submission/dist/kan-demo-package-final.zip`
- Hash ZIP final:
  `2c3edb395507bd38194a41ee3ef96558ff83f0350d1e228fc5948ae38c2d3237`

Tambien se regeneraron las releases existentes:

```text
submission/live-demo/zpk-local-release.apk
submission/live-demo/zpk-litert-release.apk
submission/live-demo/zpk-citizen-gemma4-release.apk
```

El APK ciudadano se buildio con:

```text
KAN_HOME=citizen
KAN_REASONER=litert-gemma
KAN_LITERT_MODEL_PATH=/sdcard/Android/data/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm
KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
KAN_LITERT_TIMEOUT_SECONDS=240
```

Nota de firma: el ultimo paquete de hoy se firmo con un keystore temporal local
en `/private/tmp/zpk-citizen-release-no-minify-20260507-2.jks`. No se commiteo
el keystore ni la password. Para una publicacion estable se debe conservar una
llave de release formal fuera del repo.

Verificacion ejecutada y aprobada:

```bash
./scripts/package_demo.sh
./scripts/verify_submission.sh
# PASS: submission artifacts verified
# Writeup words: 1465
# Video seconds: 100
# Citizen Gemma APK SHA-256:
# 7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb
```

No usar el QR installer por ahora; el usuario prefirio instalar por cable/USB.

## Dataset y fine tuning

Hay dataset ReAct listo pero no hay entrenamiento real aun:

```text
unsloth/data/react/
  zpk_react_lote1_train.jsonl
  zpk_react_lote1_validation.jsonl
  zpk_react_lote1_test.jsonl
```

Reporte:

```text
unsloth/outputs/react_dataset_quality_report.md
```

Metricas reportadas en `dom3may.md`:

- json_validity_rate: 1.0
- react_format_rate: 1.0
- tool_chain_completeness: 1.0
- pii_leak_rate: 0.0

Scripts:

```bash
cd unsloth
uv run python generate_react_lote1.py
uv run python evaluate_react_dataset.py
```

Regla del repo: Python siempre con virtual env/uv; nunca system Python.

Pendiente: LoRA/GRPO/distillation real en GPU. El laptop Ubuntu/NVIDIA habia
fallado por SSH timeout en sesiones anteriores; no se hizo training hoy.

## Que dice dom3may.md y como usarlo

`dom3may.md` es el contexto narrativo largo del 3 de mayo. Sigue siendo util
para explicar:

- Modo Ciudadano y Modo Ventanilla.
- Por que Gemma 4 E2B + LiteRT-LM es el camino on-device.
- Por que el fallback deterministico es honesto y necesario.
- Como vender el demo al jurado.
- Limitaciones: no zk-SNARK real, no integracion real con IGSS/SAT/RENAP, no
  LoRA entrenado todavia.

Pero para claims publicos usar lo verificado hoy y los archivos de evidencia.

## Articulo Flutter Agent Skills

Se reviso el material oficial actual en:

```text
https://docs.flutter.dev/ai/agent-skills
```

Utilidad para este repo:

- Si se quiere mejorar futuras sesiones de desarrollo, conviene instalar skills
  oficiales de Flutter/Dart en `.agents/skills`.
- Comandos sugeridos por la doc oficial:

```bash
npx skills add flutter/skills --skill '*' --agent universal
npx skills add dart-lang/skills --skill '*' --agent universal
```

No es una feature de la app ni un claim del hackathon. Es higiene de desarrollo
para que agentes futuros respeten mejores patrones Flutter/Dart. No hacerlo no
bloquea la submission.

## Riesgos y gaps honestos

- La app debug y la release ciudadana exacta de submission funcionaron en Honor
  fisico. La release genero artifact firmado con Android Keystore despues del
  cierre seguro del loop.
- Logcat en Honor salio cifrado/oculto; usar UIAutomator/screenshot como
  evidencia fisica.
- El flujo demuestra Gemma 4 local y tool calls visibles en UI, pero el cierre
  seguro puede intervenir si Gemma repite herramientas o no llama `final`.
- `sign_packet` usa Android Keystore en release Android, pero el QR de
  ciudadano/acuse todavia usa trust list HMAC del piloto offline; no es aun
  firma asimetrica institucional completa ni zk-SNARK.
- No hay integracion real con instituciones; Modo Ventanilla simula la mesa
  institucional localmente.
- La entrada por `adb input text` puede distorsionar espacios o acentos; para
  video/manual usar teclado, voz o pegar texto normal.
- Las capturas pueden tener UI parcialmente recortada por scroll; para video,
  usar captura manual/OBS y evitar notificaciones flotantes.

## Siguientes pasos recomendados

1. Para reinstalar la release final por cable, usar:
   `adb install -r submission/live-demo/zpk-citizen-gemma4-release.apk`.
2. Si se desinstala la app, volver a copiar el modelo a:
   `/sdcard/Android/data/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm`.
3. Exponer en la UI final un resumen persistente del timeline agentico despues
   del artifact, para poder demostrar tool calls Gemma/fallback sin depender de
   logcat.
4. Crear boton "Ver trazabilidad del agente" en artifact final: mostrar
   `redact_pii -> classify_case -> lookup -> draft -> sign_packet`, indicando
   que motor decidio cada paso y si hubo fallback.
5. Entrenar LoRA con el dataset ReAct si el laptop GPU vuelve a estar accesible.
6. Preparar video de 3 minutos: ciudadano habla/foto/texto, Gemma local razona,
   artifact, QR firmado, Modo Ventanilla verifica, acuse de vuelta.
7. Actualizar Kaggle writeup con claims honestos: offline/on-device real en
   Honor, fallback para hardware bajo, cero PII real, demo institucional local.

## Comandos de bolsillo

Build/debug Honor:

```bash
cd /Users/anibalperez/Code/AI/kaggle/kan-app
flutter build apk --debug \
  --dart-define=KAN_HOME=citizen \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH=/data/data/gt.kan.kan_app.citizenpreview/files/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42 \
  --dart-define=KAN_LITERT_TIMEOUT_SECONDS=240
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n gt.kan.kan_app.citizenpreview/gt.kan.kan_app.MainActivity
```

Verificar modelo:

```bash
adb shell run-as gt.kan.kan_app.citizenpreview ls -lh files/models
adb shell run-as gt.kan.kan_app.citizenpreview cat files/models/gemma-4-E2B-it.litertlm.sha256
adb shell run-as gt.kan.kan_app.citizenpreview wc -c files/models/gemma-4-E2B-it.litertlm
```

Dump UI/screenshot:

```bash
adb shell uiautomator dump /sdcard/zpk.xml
adb pull /sdcard/zpk.xml /private/tmp/zpk.xml
adb shell screencap -p /sdcard/zpk.png
adb pull /sdcard/zpk.png /private/tmp/zpk.png
```

Calidad local:

```bash
cd /Users/anibalperez/Code/AI/kaggle/kan-app
flutter analyze
flutter test
dart format lib test
```

Estado Git:

```bash
cd /Users/anibalperez/Code/AI/kaggle
git status --short
```

No revertir cambios no propios. No hacer `git reset --hard`.
