# Artifact Manifest

Date: 2026-05-07

Use this file to verify the local artifacts before uploading them to Kaggle, GitHub Releases, a Kaggle Dataset, or another public no-login location.

## Primary Uploads

| Artifact | Path | Purpose | SHA-256 |
|---|---|---|---|
| Local APK | `submission/live-demo/zpk-local-release.apk` | Signed ARM64 local-mode Android APK | See `submission/live-demo/zpk-local-release.apk.sha256` |
| LiteRT APK | `submission/live-demo/zpk-litert-release.apk` | Signed ARM64 LiteRT-mode APK for physical-device Gemma testing | See `submission/live-demo/zpk-litert-release.apk.sha256` |
| Citizen Gemma APK | `submission/live-demo/zpk-citizen-gemma4-release.apk` | Signed ARM64 citizen-mode APK with Gemma 4 ReAct home screen and Modo Ventanilla | See `submission/live-demo/zpk-citizen-gemma4-release.apk.sha256` |
| Final video | `submission/kan-final-demo-video.mp4` | Public media-gallery video, under 3 minutes | `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6` |
| Media cover | `submission/media-gallery-cover.png` | 1600x900 Kaggle media-gallery image | `bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947` |
| Submission package | `submission/dist/kan-demo-package-final.zip` | Downloadable bundle with APK, app source, video, docs, evidence, and adaptation pipeline | See `submission/dist/kan-demo-package-final.zip.sha256` |

## Kaggle Form Inputs

- Repository URL: fill in after public GitHub push.
- Live artifact URL: fill in after uploading `submission/dist/kan-demo-package-final.zip`.
- Video URL: fill in after uploading `submission/kan-final-demo-video.mp4`.
- Kaggle form copy: `submission/KAGGLE_FORM.md`.
- YouTube upload copy: `submission/YOUTUBE_DESCRIPTION.md`.
- GitHub release notes: `submission/GITHUB_RELEASE_NOTES.md`.
- Kaggle Dataset metadata template: `submission/kaggle-dataset-metadata.template.json`.
- Kaggle Dataset README: `submission/KAGGLE_DATASET_README.md`.
- Media gallery cover: `submission/media-gallery-cover.png`.
- Impact Track: Digital Equity & Inclusivity.
- Special prizes: claim LiteRT / AI Edge for the final physical-device local Gemma 4 E2B proof. Claim Cactus only as supplemental local routing/inference evidence. Do not claim Unsloth trained weights unless a larger-GPU adapter and before/after benchmark are added.

## Final Local Verification

```bash
git status --short
git status --ignored --short | rg "\\.env|submission/dist|submission/live-demo/zpk-local-release|unsloth/.venv"
shasum -a 256 submission/live-demo/zpk-local-release.apk submission/live-demo/zpk-litert-release.apk submission/live-demo/zpk-citizen-gemma4-release.apk submission/kan-final-demo-video.mp4 submission/media-gallery-cover.png
(cd submission/dist && shasum -a 256 -c kan-demo-package-final.zip.sha256)
unzip -l submission/dist/kan-demo-package-final.zip | rg "\\.env|kan-final-demo-video|training_attempt|zpk-local-release.apk|zpk-litert-release.apk|zpk-citizen-gemma4-release.apk"
./scripts/verify_submission.sh
./scripts/verify_release_build.sh
./scripts/publish_submission.sh --check
KAGGLE_USERNAME=<your-kaggle-username> ./scripts/prepare_kaggle_dataset.sh
uvx kaggle datasets create -p submission/kaggle-dataset-upload --dir-mode zip
```

Expected:

- Git working tree may be dirty before final commit; do not publish until the intended files are committed or the public repo clearly reflects this artifact.
- `.env`, generated ZIPs, APKs, and `.venv` are ignored.
- The archive contains `.env.example` but not `.env`.
- The archive contains the auditable Flutter app source under `kan-app/`
  (`lib/`, `test/`, assets, and minimal Android/iOS project files) without
  `.dart_tool`, `build`, `local.properties`, Pods, or IDE state.
- The video is under 180 seconds.
- The media cover is 1600x900.
- Release builds do not silently use Android debug signing; without
  `ZPK_RELEASE_*` credentials the release APK is intentionally unsigned.
- `verify_submission.sh` also checks that the public copy and ZIP include
  the signed local authentication proof, encrypted audit archive, Gemma 4
  evidence, and physical-device claims without stale draft markers.
