# Kan App

Mobile-first ZPK Digital ID app for the Gemma 4 Good Hackathon project
described in `../kan.md`.

## What Works Now

- Citizen and institutional intake flows for IGSS, SAT, school/university,
  identity recovery, fraud, extortion evidence, field access, and prevention.
- Offline synthetic CUI verification, no-CUI institutional intake, local
  routing, redacted recovery packets, signed local evidence, and sealed audit.
- Gemma 4 reasoner adapters for hosted, iOS FlutterGemma, Android ML Kit/AICore,
  and Android LiteRT-LM paths, with deterministic offline fallback.
- Android LiteRT-LM status, model installation, SHA-256 verification, warmup,
  low-memory guard, and native-generation bridge.
- Copyable diagnostics and reproducible scripts for Kaggle evidence.
- Synthetic Guatemala/LatAm SFT and RLKD datasets under `../unsloth/`.

The app defaults to local-first privacy behavior. Hosted model calls are only
for redacted prompts; CUI/DPI and proof material stay on device. On the
available Motorola G15, the real Gemma 4 E2B LiteRT-LM model is installed in
app-private storage, but generation is blocked by the 6 GB RAM safety gate and
the app shows the deterministic offline fallback instead of crashing or making
an unsupported claim.

## Run Locally

```bash
flutter pub get
flutter run
```

Use `1234567890101` for an exposed synthetic CUI and `1111111111111` for a
valid CUI with no local match. Institution flows such as IGSS/SAT/Colegio can
also continue without CUI; they produce intake/checklists only, not identity
credentials.

## Verify

```bash
dart format lib test
flutter analyze
flutter test
```

## Physical Device Evidence

```bash
../scripts/verify_motorola_physical_flow.sh --no-install
../scripts/run_physical_litert_proof.sh --watch-seconds 300
```

`verify_motorola_physical_flow.sh` validates the current Motorola G15 flow:
Persona -> IGSS -> no-CUI institutional intake -> Motor low-memory fallback.
`run_physical_litert_proof.sh` is reserved for a future ARM64 Android phone with
6 GB+ RAM; only a `litert_gemma.generate(...) -> ok` trace counts as Android
physical Gemma 4 generation.
