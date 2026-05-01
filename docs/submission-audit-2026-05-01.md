# Submission Audit

Date: 2026-05-01

Objective: make ZPK Digital ID competitive for the Gemma 4 Good Hackathon, prioritize winning over the original `kan.md` implementation details, do not deploy from this workspace, and verify that the mobile demo, evidence, and submission assets are ready for public upload.

## Prompt-To-Artifact Checklist

| Requirement | Evidence | Status |
|---|---|---|
| Working Android demo | `kan-app/`, `submission/live-demo/kan-debug.apk`, `flutter build apk --debug` | Verified locally |
| Offline/local-first identity registration | `DigitalIdentityFabric`, `IdentityProtectionAgent`, DID-style document, Android Keystore-backed HMAC-SHA256 credential, signed agent ledger, selective disclosure claims, consent proof | Verified locally |
| Android privacy hardening | `FLAG_SECURE`, backup/data-extraction exclusions, cleartext traffic disabled | Built and manifest-inspected locally |
| Offline/local-first CUI risk check | `kan-app/assets/breach_catalog.json`, `LocalBreachCatalog.loadEmbeddedOrFallback()`, ZPK final video | Verified locally |
| Spanish guidance and complaint/recovery draft | Flutter app flow, `LegalTemplateService`, final video | Verified locally |
| Visible privacy/tool trace | UI traces for agent planning, CUI validation, local risk lookup, privacy route, HMAC credential signing/verification, consent proof, Gemma API, and Cactus mode | Verified locally |
| Gemma 4 usage | `GemmaApiReasoner`, `docs/evidence/gemma4-api-smoke-2026-05-01.md`, screenshot `kan-gemma-hosted-trace.png` | Verified for hosted `gemma-4-31b-it` |
| Cactus integration | `cactus ^1.3.0`, `CactusReasoner`, `docs/evidence/cactus-local-inference-2026-05-01.md` | Partial: local inference works, tool-calling fails |
| Unsloth readiness | `unsloth/train_lora.py`, dry-run report, CUDA import smoke, `unsloth/outputs/training_attempt_2026-05-01.md` | Partial: no adapter; 6 GB GPU OOM |
| Training-Free GRPO-style prior | `ReasonerPromptBuilder`, `docs/routing-calibration.md`, writeup adaptation section | Verified as prompt/experience prior |
| Public writeup under 1,500 words | `submission/final-kaggle-writeup.md`, `wc -w` = 689 | Ready locally |
| Public video under 3 minutes | `submission/kan-final-demo-video.mp4`, `docs/evidence/final-video-2026-05-01.md` | Ready locally, not uploaded |
| Public code repository | Git repo with clean status, `.gitignore`, `README.md`, `AGENTS.md`, `LICENSE` | Blocked: no remote and `gh` is not logged in |
| Public demo files | `submission/dist/kan-demo-package-final.zip`, static live-demo page, APK, checksums | Ready locally, not uploaded |
| Media gallery assets | `submission/media-gallery-cover.svg`, final video, screenshots | Ready locally, not uploaded |
| No secret leakage | `.env` ignored; verifier checks ZIP has `.env.example` and not `.env` | Verified locally |
| Python best practice | Unsloth uses `uv`/venv paths; no system Python needed for project checks | Verified locally |
| Latest practical libraries | Flutter deps checked; Unsloth stack installed as latest available on remote venv | Verified locally/remotely |
| Mac emulator preference | Android evidence captured from Mac-hosted emulator; no emulator currently attached | Verified |
| Linux resource use | Remote RTX 4050 used for Unsloth dependency/import/training attempt | Verified |
| Post-quantum note | Mentioned as future trust segment, not a blocker or unsupported claim | Ready as future-facing note |

## Verification Commands

```bash
git status --short
./scripts/verify_submission.sh
git status --ignored --short | rg "\.env|submission/dist|submission/live-demo/kan-debug|unsloth/.venv"
adb devices
```

Latest observed results:

- Git working tree: clean.
- Submission verifier: pass.
- Ignored secrets/generated files: `.env`, `submission/dist/`, generated APK/checksum, and `unsloth/.venv/`.
- Android devices: none attached.

## Remaining External Blockers

- Run `gh auth login`.
- Create and push a public repository.
- Upload `submission/dist/kan-demo-package-final.zip` to a public no-login URL.
- Upload `submission/kan-final-demo-video.mp4` to a public video URL.
- Submit the Kaggle form using `submission/KAGGLE_FORM.md`, `submission/final-kaggle-writeup.md`, and `submission/YOUTUBE_DESCRIPTION.md`.
- Use `submission/prize-claims.md`: claim Main Track and Digital Equity; claim Cactus only cautiously; do not claim Unsloth unless a larger GPU produces an adapter and before/after benchmark.

Conclusion: the local submission package is ready, but the competition submission is not complete until the public repo, public demo URL, public video URL, and Kaggle form are created.
