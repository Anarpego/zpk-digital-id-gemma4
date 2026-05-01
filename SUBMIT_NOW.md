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

- Title: `Kan: Local-First Breach Defense for Guatemalan Citizens`
- Impact Track: `Digital Equity & Inclusivity`
- Writeup: paste `submission/final-kaggle-writeup.md`
- Video: upload or link `submission/kan-final-demo-video.mp4`
- Media cover: upload `submission/media-gallery-cover.png`
- Live demo URL: public URL for `kan-demo-package-final.zip` or the Kaggle Dataset
- Repository URL: public GitHub repository URL

## 4. Hashes To Confirm Uploads

- ZIP: see `submission/dist/kan-demo-package-final.zip.sha256`
- APK: `97f46a47ac06bbdd232e70e98cec6a7d03b4093ca7a43e38ebb391f63ce97138`
- Video: `42774441b15dd69af421c2f76d6e59b71203b4c27effb810b0b011da040bce34`
- Cover PNG: `3c1039c1843ee8763439b1be6fb27151056770e33f4f0e7e7a5d04f9ada16db3`

## 5. Prize Claims

Claim strongly:

- Main Track: working Android social-impact prototype.
- Impact Track: Digital Equity & Inclusivity.
- Local-first sensitive-data workflow with visible privacy traces.
- Hosted Gemma 4 evidence with `gemma-4-31b-it`.

Claim cautiously:

- Cactus: partial local-inference/routing evidence only.
- ML Kit/AICore: integration and fallback evidence only.

Do not claim:

- Successful offline/on-device Gemma 4 generation.
- Completed Unsloth adapter or RL fine-tune.
- Production legal advice.
