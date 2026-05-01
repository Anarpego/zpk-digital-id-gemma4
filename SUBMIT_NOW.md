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
- `submission/kan-final-demo-video.mp4`
- `submission/media-gallery-cover.png`

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
- APK: see `submission/live-demo/kan-debug.apk.sha256`
- Video: `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6`
- Cover PNG: `15ba1a8f5037973ce6b0c76defdfd05bee438d2f8ddf15393cc75070e4a6f2b6`

## 5. Prize Claims

Claim strongly:

- Main Track: working Android social-impact prototype.
- Impact Track: Digital Equity & Inclusivity.
- Local-first ZPK identity registration, selective disclosure, and recovery workflow.
- Visible privacy/tool traces for DID-style credential, consent proof, and redacted institutional packet.
- Hosted Gemma 4 evidence with `gemma-4-31b-it`.

Claim cautiously:

- Cactus: partial local-inference/routing evidence only.
- ML Kit/AICore: integration and fallback evidence only.

Do not claim:

- Successful offline/on-device Gemma 4 generation.
- Completed Unsloth adapter or RL fine-tune.
- Real government integration, hardware-backed key custody, or standards certification.
- Production legal advice.
