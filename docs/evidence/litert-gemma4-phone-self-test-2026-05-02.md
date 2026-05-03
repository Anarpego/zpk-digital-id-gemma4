# LiteRT Gemma 4 Phone Self-Test

Date: 2026-05-02

## Purpose

The LiteRT APK now includes an in-app phone self-test so the physical-device run can be validated without cable logs.

## User Flow

1. Install the latest `zpk-litert.apk`.
2. Open `Motor agente offline`.
3. If the model is not installed, tap `Instalar Gemma offline` and leave the app open until the model is available.
4. When the runtime shows offline-ready, tap `Probar Gemma offline`.
5. Tap `Copiar diagnostico` and save the copied text for Kaggle evidence.

## Expected Successful Traces On High-RAM Phone

```text
litert_gemma.self_test.status_probe(gemma-4-E2B-it-litertlm) -> AVAILABLE
litert_gemma.self_test.warmup(gemma-4-E2B-it-litertlm) -> READY
agent_contract.schema(json) -> ok
agent_contract.safety_review(raw_cui=false) -> ok
privacy_guard.self_test_raw_cui -> absent
litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok
```

## Safety Boundary

The self-test prompt uses only synthetic, redacted Guatemala identity-risk context. It asks Gemma 4 for JSON guidance and validates the response with the same app contract used by the case flow. A successful trace proves native LiteRT-LM generation, JSON contract compliance, and no raw CUI in the self-test path.

## Current Status

Implemented and covered by Flutter widget test. The signed release APK also downloads the 2,583,085,056-byte model into app-private storage and verifies the SHA-256 sidecar before runtime use.

On the available Motorola G15, the APK installs the real model but does not show
the self-test action because the phone reports `DEVICE_LOW_MEMORY`:

```text
litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> DEVICE_LOW_MEMORY
litert_gemma.model_size_bytes -> 2583085056
litert_gemma.device_ram_bytes -> 3869007872
litert_gemma.required_ram_bytes -> 6000000000
runtime.local_deterministic -> ready
runtime.network_required -> false
```

This low-memory state is covered by a dedicated Flutter widget test and by
`./scripts/verify_motorola_physical_flow.sh --no-install`. It is not a native
Android Gemma generation proof.

On the Mac Android emulator, native LiteRT-LM engine creation crashes before Dart can catch it. The APK now detects Android emulator builds and fails closed with:

```text
reasoner_runtime(litert-gemma:gemma-4-e2b-it) -> EMULATOR_UNSUPPORTED
litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> EMULATOR_UNSUPPORTED
litert_gemma.model_size_bytes -> 2583085056
litert_gemma.model_path(app_private) -> configured
```

The UI shows the installed model and removes the dead-end install/self-test actions on emulator and low-memory phones. The final physical-device generation claim is still pending until a high-RAM phone produces the successful copied trace above.
