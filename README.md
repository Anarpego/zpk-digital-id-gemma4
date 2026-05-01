# ZPK Digital ID

ZPK Digital ID is a local-first Android prototype for the Gemma 4 Good Hackathon. It registers a citizen into a privacy-preserving identity wallet, issues a pseudonymous local credential, checks a synthetic offline CUI risk catalog, and prepares recovery guidance without sending raw CUI to the cloud.

This repository is optimized for hackathon evidence, not production deployment. It intentionally avoids real personal data.

## Current Prototype

- Flutter app: `kan-app/`
- Embedded synthetic breach catalog: `kan-app/assets/breach_catalog.json`
- Local ZPK trust fabric: HMAC-derived pseudonymous ID, DID-style document, Android Keystore-backed HMAC-SHA256 recovery credential, selective disclosure claims, and 15-minute consent proof.
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

ML Kit/AICore on-device mode, verified to build and to fail closed on the Mac emulator:

```bash
cd kan-app
flutter run \
  --dart-define=KAN_REASONER=mlkit-gemma \
  --dart-define=KAN_MLKIT_TIMEOUT_SECONDS=120
```

This mode uses Android ML Kit Prompt API. It needs a supported AICore device for actual on-device Gemma/Gemini Nano generation; the available emulator reports `UNAVAILABLE` and the app falls back locally with a visible trace.

## Verified Evidence

- Offline embedded catalog trace: `kan-app/kan-embedded-catalog-trace.png`
- Hosted Gemma 4 app trace: `kan-app/kan-gemma-hosted-trace.png`
- Cactus local inference trace: `kan-app/kan-cactus-270m-notools-trace.png`
- Cactus tool failure isolation: `kan-app/kan-cactus-270m-trace.png`
- ML Kit/AICore emulator result: `docs/evidence/mlkit-gemma-ondevice-2026-05-01.md`
- ZPK local trust fabric: `docs/evidence/zpk-local-trust-fabric-2026-05-01.md`

Current verified gates:

- `dart format --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test` passes 20 tests
- `flutter build apk --debug`

## Demo Package

Build a local downloadable package for Kaggle live-demo evidence:

```bash
./scripts/package_demo.sh
```

The script rebuilds the default local-mode APK, copies selected screenshots into `submission/live-demo/`, writes an APK SHA-256 checksum, and creates a ZIP under `submission/dist/`. It does not embed hosted API keys.

Current verified package:

- `submission/dist/kan-demo-package-final.zip`
- Verify with `./scripts/verify_submission.sh`

## Submission Handoff

Final copy/paste and upload files live in `submission/`:

- `submission/final-kaggle-writeup.md`: Kaggle writeup, 695 words.
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
- It is not legal advice and does not guarantee legal correctness.
- Cactus tool-calling is not working yet; local Cactus inference works only with tools disabled.
- Gemma 4 evidence is currently hosted through the Gemini API, not Cactus.
- ML Kit/AICore mode is integrated and builds, but the Mac emulator reports the on-device GenAI feature as unavailable; do not claim verified offline Gemma 4 generation yet.
- Unsloth artifacts include a scaffold and failed one-step Gemma 4 E2B attempt on a 6 GB RTX 4050; no trained adapter exists yet.
- Runtime app signing uses Android Keystore through `DigitalIdentityFabric.device()`; deterministic Dart HMAC signing is used only for tests.

## Python Policy

If Python tooling is added, use a virtual environment. Prefer `uv venv` and `uv run`; never use system Python.
