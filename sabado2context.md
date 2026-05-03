# Contexto sabado 2 - ZPK Digital ID

## Proposito de este archivo

Este archivo es el handoff para una futura sesion de codigo. Resume que es la app hoy, que se probo en el Motorola fisico, como quedo Gemma 4 LiteRT-LM, que artefactos estan listos y que limites no se deben ocultar.

No se debe enviar nada a Kaggle desde Codex. El usuario hara la submission manual.

## Objetivo del proyecto

ZPK Digital ID es una app Flutter Android para Gemma 4 Good enfocada primero en Guatemala. La propuesta es identidad digital local-first para paises con infraestructura institucional fragil: CUI/DPI se queda en el dispositivo, la app produce paquetes redactados, rutas de recuperacion y evidencia verificable para instituciones como IGSS, SAT y colegios, sin enviar PII al modelo.

La historia para jueces: una persona con poca experiencia tecnologica puede recuperar o proteger identidad despues de filtraciones, estafas, extorsion o tramites bloqueados; una institucion puede recibir un intake firmado y minimizado sin exigir datos sensibles por canales inseguros.

## Estado actual de la app

Ruta principal: `kan-app/`.

La app ya no esta organizada como una sola pantalla larga de demo. La vista principal esta en:

```text
kan-app/lib/features/identity_wallet/home_screen.dart
```

Vistas actuales:

- `Persona`: selecciona el caso de ayuda, por ejemplo IGSS, SAT, colegio, dinero, amenazas o DPI/datos.
- `Acciones`: muestra pasos ejecutables y lenguaje claro para usuarios sin background tecnico.
- `Institucion`: mesa simulada de intake institucional, por ejemplo IGSS/SAT/colegio, con ruta de atencion y paquete redactado.
- `Evidencia`: muestra trust fabric, paquete firmado, hash, pseudonimo y auditoria local.
- `Motor`: estado real del motor offline: LiteRT-LM Gemma 4 si el dispositivo aguanta, o respaldo deterministico offline si no.

En `Acciones` y `Evidencia`, la app muestra ahora una prueba visible del agente antes de las trazas crudas: `Prueba agente local`, conteo de herramientas, `PII bloqueada`, estado de JSON de modelo cuando aplica, y `ledger firmado`. Esto evita que el juez tenga que leer logs para ver el comportamiento agentico.

Casos principales:

- `IGSS`: afiliacion, recuperacion o atencion presencial sin CUI.
- `SAT`: recuperacion de acceso, actualizacion o bloqueo preventivo.
- `Colegio`: inscripcion, beca o constancia.
- Otros: tramite, DPI/datos, dinero, amenazas, campo, proteccion, duda y prevenir.

Los flujos `IGSS`, `SAT` y `Colegio` permiten continuar sin CUI. En ese modo la app no emite credencial falsa; genera intake institucional, checklist y paquete redactado. Si hay CUI sintetico valido, la app puede crear pseudonimo local y paquete firmado.

## Estructura de codigo relevante

- `kan-app/lib/main.dart`: entrypoint Flutter y configuracion general.
- `kan-app/lib/config/app_config.dart`: dart-defines, modo de razonador y rutas de modelo.
- `kan-app/lib/features/identity_wallet/home_screen.dart`: UI Persona/Acciones/Institucion/Evidencia/Motor.
- `kan-app/lib/models/kan_case.dart`: escenarios, labels, misiones, institucion objetivo y `allowsNoCui`.
- `kan-app/lib/services/kan_reasoner.dart`: contrato comun, estado runtime y fallback.
- `kan-app/lib/services/litert_gemma_reasoner.dart`: razonador Gemma 4 LiteRT-LM via MethodChannel.
- `kan-app/lib/services/local_deterministic_reasoner.dart`: agente offline deterministico.
- `kan-app/lib/services/reasoner_factory.dart`: selecciona razonador segun configuracion.
- `kan-app/lib/services/routing_policy.dart`: decide herramientas locales vs modelo sin enviar PII.
- `kan-app/lib/services/identity_protection_agent.dart`: herramientas agente, evaluacion de riesgo y acciones.
- `kan-app/lib/services/digital_identity_fabric.dart`: credencial/pseudonimo/firma local.
- `kan-app/lib/services/recovery_packet_service.dart`: paquete de recuperacion redactado.
- `kan-app/lib/services/identity_signer.dart`: firma local.
- `kan-app/android/app/src/main/kotlin/gt/kan/kan_app/MainActivity.kt`: puente nativo Android para LiteRT-LM, instalacion, verificacion de hash y guard de RAM.
- `kan-app/test/`: pruebas widget y servicios.
- `scripts/`: empaquetado, verificadores de submission y pruebas fisicas.
- `motorola/`: APK vigente y runbook para dispositivo fisico.
- `unsloth/`: dataset y scripts de fine-tuning/evaluacion usando `uv`, nunca system Python.

Ruta vieja eliminada: `kan-app/lib/features/demo/home_screen.dart`. `scripts/verify_submission.sh` falla si vuelve a aparecer `features/demo`.

## Gemma 4 LiteRT-LM

Modelo instalado en el Motorola G15:

```text
/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm
size: 2583085056 bytes
sha256: ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

Como funciono la instalacion:

- El APK se instalo por USB/ADB.
- El modelo quedo en almacenamiento privado de la app.
- Al reinstalar con `adb install -r`, Android conserva los datos privados de la app, por eso el modelo siguio ahi.
- Si se desinstala la app, se limpia storage o se cambia de telefono, hay que instalar el modelo otra vez.

El flujo soportado por codigo es descargar desde `KAN_LITERT_MODEL_URL` hacia `KAN_LITERT_MODEL_PATH`, validar `KAN_LITERT_MODEL_SHA256` y luego hacer warmup. Los links `trycloudflare` son temporales; si expiran aparece algo como `Unable to resolve host ...`. Para un telefono nuevo se necesita URL nuevo o hosting local/HTTPS estable antes de pulsar `Instalar Gemma offline`.

Guard de seguridad agregado:

- `warmup` y `generate` reciben `KAN_LITERT_MODEL_SHA256`.
- Android calcula/verifica SHA-256 antes de abrir LiteRT-LM.
- Si falta sidecar `.sha256` pero el archivo coincide, lo repara.
- Si el hash no coincide, falla cerrado.
- `installRuntimeAssets()` hace warmup aunque el modelo ya exista, para no reportar listo sin probar runtime.
- Si el probe nativo de Gemma falla por completo, `FallbackReasoner.runtimeStatus()` conserva `offline=true` cuando el agente local deterministico esta listo. Esto evita diagnosticos falsos tipo `offline=false` en dispositivos donde el canal nativo falla pero la app aun puede ejecutar flujos locales.

Define correcto:

```bash
--dart-define=KAN_REASONER=litert-gemma
```

No usar `KAN_REASONER_MODE`.

## Motorola G15 fisico

Dispositivo probado:

```text
serial: ZY32LL9926
model: moto g15
abi: arm64-v8a
ram reportada por app: 3869007872 bytes
```

Nota: la prueba fisica mas reciente con `run_physical_litert_proof.sh` reporto
`3868741632` bytes. Esa diferencia pequena es normal entre lecturas de memoria;
en ambos casos esta por debajo del minimo de 6 GB exigido por el guard.

Estado real visto en la app:

```text
LiteRT-LM Gemma 4 local
DEVICE_LOW_MEMORY
litert_gemma.model_size_bytes -> 2583085056
litert_gemma.device_ram_bytes -> 3869007872
litert_gemma.required_ram_bytes -> 6000000000
litert_gemma.model_path(app_private) -> configured
Respaldo offline disponible
runtime.local_deterministic -> ready
runtime.network_required -> false
```

Conclusion tecnica: Gemma 4 E2B esta instalado en el Motorola G15, pero el telefono no tiene suficiente RAM para una generacion estable. La app lo detecta y cae a agente deterministico offline sin fingir que Gemma genero texto. Para reclamar generacion Android real de Gemma 4 hace falta un telefono ARM64 con 6 GB+ RAM.

Comando de prueba fisica que paso:

```bash
./scripts/verify_motorola_physical_flow.sh --no-install
```

Resultado:

```text
PASS: Motorola physical flow verified.
```

Ese script valida por UIAutomator:

- App instalada y abierta en dispositivo fisico ARM64.
- Vista `Persona`.
- Seleccion de `IGSS`.
- Flujo `Continuar sin CUI`.
- Cambio a `Institucion`.
- Textos estables: `Mesa institucional IGSS`, `Atender como intake presencial sin credencial`, `Pseudonimo:` y `Hash paquete:`.
- Vista `Motor` con `DEVICE_LOW_MEMORY`, `Respaldo offline disponible`, `runtime.local_deterministic -> ready` y `runtime.network_required -> false`.

Prueba que debe fallar en G15 por baja RAM:

```bash
./scripts/run_physical_litert_proof.sh --no-install --watch-seconds 1
```

Resultado esperado en G15:

```text
exit 4
Device RAM: 3869007872 bytes; required for Gemma proof: 6000000000 bytes
```

Solo cuenta como prueba Android real de Gemma 4 un dispositivo donde el log muestre `litert_gemma.generate(...) -> ok`.

## APK vigente para Motorola

APK a copiar por cable o instalar por ADB:

```text
motorola/zpk-litert-persona-institucion-release.apk
sha256: d3ab26a09c79a454b68be344df43bd6c58ba95f8aec73a8bd34f547588167e09
```

Despues de regenerar artefactos, este APK se reinstalo en el Motorola por USB:

```bash
adb install -r motorola/zpk-litert-persona-institucion-release.apk
```

Resultado:

```text
Performing Streamed Install
Success
```

Verificacion:

```bash
./motorola/verificar-apk.sh
```

Resultado actual:

```text
zpk-litert-persona-institucion-release.apk: OK
```

El APK de `motorola/` esta sincronizado con:

```text
submission/live-demo/zpk-litert-release.apk
sha256: d3ab26a09c79a454b68be344df43bd6c58ba95f8aec73a8bd34f547588167e09
```

Los APKs de `motorola/` estan ignorados por Git para no ensuciar el repo publico. Estan disponibles localmente y dentro del ZIP final.

## Artefactos actuales de submission

Paquete final:

```text
submission/dist/kan-demo-package-final.zip
sha256: fc1a1575d2feae386b9106de3306b496bb8a57e1059067cde3fd305224a90bc3
```

Copia preparada para Kaggle Dataset:

```text
submission/kaggle-dataset-upload/kan-demo-package-final.zip
sha256: fc1a1575d2feae386b9106de3306b496bb8a57e1059067cde3fd305224a90bc3
```

APKs incluidos en `submission/live-demo/`:

```text
zpk-local-release.apk
sha256: fbfb9cf8b077ce3b284dbbddfcd76efb493a79f80c20e1f12c3531a8a642839f

zpk-litert-release.apk
sha256: d3ab26a09c79a454b68be344df43bd6c58ba95f8aec73a8bd34f547588167e09
```

Otros hashes del verificador:

```text
Video SHA-256: e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6
Cover SHA-256: bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947
Video seconds: 100
Cover dimensions: 1600x900
Writeup words: 1465
```

La portada publica `submission/media-gallery-cover.svg/png` ya no usa wording de demo en la credencial; se cambio a `DID + VC local`. `scripts/verify_submission.sh` ahora falla si la portada vuelve a contener wording de demo/prototipo.

El ZIP contiene solo APKs release:

```text
submission/live-demo/zpk-local-release.apk
submission/live-demo/zpk-local-release.apk.sha256
submission/live-demo/zpk-litert-release.apk
submission/live-demo/zpk-litert-release.apk.sha256
```

No contiene `kan-debug.apk`.

## Comandos ejecutados al cierre

Preparar copia Kaggle Dataset:

```bash
KAGGLE_USERNAME=anarpego ./scripts/prepare_kaggle_dataset.sh
```

Resultado:

```text
PASS: submission artifacts verified
Prepared Kaggle Dataset upload folder:
/Users/anibalperez/Code/AI/kaggle/submission/kaggle-dataset-upload
```

Verificaciones finales:

```bash
./scripts/verify_submission.sh
shasum -a 256 -c kan-demo-package-final.zip.sha256
./motorola/verificar-apk.sh
rg -n kan-debug\.apk docs submission README.md SUBMIT_NOW.md SUBMISSION_CHECKLIST.md
```

Resultados actuales:

```text
verify_submission.sh -> PASS
submission/dist checksum -> OK
submission/kaggle-dataset-upload checksum -> OK
motorola/verificar-apk.sh -> OK
rg kan-debug.apk -> no output
```

Tambien se verifico que `zipinfo` no encuentra `*kan-debug*` dentro del ZIP final.

## Build release usado por el empaquetador

El empaquetador exige firma release y falla si faltan variables:

```bash
ZPK_RELEASE_KEYSTORE=/Users/anibalperez/Code/AI/kaggle/.secrets/zpk-sideload-release.p12 ZPK_RELEASE_STORE_PASSWORD=<local-secret> ZPK_RELEASE_KEY_ALIAS=zpk-sideload ZPK_RELEASE_KEY_PASSWORD=<local-secret> ./scripts/package_demo.sh
```

`scripts/package_demo.sh` genera APKs release ARM64, sincroniza `motorola/zpk-litert-persona-institucion-release.apk`, incluye fuente auditable de `kan-app/` en el ZIP y bloquea artefactos locales/generados como `.dart_tool`, `build`, `android/local.properties`, Pods y registrants generados.

`scripts/verify_submission.sh` ahora revisa:

- APKs firmados release, no debug.
- Manifest con package `gt.kan.kan_app` y label `ZPK Digital ID`.
- `allowBackup=false`.
- `usesCleartextTraffic=false`.
- `fullBackupContent` y `dataExtractionRules` presentes.
- No `features/demo`.
- No `kan-debug.apk`.
- Checksums portables.
- Fuente reconstruible minima de Flutter/Android/iOS dentro del ZIP.

## Tests y calidad

Ultimo estado conocido de app, revalidado el 2026-05-03:

```text
cd kan-app
flutter analyze -> No issues found
flutter test -> 74 tests passed
```

Tambien se revalido:

```text
./scripts/verify_submission.sh -> PASS
./motorola/verificar-apk.sh -> OK
./scripts/verify_motorola_physical_flow.sh --no-install -> PASS
./scripts/run_physical_litert_proof.sh --no-install --watch-seconds 1 -> exit 4 por baja RAM esperada en Motorola G15
flutter pub outdated -> direct dependencies and dev_dependencies all up-to-date
```

`./scripts/verify_motorola_physical_flow.sh --no-install` se ejecuto despues de
instalar el APK release vigente por USB. `adb shell run-as gt.kan.kan_app ...`
fallo con `package not debuggable`, lo cual es consistente con APK release.

Nota de dependencias: `flutter pub outdated` mostro paquetes transitivos con
versiones mas nuevas disponibles, pero las dependencias directas del proyecto y
`dev_dependencies` estan al dia. El comando tambien imprimio errores de decode
de advisories de `pub.dev` (`advisoriesUpdated must be a String`), por lo que
esa salida no debe contarse como auditoria completa de seguridad.

Dataset/fine-tuning:

```text
cd unsloth
uv run python evaluate_dataset.py -> PASS
uv run python -m py_compile generate_guatemala_latam_sft.py evaluate_dataset.py train_lora.py train_grpo.py distill_with_gemma4_teacher.py zpk_rewards.py -> ok
```

Regla permanente: Python siempre con entorno virtual y `uv`; nunca system Python.

Dataset generado:

```text
unsloth/data/
train: 9840
validation: 1080
test: 1080
scenarios: economic_fraud, extortion_evidence, identity_recovery, igss_registration, preventive_wallet, sat_tax_access, school_enrollment
No 13-digit identifiers appear.
Assistant content is strict JSON.
```

## Que no se debe afirmar

No afirmar:

- Que el Motorola G15 genero texto con Gemma 4. No lo hizo; detecto baja RAM.
- Que hay integracion real con IGSS, SAT, RENAP, gobierno o colegios.
- Que hay PII real o datos de brechas reales dentro del repo.
- Que hay un modelo fine-tuned publicado y evaluado como final.
- Que el link Cloudflare viejo sigue funcionando.
- Que el APK debug es parte de la entrega.

Si se habla de Gemma 4 en Android hoy, decir: modelo Gemma 4 instalado y verificado por hash en dispositivo, runtime protegido por guard de RAM, fallback offline funcional, y prueba de generacion pendiente en telefono high-RAM.

## Siguiente sesion recomendada

Prioridad tecnica para ganar mas puntos:

1. Probar `run_physical_litert_proof.sh` en un Android ARM64 con 6 GB+ RAM.
2. Si pasa, capturar log `litert_gemma.generate(...) -> ok` y actualizar docs/evidence.
3. Si no hay telefono high-RAM, usar iOS Simulator o Mac solo como evidencia auxiliar, dejando claro que Android real sigue pendiente.
4. Mejorar mas la UI tipo ciudadano/institucion, pero sin agregar placeholders ni claims falsos.
5. Si se fine-tunea, publicar pesos/adapter y benchmarks; si no, mantenerlo como dataset/eval preparado, no como modelo entrenado final.

Intento GPU mas reciente: `ssh -i /Users/anibalperez/.ssh/id_ed25519 -o
ConnectTimeout=8 -o BatchMode=yes anarpego@192.168.0.17 ...` volvio a terminar
en `Operation timed out`, asi que no hay adapter entrenado desde ese laptop en
esta sesion.

Para reinstalar en Motorola actual:

```bash
adb install -r motorola/zpk-litert-persona-institucion-release.apk
adb shell monkey -p gt.kan.kan_app 1
./scripts/verify_motorola_physical_flow.sh --no-install
```

Para revisar modelo en app-private storage, si `run-as` funciona:

```bash
adb shell run-as gt.kan.kan_app ls -lh files/models
adb shell run-as gt.kan.kan_app sha256sum files/models/gemma-4-E2B-it.litertlm
```

Si no funciona `run-as`, usar la vista `Motor` como evidencia.

## Estado de procesos locales

Al cierre se intento revisar procesos. `pgrep` fallo por entorno local, pero `ps -axo pid,command` no mostro Xcode, iOS Simulator, Android Emulator ni `qemu-system`. Si aparece consumo raro luego, revisar manualmente. El daemon `adb` si quedo activo porque el Motorola estaba conectado.
