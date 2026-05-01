# Kan: Local-First Breach Defense for Guatemalan Citizens

**Selected Impact Track: Digital Equity & Inclusivity**

When personal data leaks in Guatemala, the hardest question for many citizens is not technical. It is: am I affected, what does this mean, and what can I do today? Kan is an Android-first assistant for that moment. It checks a local breach catalog, explains risk in plain Spanish, and prepares a preliminary complaint document without sending the user's CUI to a server.

Kan focuses on one story: a citizen discovers that their DPI/CUI may have been exposed after interacting with an institution or fake aid program. The app turns breach response into three steps: detect, explain, act.

## How Kan Uses Gemma 4

Kan combines local-first privacy with verified Gemma 4 reasoning. The current app has four reasoner modes:

1. Deterministic local mode for reliable offline demos and tests.
2. Cactus local mode for on-device model routing and local inference metrics.
3. Hosted Gemma 4 mode through the Gemini API using `gemma-4-31b-it`.
4. ML Kit/AICore mode for the official Android on-device Prompt API path.

The hosted Gemma 4 path is verified in the Android app. The trace screenshot shows `reasoner_mode(gemma-api:gemma-4-31b-it) -> ok`, `gemma_api.generateContent(gemma-4-31b-it) -> ok`, and token accounting. The separate API smoke test returned model version `gemma-4-31b-it`.

The ML Kit/AICore path now compiles and runs on the Mac Android emulator, but the emulator reports the GenAI feature as `UNAVAILABLE`. Kan records that failure and falls back locally, so I do not claim verified offline Gemma 4 generation without a supported AICore device.

Kan does not send raw CUI to hosted reasoning by default. The mobile routing policy records whether a task uses local tools, a local model, or an abstract no-PII server route. This makes privacy visible instead of burying it in a policy page.

## Local-First Architecture

The demo APK bundles `assets/breach_catalog.json`, a synthetic offline breach catalog with no real personal data. `LocalBreachCatalog.loadEmbeddedOrFallback()` loads this asset on device. The UI trace shows:

- `load_breach_catalog(asset:assets/breach_catalog.json) -> ok`
- `verify_dpi_in_local_leaks(local) -> 1 coincidencias`
- `routing_decision(local_model) -> confidence 92%, pii no`
- `fill_legal_template(local) -> ready`

After a synthetic match, Kan generates Spanish guidance and a preliminary complaint document locally. The app can be installed from the demo package and run without a backend.

## Cactus Evidence

Kan integrates the Cactus Flutter SDK and disables Cactus telemetry in `ReasonerFactory`. A Cactus emulator run with `functiongemma-270m` and tools disabled succeeded locally. The trace shows `reasoner_mode(cactus:functiongemma-270m) -> ok`, `cactus.generateCompletion(local, functiongemma-270m) -> ok`, TTFT `926ms`, total `993ms`, and `60.4 tok/s`.

This is useful Cactus routing evidence, but I am not overstating it: Cactus tool-calling currently fails with `completion failed with code -1`, and the small local model's answer quality is not yet suitable for the main user-facing demo. Gemma 4 evidence is therefore presented separately through the hosted `gemma-4-31b-it` app mode.

## Adaptation

Kan uses a Training-Free GRPO-style experience prior inspired by `arXiv:2510.08191`. The prior teaches three rules: verify locally before requesting data, separate plain explanation from legal steps, and fill documents only on device. This gives a cheap improvement loop before fine-tuning.

Unsloth artifacts are prepared but not claimed as a trained result yet: a ShareGPT-style SFT seed dataset, evaluation cases, a `uv`-based training scaffold, and a dry-run report. A future run will train a Gemma 4 legal-Spanish adapter and compare before/after scores.

## Impact

Kan targets Digital Equity & Inclusivity because it reduces a complex legal and cybersecurity process to a clear Spanish-first mobile flow. The target user does not need to understand breach databases, LLMs, or legal forms. They see whether a synthetic local match exists, receive simple next steps, and leave with a complaint draft.

The strongest current claim is not that Kan is production legal infrastructure. It is that a privacy-preserving, Android-first breach response assistant can make advanced Gemma 4 reasoning useful to people who normally receive neither AI support nor legal clarity.

## Reproducibility

The repository includes the Flutter app, synthetic catalog, tests, evidence screenshots, demo package script, Gemma 4 smoke script, ML Kit/AICore path, and Unsloth scaffold. Current local gates pass: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` with 17 tests, and `flutter build apk --debug`.
