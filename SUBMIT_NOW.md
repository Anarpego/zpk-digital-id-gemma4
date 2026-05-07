# Submit Now

Use this one-page handoff for the final manual Kaggle submission.

## 1. Verify Local Artifacts

```bash
./scripts/verify_submission.sh
./scripts/publish_submission.sh --check
```

Expected: artifact verification passes. `publish_submission.sh --check` stops only if GitHub CLI is not authenticated.

## 2. Public Repository And Release

After account login:

```bash
gh auth login
./scripts/publish_submission.sh
```

Release assets uploaded by the script:

- `submission/dist/kan-demo-package-final.zip`
- `submission/dist/kan-demo-package-final.zip.sha256`
- `submission/live-demo/zpk-citizen-gemma4-release.apk`
- `submission/live-demo/zpk-citizen-gemma4-release.apk.sha256`
- `submission/kan-final-demo-video.mp4`
- `submission/media-gallery-cover.png`

The script uses the local tag `v2026.05.07-kaggle`.

Alternative live demo upload:

```bash
KAGGLE_USERNAME=<your-kaggle-username> ./scripts/prepare_kaggle_dataset.sh
uvx kaggle datasets create -p submission/kaggle-dataset-upload --dir-mode zip
```

## 3. Kaggle Form Fields

Copy fields from `submission/KAGGLE_FORM.md`.

- Title: `ZPK Digital ID: Local-First Identity Protection for Guatemala`
- Impact Track: `Digital Equity & Inclusivity`
- Writeup: paste `submission/final-kaggle-writeup.md`
- Video: upload or link `submission/kan-final-demo-video.mp4`
- Media cover: upload `submission/media-gallery-cover.png`
- Live demo URL: public URL for `kan-demo-package-final.zip` or the Kaggle Dataset
- Repository URL: public GitHub repository URL

## 4. Hashes To Confirm Uploads

- ZIP: see `submission/dist/kan-demo-package-final.zip.sha256`
- Primary citizen APK: see `submission/live-demo/zpk-citizen-gemma4-release.apk.sha256`
- Local fallback APK: see `submission/live-demo/zpk-local-release.apk.sha256`
- Video: `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6`
- Cover PNG: `bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947`

## 5. Prize Claims

Claim strongly:

- Main Track: working Android social-impact app with citizen and ventanilla views.
- Impact Track: Digital Equity & Inclusivity.
- Primary Gemma 4 claim: Honor Android physical-device release proof with local Gemma 4 E2B through LiteRT-LM.
- Agentic ReAct flow: `redact_pii`, case classification, local lookup, document drafting, safe close, and `sign_packet`.
- Local-first ZPK identity registration, selective disclosure, signed recovery workflow, redacted institutional packet, encrypted local audit archive, and signed local revocation.
- APK integrity: submitted citizen APK and installed Honor `base.apk` both hash to `7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb`.

Claim cautiously:

- Cactus: partial local-inference/routing evidence only.
- ML Kit/AICore: integration and fallback evidence only on the available emulator.
- Mac/iOS LiteRT/FlutterGemma and Motorola G15 low-memory evidence: supporting engineering context only.
- Unsloth/adaptation: synthetic dataset, ReAct teacher traces, SFT/GRPO scripts, and reward code only.

Do not claim:

- Completed Unsloth adapter or RL fine-tune.
- Real government integration, hardware-backed key custody on every possible citizen device, or standards certification.
- Production legal advice.
