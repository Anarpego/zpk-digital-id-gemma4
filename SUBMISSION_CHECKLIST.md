# Gemma 4 Good Submission Checklist

## Verified In This Workspace

- Flutter prototype exists at `kan-app/`.
- Offline synthetic CUI verification works with `1234567890101`.
- Offline breach fixtures are bundled in `kan-app/assets/breach_catalog.json` and loaded by `LocalBreachCatalog.loadEmbeddedOrFallback()`.
- Local Spanish guidance and complaint preview are generated without a server.
- Tool trace is visible in the Android UI for function-calling evidence.
- Cactus Flutter dependency is present (`cactus ^1.3.0`) and a `CactusReasoner` adapter compiles behind the mock default.
- Runtime reasoner selection exists through `--dart-define=KAN_REASONER=mock|cactus|gemma-hosted`, `KAN_CACTUS_MODEL=<slug>`, and `KAN_GEMINI_MODEL=<model>`.
- Hosted Gemma 4 app mode exists through `--dart-define=KAN_REASONER=gemma-hosted`, `KAN_GEMINI_API_KEY`, and `KAN_GEMINI_MODEL=gemma-4-31b-it`.
- Cactus telemetry is disabled in `ReasonerFactory` for privacy.
- Cactus model catalog check is documented in `docs/cactus-model-catalog-2026-05-01.md`; current Cactus catalog has FunctionGemma/Gemma 3 entries but no verified Gemma 4 slug.
- Real hosted Gemma 4 API smoke evidence exists in `docs/evidence/gemma4-api-smoke-2026-05-01.md` using `gemma-4-31b-it`.
- Gemini API model-list evidence exists in `docs/evidence/gemini-api-model-list-2026-05-01.md` and includes `gemma-4-26b-a4b-it` plus `gemma-4-31b-it`.
- Training-Free GRPO-style experience prior is encoded in `ReasonerPromptBuilder` and surfaced in local traces.
- Local-tools-vs-local-model-vs-abstract-server routing is implemented in `RoutingPolicy`, shown in the UI, and covered by tests.
- Android debug APK builds at `kan-app/build/app/outputs/flutter-apk/app-debug.apk`.
- Emulator smoke test launched `gt.kan.kan_app` and captured:
  - `kan-app/kan-smoke.png`
  - `kan-app/kan-result.png`
  - `kan-app/kan-embedded-catalog-trace.png`
- Cactus-mode fallback smoke test launched on emulator and captured:
  - `kan-app/kan-cactus-mode.png`
  - `kan-app/kan-cactus-fallback-fixed-2.png`
  - `kan-app/kan-cactus-fallback-trace.png`
- Cactus local-inference smoke test launched on emulator with tools disabled and captured:
  - `kan-app/kan-cactus-270m-notools-after45.png`
  - `kan-app/kan-cactus-270m-notools-trace.png`
  - Trace shows `reasoner_mode(cactus:functiongemma-270m) -> ok`, `cactus.generateCompletion(local, functiongemma-270m) -> ok`, TTFT `926ms`, total `993ms`, `60.4 tok/s`.
- Cactus tool-calling isolation run captured:
  - `kan-app/kan-cactus-270m-trace.png`
  - Trace shows tools enabled failed with `completion failed with code -1`.
- Hosted Gemma 4 app-mode smoke test launched on emulator and captured:
  - `kan-app/kan-gemma-hosted-later.png`
  - `kan-app/kan-gemma-hosted-trace.png`
  - Trace shows `reasoner_mode(gemma-api:gemma-4-31b-it) -> ok` and token accounting.
- Draft submission artifacts exist:
  - `submission/ARTIFACT_MANIFEST.md`
  - `submission/KAGGLE_FORM.md`
  - `submission/YOUTUBE_DESCRIPTION.md`
  - `submission/kaggle-writeup-draft.md` (699 words, under 1,500)
  - `submission/final-kaggle-writeup.md` (635 words, under 1,500)
  - `submission/video-script-draft.md`
  - `submission/final-video-script.md`
  - `submission/final-video-captions.srt`
  - `submission/demo-runbook.md`
  - `submission/media-gallery-cover.svg`
  - `submission/prize-claims.md`
  - `submission/publish-runbook.md`
- Raw video footage exists:
  - `submission/video-raw/kan-demo-flow.mp4`
  - `submission/video-raw/README.md`
- Final rendered video exists locally:
  - `submission/kan-final-demo-video.mp4`
  - Duration: about 1:43, under the 3-minute limit.
  - Includes narrated audio generated from `submission/final-video-narration.txt`.
  - Evidence: `docs/evidence/final-video-2026-05-01.md`
- Root public-repo README exists:
  - `README.md`
- Repo safety and package files exist:
  - `.gitignore`
  - `.env.example`
  - `LICENSE`
  - `scripts/package_demo.sh`
  - `scripts/verify_submission.sh`
- Local downloadable demo package exists:
  - `submission/dist/kan-demo-package-20260501T172529Z.zip`
  - `submission/live-demo/kan-debug.apk`
  - `submission/live-demo/kan-debug.apk.sha256`
  - `submission/live-demo/index.html`
- Unsloth seed artifacts exist but are not trained:
  - `unsloth/kan_legal_spanish_sft.jsonl`
  - `unsloth/eval_cases.jsonl`
  - `unsloth/README.md`
  - `unsloth/train_lora.py`
  - `unsloth/pyproject.toml`
  - `unsloth/outputs/dry_run_report.md`
- Unsloth scaffold evidence exists:
  - `docs/evidence/unsloth-scaffold-2026-05-01.md`
- Remote Unsloth training stack smoke passed in `/tmp/kan-unsloth-venv` on the Linux GPU box:
  - `unsloth-2026.4.8`
  - `torch-2.10.0+cu128`
  - `transformers-5.5.0`
  - CUDA detected `NVIDIA GeForce RTX 4050 Laptop GPU`
  - Unsloth import passed, with Xformers fallback because Flash Attention 2 was broken.
- Remote Unsloth one-step training attempt reached model download, weight load, and dataset tokenization, then failed with CUDA OOM on the 6 GB RTX 4050:
  - `unsloth/outputs/training_attempt_2026-05-01.md`

## Local Gates

- `cd kan-app && dart format --set-exit-if-changed lib test`: pass.
- `cd kan-app && flutter analyze`: pass.
- `cd kan-app && flutter test`: pass, 16 tests.
- `cd kan-app && flutter build apk --debug`: pass.
- `cd kan-app && flutter build apk --debug --dart-define=KAN_REASONER=cactus --dart-define=KAN_CACTUS_MODEL=functiongemma-270m-pro --dart-define=KAN_CACTUS_TIMEOUT_SECONDS=5`: pass.
- `cd kan-app && flutter build apk --debug --dart-define=KAN_REASONER=cactus --dart-define=KAN_CACTUS_MODEL=functiongemma-270m --dart-define=KAN_CACTUS_ENABLE_TOOLS=false --dart-define=KAN_CACTUS_TIMEOUT_SECONDS=180`: pass.
- `cd kan-app && flutter build apk --debug --dart-define=KAN_REASONER=gemma-hosted --dart-define=KAN_GEMINI_MODEL=gemma-4-31b-it`: pass.
- `/bin/zsh -lc 'set -a; source ../.env; set +a; flutter build apk --debug --dart-define=KAN_REASONER=gemma-hosted --dart-define=KAN_GEMINI_MODEL=gemma-4-31b-it --dart-define=KAN_GEMINI_API_KEY="$GEMINI_API_KEY"'`: pass for local testing only; do not publish an APK with an embedded API key.
- `cd kan-app && flutter pub outdated`: direct and dev dependencies are up to date; older versions are transitive constraints from packages.
- `/bin/zsh -lc 'set -a; source .env; set +a; curl ... models/gemma-4-31b-it:generateContent'`: pass; returned `modelVersion: gemma-4-31b-it`.
- `./scripts/gemma4_smoke.sh <prompt>`: pass; repeatable hosted Gemma 4 smoke path works when network is allowed.
- `./scripts/package_demo.sh`: pass; generated `submission/dist/kan-demo-package-20260501T172529Z.zip`.
- `./scripts/verify_submission.sh`: pass; verified APK/video checksums, ZIP contents, no `.env`, and writeup length.
- `cd unsloth && uv run python train_lora.py --dry-run`: pass; generated `unsloth/outputs/dry_run_report.md`.
- Remote Linux GPU dry-run in `/tmp/kan-unsloth-venv`: pass; RTX 4050 Laptop GPU with 6,141 MiB VRAM detected.
- Remote Linux GPU Unsloth dependency install and import smoke in `/tmp/kan-unsloth-venv`: pass; CUDA available.
- Remote Linux GPU one-step Unsloth training smoke: failed with CUDA OOM after model load and dataset tokenization.

## Competition Deliverables Still Missing

- Public code repository. A local Git repository now exists with publish-ready hygiene files, but it has not been pushed to a public remote.
- Final Kaggle writeup upload. `submission/final-kaggle-writeup.md` exists under 1,500 words with measured Gemma/Cactus evidence, but it has not been pasted/submitted to Kaggle.
- Public video, maximum 3 minutes, recorded and attached to the media gallery. A final narrated MP4 exists locally, but it has not been uploaded to a public URL or attached to Kaggle yet.
- Final media gallery cover upload. A draft SVG cover now exists locally but has not been uploaded.
- Final selected competition track and prize claims. `submission/prize-claims.md` exists; selected Impact Track is Digital Equity & Inclusivity, but claims have not been entered in Kaggle.
- Stronger Cactus prize evidence. Local inference now works with `functiongemma-270m` and tools disabled, but Cactus tool-calling still fails with code `-1`, and this is not Gemma 4 evidence.
- Decision on whether Cactus local-routing evidence is enough for a technical prize if Gemma 4 is served through Google AI Studio instead.
- Unsloth adapter and before-after benchmark, if targeting the Unsloth prize. The scaffold now reaches Gemma 4 E2B load/tokenization, but the available 6 GB RTX 4050 fails with CUDA OOM before step 1.
- Public live demo URL. A downloadable demo ZIP now exists locally, but it has not been uploaded anywhere public.

## Next Build Priorities

1. Publish the GitHub repository after authenticating `gh`.
2. Upload the demo ZIP and final video to public no-login URLs.
3. Paste `submission/final-kaggle-writeup.md` into Kaggle and attach the media/gallery assets.
4. Move Unsloth training to a larger GPU if pursuing that special prize.
