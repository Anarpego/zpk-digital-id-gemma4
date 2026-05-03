# ZPK Digital ID

ZPK Digital ID is a local-first Android app for the Gemma 4 Good Hackathon. It registers a citizen into a privacy-preserving identity wallet, issues a pseudonymous local credential, checks a synthetic offline CUI risk catalog, and prepares recovery guidance without sending raw CUI to the cloud.

This repository is optimized for a public hackathon submission and reproducible evidence. It intentionally avoids real personal data, real breach records, and government registry connectivity.

## Current App

- Flutter app: `kan-app/`
- Embedded synthetic breach catalog: `kan-app/assets/breach_catalog.json`
- Local ZPK trust fabric: HMAC-derived pseudonymous ID, DID-style document, Android Keystore-backed HMAC-SHA256 recovery credential, signed and locally verified agent ledger, hash-verified offline civic threat bulletins, Android device-presence-gated verifier-enforced allowlisted expiring local authentication proof, signed and locally verified redacted recovery packet, signed local revocation receipt that blocks new auth proofs, selective disclosure claims, 15-minute consent proof, and validated JSON agent-response contracts for model outputs.
- Local privacy controls: raw CUI prompt guard, model-prompt redaction of stable local IDs and proof material, encrypted app-internal audit archive, citizen archive deletion, `FLAG_SECURE`, disabled Android backup, and cleartext traffic disabled.
- Evidence docs: `docs/evidence/`
- Final submission assets: `submission/`
- Gemma 4 adaptation pipeline: `unsloth/`
- CI: `.github/workflows/android-ci.yml` runs Flutter format, analyze, tests,
  APK build, LiteRT app-agent harness, and release-signing gate.

## Quick Start

```bash
cd kan-app
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release --split-per-abi
flutter run
```

Use synthetic CUI `1234567890101` for the main app flow.

## Reasoner Modes

Default deterministic local mode:

```bash
cd kan-app
flutter run
```

Cactus local mode, no tools, verified on the Android emulator:

```bash
cd kan-app
flutter run \
  --dart-define=KAN_REASONER=cactus \
  --dart-define=KAN_CACTUS_MODEL=functiongemma-270m \
  --dart-define=KAN_CACTUS_ENABLE_TOOLS=false \
  --dart-define=KAN_CACTUS_TIMEOUT_SECONDS=180
```

Hosted Gemma 4 mode for local testing only:

```bash
cd kan-app
set -a
source ../.env
set +a
flutter run \
  --dart-define=KAN_REASONER=gemma-hosted \
  --dart-define=KAN_GEMINI_API_KEY="$GEMINI_API_KEY" \
  --dart-define=KAN_GEMINI_MODEL=gemma-4-31b-it
```

Do not publish APKs with embedded API keys.

ML Kit/AICore on-device mode, verified to build and to fail closed on the Mac emulator:

```bash
cd kan-app
flutter run \
  --dart-define=KAN_REASONER=mlkit-gemma \
  --dart-define=KAN_MLKIT_TIMEOUT_SECONDS=120
```

This mode uses Android ML Kit Prompt API. It needs a supported AICore device for actual on-device Gemma/Gemini Nano generation; the available emulator reports `UNAVAILABLE` and the app falls back locally with a visible trace. On supported devices the app now handles `DOWNLOADABLE` by requesting the model download, re-probing status, warming the runtime, and then generating locally.

AI Edge Gallery running Gemma 4 offline uses a different Google AI Edge /
LiteRT-LM path with downloaded open model artifacts. ZPK now has an Android
LiteRT-LM bridge using `com.google.ai.edge.litertlm:litertlm-android:0.10.2`.
On the Mac emulator, the app loads the 2.4 GB Gemma 4 E2B `.litertlm` file from
app-private storage and reaches prefill/decode, then fails closed because the
emulator lacks a usable OpenCL sampler. Use a physical Android device for the
final successful in-app generation proof.

LiteRT-LM Gemma 4 E2B local smoke, verified offline on the Mac after the model
download:

```bash
uv venv /private/tmp/zpk-litert-venv
uv pip install --python /private/tmp/zpk-litert-venv/bin/python litert-lm
LITERT_LM_BIN=/private/tmp/zpk-litert-venv/bin/litert-lm \
LITERT_GEMMA4_MODEL_PATH=/path/to/gemma-4-E2B-it.litertlm \
./scripts/litert_gemma4_smoke.sh
```

LiteRT-LM Android mode, intended for a physical Android device:

```bash
cd kan-app
flutter run \
  --dart-define=KAN_REASONER=litert-gemma \
  --dart-define=KAN_LITERT_MODEL_PATH=/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_LITERT_MODEL_URL=https://your-cloudflare-url/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42 \
  --dart-define=KAN_LITERT_TIMEOUT_SECONDS=240
```

Pre-device app harness for the agentic LiteRT path:

```bash
./scripts/test_litert_agent_harness.sh
```

This runs Flutter tests with a mocked Android LiteRT MethodChannel. It verifies
the app shows offline Gemma runtime status, hash-checks pre-existing models,
can install/download/warm up the model before a case, calls
status/warmup/generate, parses the returned JSON with `AgentResponseContract`,
renders Gemma's guidance in the UI instead of silently falling back, and exposes
copyable diagnostics if the agent fails.

## Wireless Physical Device Install

Use Cloudflare Tunnel so the phone can install the APK and the app can download
the Gemma 4 model over HTTPS without a cable:

```bash
cloudflared tunnel --url http://127.0.0.1:3333
PUBLIC_URL=https://your-trycloudflare-url ./scripts/wireless_installer.sh
```

Open the installer URL or scan the QR shown at `/qr.svg` from the Android phone.
The script builds a LiteRT-LM APK with `KAN_LITERT_MODEL_URL` and serves both
`zpk-litert.apk` and `gemma-4-E2B-it.litertlm`.

## Offline Agentic Flow

The default APK runs without a backend. The local agent performs CUI format validation, embedded catalog lookup, hash-verified civic threat-bulletin matching, identity-risk classification, privacy routing, DID-style credential issuance, Android device-presence-gated verifier-enforced allowlisted expiring authentication proof generation, signed recovery packet generation, signed revocation that blocks later auth proofs, encrypted local audit storage, and Spanish recovery guidance. Model modes must return a validated JSON agent response before guidance is shown. The app also shows a runtime panel for the offline agent so LiteRT Gemma model readiness, downloadability, native errors, and fallback state are visible before and after a case run. Gemma 4 is used only through redacted prompts.

## Verified Evidence

- Offline embedded catalog trace: `kan-app/kan-embedded-catalog-trace.png`
- Hosted Gemma 4 app trace: `kan-app/kan-gemma-hosted-trace.png`
- Cactus local inference trace: `kan-app/kan-cactus-270m-notools-trace.png`
- Cactus tool failure isolation: `kan-app/kan-cactus-270m-trace.png`
- ML Kit/AICore emulator result: `docs/evidence/mlkit-gemma-ondevice-2026-05-01.md`
- On-device Gemma 4 runtime plan: `docs/evidence/on-device-gemma4-runtime-plan-2026-05-01.md`
- LiteRT-LM offline Gemma 4 local smoke: `docs/evidence/litert-gemma4-offline-2026-05-01.md`
- LiteRT-LM app agent harness: `docs/evidence/litert-gemma4-app-agent-harness-2026-05-01.md`
- LiteRT-LM physical device runbook: `docs/evidence/litert-gemma4-physical-device-runbook-2026-05-01.md`
- Production readiness audit: `docs/evidence/production-readiness-audit-2026-05-01.md`
- LiteRT-LM Android bridge log: `docs/evidence/litert-gemma4-android-logcat-2026-05-01.txt`
- ZPK local trust fabric: `docs/evidence/zpk-local-trust-fabric-2026-05-01.md`
- Local authentication proof: `docs/evidence/local-authentication-proof-2026-05-01.md`
- Encrypted audit archive runtime evidence: `docs/evidence/local-audit-archive-2026-05-01.md`

Current verified gates:

- `dart format --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test` passes 74 tests
- `flutter build apk --release --split-per-abi`
- `./scripts/verify_release_build.sh` confirms release builds do not use the Android debug certificate
- GitHub Actions workflow `.github/workflows/android-ci.yml`

## Evidence Package

Build a local downloadable package for Kaggle evidence:

```bash
# Requires ZPK_RELEASE_* signing variables.
./scripts/package_demo.sh
```

The script rebuilds signed ARM64 release APKs for local mode and LiteRT mode, copies selected screenshots into `submission/live-demo/`, writes APK SHA-256 checksums, and creates a ZIP under `submission/dist/`. Set `LITERT_PUBLIC_URL=https://<trycloudflare-url>` before packaging if you want `zpk-litert-release.apk` to include a model download URL. The submission verifier checks that the APKs do not contain hosted Gemini key markers, that public APKs are not signed with the Android debug certificate, and that the ZIP does not contain `.env` or Gemini API key patterns.

Current verified package:

- `submission/dist/kan-demo-package-final.zip`
- `submission/live-demo/zpk-local-release.apk`
- `submission/live-demo/zpk-litert-release.apk`
- Verify with `./scripts/verify_submission.sh`

## Submission Handoff

Final copy/paste and upload files live in `submission/`:

- `submission/final-kaggle-writeup.md`: Kaggle writeup, under 1,500 words.
- `submission/KAGGLE_FORM.md`: final form fields and prize-claim guidance.
- `submission/YOUTUBE_DESCRIPTION.md`: video upload title, description, and tags.
- `submission/ARTIFACT_MANIFEST.md`: upload checklist and checksums.
- `submission/kan-final-demo-video.mp4`: narrated final video under 3 minutes.
- `SUBMIT_NOW.md`: shortest final manual submission handoff.

After authenticating externally:

```bash
gh auth login
./scripts/publish_submission.sh --check
./scripts/publish_submission.sh
```

Optional Kaggle Dataset upload staging:

```bash
KAGGLE_USERNAME=<your-kaggle-username> ./scripts/prepare_kaggle_dataset.sh
```

## Important Non-Claims

- The app does not use real breach data.
- It is not a deployed national identity system and does not integrate with the Guatemalan registry.
- It is not legal advice and does not guarantee legal correctness.
- Cactus tool-calling is not working yet; local Cactus inference works only with tools disabled.
- Gemma 4 evidence includes hosted Gemini API and offline LiteRT-LM local inference on the Mac, not Cactus.
- ML Kit/AICore mode is integrated and builds, but the Mac emulator reports the on-device GenAI feature as unavailable; do not claim verified ML Kit/AICore Gemma 4 generation yet.
- LiteRT-LM Gemma 4 E2B local inference is verified offline on the Mac after model download.
- LiteRT-LM Android is integrated in the Flutter APK. The Motorola G15 physical run installed the full Gemma 4 E2B model into app-private storage and now reports `DEVICE_LOW_MEMORY` plus `Respaldo offline disponible` instead of crashing because the phone has 3.86 GB RAM and the runtime requires 6 GB+ for safe generation; do not claim successful Android in-app Gemma 4 generation until a higher-RAM device produces `litert_gemma.generate(...) -> ok`.
- Gemma 4 adaptation artifacts include 12,000 validated synthetic Guatemala/LatAm SFT examples, 1,200 RLKD-style teacher traces, SFT LoRA/QLoRA and optional GRPO scripts, plus a failed one-step Gemma 4 E2B attempt on a 6 GB RTX 4050; no trained adapter exists yet.
- Runtime app signing uses Android Keystore through `DigitalIdentityFabric.device()`; deterministic Dart HMAC signing is used only for tests.
- Each recovery run emits a signed and locally verified SHA-256 hash-chain agent ledger so tool calls, credential issuance, consent, and reasoner routing are auditable without storing raw CUI.
- Recovery packets are split into a private local complaint with full CUI and a signed redacted share packet for institutions.
- App-internal audit receipts are sealed with AES-GCM using an Android Keystore key before storage.
- Android hardening blocks screenshots/screen recording, disables app backup/data extraction, and disallows cleartext traffic.

## Python Policy

If Python tooling is added, use a virtual environment. Prefer `uv venv` and `uv run`; never use system Python.
