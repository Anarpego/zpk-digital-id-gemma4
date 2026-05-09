# Gemma 4 Good Final Submission Checklist

Use this checklist for the manual Kaggle submission. Do not submit from the
assistant session.

## Current Verified State

- Source commit: `31e82d8 feat: prepare offline Gemma identity app for Kaggle`.
- Final package: `submission/dist/kan-demo-package-final.zip`.
- Package SHA-256: see `submission/dist/kan-demo-package-final.zip.sha256`.
- Primary APK: `submission/live-demo/zpk-citizen-gemma4-release.apk`.
- Primary APK SHA-256: `7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb`.
- Physical-device proof: `docs/evidence/honor-release-citizen-gemma-final-2026-05-07.xml`.
- Current audit: `docs/evidence/goal-completion-audit-2026-05-07.md`.

## What To Claim

- Working Flutter Android app with citizen mode and local institutional
  ventanilla mode.
- Primary Gemma 4 proof: local Gemma 4 E2B through LiteRT-LM on an Honor
  Android release install.
- Agentic workflow: `redact_pii`, case classification, local Guatemala lookup,
  document drafting, safe close, and local `sign_packet`.
- Digital Equity & Inclusivity impact for Guatemala first, then Central America
  and Latin America.
- Safety & Trust angle: privacy guard, redacted packets, Android Keystore
  signing, revocation receipt, encrypted audit, and no raw CUI leaving the phone.
- Adaptation work: synthetic Guatemala/LatAm dataset, ReAct teacher traces,
  SFT/GRPO scripts, and reward code.

## What Not To Claim

- Real RENAP, IGSS, SAT, Ministerio Publico, bank, or telco integration.
- Production legal advice or certified legal templates.
- Completed Unsloth adapter weights or before/after benchmark.
- Cactus as the primary Gemma 4 implementation.
- ML Kit/AICore generation on the emulator.

## Local Gates

Run before uploading:

```bash
./scripts/verify_submission.sh
cd kan-app && flutter analyze
cd kan-app && flutter test
```

Expected current results:

- `verify_submission.sh`: pass.
- `flutter analyze`: no issues.
- `flutter test`: 142 tests passed.
- Video: 88 seconds.
- Cover: 1600x900.
- Writeup: 977 words, under the 1,500-word limit.

## Manual Kaggle Items

- Public repository URL, reachable without login.
- Public video URL, under 3 minutes.
- Live demo URL for the ZIP or Kaggle Dataset.
- Media gallery cover: `submission/media-gallery-cover.png`.
- Writeup text: `submission/final-kaggle-writeup.md`.
- Form fields: `submission/KAGGLE_FORM.md`.
