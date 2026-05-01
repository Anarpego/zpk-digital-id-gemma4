# Submission Audit

Date: 2026-05-01

Objective: make Kan competitive for the Gemma 4 Good Hackathon without spending time on deployment before the mobile demo and evidence are strong.

## Success Criteria and Evidence

| Requirement | Current Evidence | Status |
|---|---|---|
| Android-first working demo | `kan-app/`, APK builds, emulator screenshots `kan-smoke.png`, `kan-result.png`, `kan-gemma-hosted-trace.png` | Verified |
| Offline CUI check | `assets/breach_catalog.json`, `LocalBreachCatalog.loadEmbeddedOrFallback()`, 16 passing tests | Verified |
| Visible tool/function trace | UI shows local catalog load, local breach lookup, routing, template fill, Gemma API trace | Verified |
| Gemma 4 usage | `GemmaApiReasoner`, app-mode screenshot with `gemma-4-31b-it`, API smoke docs | Verified for hosted API |
| Cactus integration | `cactus ^1.3.0`, `CactusReasoner`, local inference screenshot with `functiongemma-270m`, fallback/tool-failure screenshots, model catalog doc | Partial: local inference works with tools disabled |
| Cactus prize readiness | Successful no-tools Cactus inference exists; tool-calling fails with code `-1`; quality is not demo-ready | Partial |
| Unsloth prize readiness | Seed dataset, eval cases, uv training scaffold, local dry-run, Linux GPU dry-run, remote CUDA/Unsloth import, and failed one-step Gemma 4 E2B training attempt exist; no adapter or before/after benchmark | Partial |
| Kaggle writeup under 1,500 words | `submission/final-kaggle-writeup.md`, 635 words, measured claims only | Ready locally |
| Public video under 3 minutes | final script/captions, narration text, narration audio, and rendered MP4 at `submission/kan-final-demo-video.mp4`; not uploaded publicly yet | Partial |
| Public code repo | Local Git repository exists; `.env`, APKs, build outputs, and `.venv` are ignored; no public remote yet | Partial |
| Live demo / downloadable files | `submission/dist/kan-demo-package-20260501T171844Z.zip` exists with APK, checksum, static demo page, screenshots, cover SVG, raw video, Unsloth scaffold/evidence, final writeup, and docs; not public yet | Partial |
| Media gallery cover image | Draft SVG exists at `submission/media-gallery-cover.svg`; not uploaded | Partial |

## Current Local Gates

- `cd kan-app && dart format --set-exit-if-changed lib test`: pass.
- `cd kan-app && flutter analyze`: pass.
- `cd kan-app && flutter test`: pass, 16 tests.
- `cd kan-app && flutter build apk --debug`: pass.

## Highest-Impact Next Steps

1. Capture a fresh default-mode emulator screenshot showing `load_breach_catalog(asset:assets/breach_catalog.json) -> ok`.
2. Improve Cactus output quality or decide to present Cactus as routing/metrics evidence only.
3. Move Unsloth training to a larger CUDA GPU and produce adapter plus before/after evaluation.
4. Publish the repo and upload the demo ZIP to a public no-login location.
5. Record the 3-minute video using only verified claims.
