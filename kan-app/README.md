# Kan App

Mobile-first prototype for the Gemma 4 Good Hackathon project described in `../kan.md`.

## What Works Now

- Offline synthetic CUI verification with no server call.
- Accessible Spanish guidance for exposed, unknown, and invalid CUI cases.
- Local complaint document preview generated on device.
- Visible local tool trace for the demo video and judging evidence.
- Cactus dependency and adapter boundary for local Gemma inference.
- Training-Free GRPO-style experience prior baked into the reasoner prompt.

This checkpoint intentionally defaults to deterministic local services instead of API calls or downloaded models. The Cactus adapter compiles, but model download/initialization is a separate benchmark step.

## Run Locally

```bash
flutter pub get
flutter run
```

Use `1234567890101` for an exposed synthetic CUI and `1111111111111` for a valid CUI with no local match.

## Verify

```bash
dart format lib test
flutter analyze
flutter test
```

## Next Integrations

1. Benchmark `CactusReasoner` with a Gemma 4 model on Android.
2. Move synthetic catalog data into a bundled SQLite asset.
3. Add an Unsloth fine-tuning dataset, notebook, and before/after benchmark.
4. Add optional server routing only for abstract legal reasoning with no CUI or PII.
