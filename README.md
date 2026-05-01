# Kan

Kan is a local-first Android prototype for the Gemma 4 Good Hackathon. It helps Guatemalan citizens respond to data breaches by checking a synthetic offline CUI catalog, explaining risk in plain Spanish, and generating a preliminary complaint document on device.

This repository is optimized for hackathon evidence, not production deployment. It intentionally avoids real personal data.

## Current Prototype

- Flutter app: `kan-app/`
- Embedded synthetic breach catalog: `kan-app/assets/breach_catalog.json`
- Evidence docs: `docs/evidence/`
- Submission drafts: `submission/`
- Unsloth seed data: `unsloth/`

## Quick Start

```bash
cd kan-app
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

Use synthetic CUI `1234567890101` for the main demo flow.

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

## Verified Evidence

- Offline embedded catalog trace: `kan-app/kan-embedded-catalog-trace.png`
- Hosted Gemma 4 app trace: `kan-app/kan-gemma-hosted-trace.png`
- Cactus local inference trace: `kan-app/kan-cactus-270m-notools-trace.png`
- Cactus tool failure isolation: `kan-app/kan-cactus-270m-trace.png`

Current verified gates:

- `dart format --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test` passes 16 tests
- `flutter build apk --debug`

## Demo Package

Build a local downloadable package for Kaggle live-demo evidence:

```bash
./scripts/package_demo.sh
```

The script rebuilds the default local-mode APK, copies selected screenshots into `submission/live-demo/`, writes an APK SHA-256 checksum, and creates a ZIP under `submission/dist/`. It does not embed hosted API keys.

## Important Non-Claims

- The app does not use real breach data.
- It is not legal advice and does not guarantee legal correctness.
- Cactus tool-calling is not working yet; local Cactus inference works only with tools disabled.
- Gemma 4 evidence is currently hosted through the Gemini API, not Cactus.
- Unsloth artifacts are seed data only; no trained adapter exists yet.

## Python Policy

If Python tooling is added, use a virtual environment. Prefer `uv venv` and `uv run`; never use system Python.
