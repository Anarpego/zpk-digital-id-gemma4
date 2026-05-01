# Artifact Manifest

Date: 2026-05-01

Use this file to verify the local artifacts before uploading them to Kaggle, GitHub Releases, a Kaggle Dataset, or another public no-login location.

## Primary Uploads

| Artifact | Path | Purpose | SHA-256 |
|---|---|---|---|
| Android APK | `submission/live-demo/kan-debug.apk` | Installable local-mode demo APK | `0e1010be2a9a850a2e694140156c32e7feb333254a0f061474100c5e20fdb8bb` |
| Final video | `submission/kan-final-demo-video.mp4` | Public media-gallery video, under 3 minutes | `42774441b15dd69af421c2f76d6e59b71203b4c27effb810b0b011da040bce34` |
| Demo package | `submission/dist/kan-demo-package-20260501T172529Z.zip` | Downloadable bundle with APK, video, docs, evidence, and Unsloth scaffold | Generate with `shasum -a 256 submission/dist/kan-demo-package-20260501T172529Z.zip` |

## Kaggle Form Inputs

- Repository URL: fill in after public GitHub push.
- Live demo URL: fill in after uploading `submission/dist/kan-demo-package-20260501T172529Z.zip`.
- Video URL: fill in after uploading `submission/kan-final-demo-video.mp4`.
- Kaggle form copy: `submission/KAGGLE_FORM.md`.
- YouTube upload copy: `submission/YOUTUBE_DESCRIPTION.md`.
- Impact Track: Digital Equity & Inclusivity.
- Special prizes: claim Cactus cautiously; do not claim Unsloth unless a larger-GPU adapter and before/after benchmark are added.

## Final Local Verification

```bash
git status --short
git status --ignored --short | rg "\\.env|submission/dist|submission/live-demo/kan-debug|unsloth/.venv"
shasum -a 256 submission/live-demo/kan-debug.apk submission/kan-final-demo-video.mp4
unzip -l submission/dist/kan-demo-package-20260501T172529Z.zip | rg "\\.env|kan-final-demo-video|training_attempt|kan-debug.apk"
./scripts/verify_submission.sh
```

Expected:

- Git working tree is clean.
- `.env`, generated ZIPs, APKs, and `.venv` are ignored.
- The archive contains `.env.example` but not `.env`.
