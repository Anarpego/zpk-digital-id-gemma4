# LiteRT Gemma 4 Motorola G15 Evidence

Date: 2026-05-02

## Device

- Model: Motorola G15 (`moto g15`)
- Serial: `ZY32LL9926`
- ABI: `arm64-v8a`
- RAM reported by Android: `3869007872` bytes

## APK

- File: `motorola/zpk-litert-persona-institucion-release.apk`
- SHA-256: see `motorola/zpk-litert-persona-institucion-release.apk.sha256`
- Install command result:

```text
Performing Streamed Install
Success
```

Submission package after this app update:

```text
submission/dist/kan-demo-package-final.zip
sha256: see `submission/dist/kan-demo-package-final.zip.sha256`
submission/live-demo/zpk-litert-release.apk
sha256: see `submission/live-demo/zpk-litert-release.apk.sha256`
./scripts/verify_submission.sh -> PASS
```

## Model Install

The real Gemma 4 E2B LiteRT-LM artifact was installed into app-private storage.

```text
litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> DEVICE_LOW_MEMORY
litert_gemma.model_size_bytes -> 2583085056
litert_gemma.device_ram_bytes -> 3869007872
litert_gemma.required_ram_bytes -> 6000000000
litert_gemma.model_path(app_private) -> configured
runtime.local_deterministic -> ready
runtime.network_required -> false
runtime.model_backed -> false
```

## Result

The app no longer exposes a crash-prone self-test on this phone. It reports
`DEVICE_LOW_MEMORY` because the model is installed but the phone has less than
the 6 GB RAM gate required for safe Gemma 4 E2B LiteRT-LM generation.

This is not a successful Android physical Gemma 4 generation claim. It is
evidence that the Android app can install and verify the real model, detect the
hardware limit, and keep the citizen/institution workflows offline through the
deterministic local agent without lying to judges or users.

After the fallback-aware runtime update, UIAutomator accessibility output for
`Motor` on the physical G15 contained:

```text
Motor offline
LiteRT-LM Gemma 4 local
DEVICE_LOW_MEMORY
hardware limitado
Gemma 4 esta instalado, pero este telefono no tiene memoria suficiente...
Respaldo offline disponible: Motor offline listo...
runtime.local_deterministic -> ready
runtime.network_required -> false
```

## Fallback App Flow

The latest physical-device flow verifies the new citizen/institution UX. UIAutomator
accessibility output on the Motorola G15 contained:

```text
Vista persona
Necesito registrarme o recuperar IGSS
Continuar sin CUI
Mesa institucional IGSS
Bandeja IGSS
sin CUI
firma local ok
Modelo local
Ruta de atencion
Atender como intake presencial sin credencial
Pseudonimo: zpk-gt-intake-...
Hash paquete: ...
Copiar paquete institucional
```

The screenshot API returned a black image because `FLAG_SECURE` is enabled.
That is expected privacy behavior, so this evidence uses accessibility text
instead of a visual screenshot.

This flow is now reproducible with:

```bash
./scripts/verify_motorola_physical_flow.sh --no-install
```

Latest result on the connected G15:

```text
PASS: Motorola physical flow verified.
```

The older `Tramite` institutional recovery flow was also verified after the
low-memory guard:

```text
Prioridad: recuperar tramite
Revision local hecha: riesgo clasificado, PII bloqueada y paquete redactado preparado.
CUI no sale
funciona sin red
paquete firmado
Modelo local
92% confianza
Respaldo offline ejecuto la guia
```

This proves the phone remains useful for the citizen workflow even when Gemma 4
generation needs higher-RAM hardware.
