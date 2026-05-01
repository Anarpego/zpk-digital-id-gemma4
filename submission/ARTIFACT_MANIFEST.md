# Artifact Manifest

Date: 2026-05-01

Use this file to verify the local artifacts before uploading them to Kaggle, GitHub Releases, a Kaggle Dataset, or another public no-login location.

## Primary Uploads

| Artifact | Path | Purpose | SHA-256 |
|---|---|---|---|
| Android APK | `submission/live-demo/kan-debug.apk` | Installable local-mode demo APK | `7b164de2b62af2130f21dcae29d3ba85c7dcb71446242d81bf8755494c164f3b` |
| Final video | `submission/kan-final-demo-video.mp4` | Public media-gallery video, under 3 minutes | `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6` |
| Media cover | `submission/media-gallery-cover.png` | 1600x900 Kaggle media-gallery image | `15ba1a8f5037973ce6b0c76defdfd05bee438d2f8ddf15393cc75070e4a6f2b6` |
| Demo package | `submission/dist/kan-demo-package-final.zip` | Downloadable bundle with APK, video, docs, evidence, and Unsloth scaffold | See `submission/dist/kan-demo-package-final.zip.sha256` |

## Kaggle Form Inputs

- Repository URL: fill in after public GitHub push.
- Live demo URL: fill in after uploading `submission/dist/kan-demo-package-final.zip`.
- Video URL: fill in after uploading `submission/kan-final-demo-video.mp4`.
- Kaggle form copy: `submission/KAGGLE_FORM.md`.
- YouTube upload copy: `submission/YOUTUBE_DESCRIPTION.md`.
- GitHub release notes: `submission/GITHUB_RELEASE_NOTES.md`.
- Kaggle Dataset metadata template: `submission/kaggle-dataset-metadata.template.json`.
- Kaggle Dataset README: `submission/KAGGLE_DATASET_README.md`.
- Media gallery cover: `submission/media-gallery-cover.png`.
- Impact Track: Digital Equity & Inclusivity.
- Special prizes: claim Cactus cautiously; claim only ML Kit/AICore integration/fallback unless a supported device verifies local generation; do not claim Unsloth unless a larger-GPU adapter and before/after benchmark are added.

## Final Local Verification

```bash
git status --short
git status --ignored --short | rg "\\.env|submission/dist|submission/live-demo/kan-debug|unsloth/.venv"
shasum -a 256 submission/live-demo/kan-debug.apk submission/kan-final-demo-video.mp4 submission/media-gallery-cover.png
shasum -a 256 -c submission/dist/kan-demo-package-final.zip.sha256
unzip -l submission/dist/kan-demo-package-final.zip | rg "\\.env|kan-final-demo-video|training_attempt|kan-debug.apk"
./scripts/verify_submission.sh
./scripts/publish_submission.sh --check
KAGGLE_USERNAME=<your-kaggle-username> ./scripts/prepare_kaggle_dataset.sh
uvx kaggle datasets create -p submission/kaggle-dataset-upload --dir-mode zip
```

Expected:

- Git working tree is clean.
- `.env`, generated ZIPs, APKs, and `.venv` are ignored.
- The archive contains `.env.example` but not `.env`.
- The video is under 180 seconds.
- The media cover is 1600x900.
