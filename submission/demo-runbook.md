# Demo Runbook

## Current Local Demo

```bash
cd kan-app
flutter pub get
flutter test
flutter build apk --release --split-per-abi
cd ..
# Requires ZPK_RELEASE_* signing variables for the public APKs.
./scripts/package_demo.sh
adb install -r submission/live-demo/zpk-local-release.apk
adb shell monkey -p gt.kan.kan_app 1
```

Default mode is the deterministic local reasoner:

```bash
flutter run -d emulator-5554
```

Cactus mode is selected at compile time. The current default model slug is `functiongemma-270m-pro`, because the Cactus 1.3.0 catalog exposes FunctionGemma 3 with tool calling. This is useful Cactus evidence, but it is not Gemma 4 evidence.

```bash
flutter run -d emulator-5554 \
  --dart-define=KAN_REASONER=cactus \
  --dart-define=KAN_CACTUS_MODEL=functiongemma-270m-pro \
  --dart-define=KAN_CACTUS_TIMEOUT_SECONDS=300
```

If tool-calling fails in Cactus with `completion failed with code -1`, isolate the runtime by disabling Cactus tools:

```bash
flutter run -d emulator-5554 \
  --dart-define=KAN_REASONER=cactus \
  --dart-define=KAN_CACTUS_MODEL=functiongemma-270m \
  --dart-define=KAN_CACTUS_ENABLE_TOOLS=false \
  --dart-define=KAN_CACTUS_TIMEOUT_SECONDS=180
```

Telemetry is disabled in `ReasonerFactory` before building any reasoner.
If the model is unavailable or initialization exceeds the timeout, ZPK falls back to the deterministic local reasoner and records the failure type in the tool trace.

Hosted Gemma 4 mode is also compile-time selected. Use it only for local demos; do not commit API keys or publish an APK with an embedded key.

```bash
set -a
source ../.env
set +a
flutter run -d emulator-5554 \
  --dart-define=KAN_REASONER=gemma-hosted \
  --dart-define=KAN_GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=KAN_GEMINI_MODEL=gemma-4-31b-it
```

For non-app evidence, run:

```bash
../scripts/gemma4_smoke.sh
```

Use synthetic CUI values:

- `1234567890101`: exposed in the synthetic Mintrab breach.
- `2890123450101`: exposed in the synthetic Digecam breach.
- `3012345670101`: exposed in the synthetic fake-NGO flow.
- `1111111111111`: valid CUI with no local match.
- `123`: invalid CUI.

## Recording Path

1. Start on the home screen showing `Wallet local`.
2. Enter `1234567890101`.
3. Tap `Registrar ZPK y generar guia`.
4. Pause on `Coincidencia encontrada`.
5. Scroll to `Guia de accion`.
6. Pause on `Registro ZPK local`, especially `trust_fabric.did_document(local)`, `trust_fabric.vc_selective_disclosure(local)`, and `trust_fabric.issue_consent(local, 15m)`.
7. Scroll to `Denuncia lista`.

## Evidence To Capture Before Final Submission

- Cactus model name and version.
- Cactus available-model list showing the chosen slug.
- Separate Gemma 4 evidence from Google AI Studio or a verified local Gemma 4 runtime.
- Hosted Gemma 4 mode screenshot showing `Gemma 4 API` and `gemma_api.generateContent(...) -> ok`.
- Device or emulator details.
- Model download/init time.
- First-token latency and total response time.
- Screenshot or clip proving local inference.
- Unsloth before/after comparison if targeting that prize.

## Do Not Claim Yet

- Do not claim production legal correctness.
- Do not claim real breach coverage.
- Do not claim Cactus prize readiness until real on-device inference is recorded.
- Do not claim Gemma 4 on-device via Cactus unless the catalog has an actual Gemma 4 slug.
- Do not publish a mobile build with `KAN_GEMINI_API_KEY` embedded.
- Do not claim Unsloth prize readiness until dataset, notebook, adapter, and benchmark exist.
