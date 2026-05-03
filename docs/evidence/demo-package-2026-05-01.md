# Demo Package Evidence

Date: 2026-05-01
Latest refresh: 2026-05-02

Generated package:

- `submission/dist/kan-demo-package-final.zip`
- `submission/dist/kan-demo-package-final.zip.sha256`
- Size: about 286 MB after adding FlutterGemma/LiteRT-LM native runtime evidence.
- Contents: signed local-mode ARM64 release APK, signed LiteRT-mode ARM64 release APK, auditable Flutter app source, iOS FlutterGemma Gemma 4 evidence, narrated final video, media-gallery cover PNG/SVG, selected evidence screenshots, README, license, checklist, evidence docs, final submission assets, and Unsloth seed data.
- ZIP SHA-256: see `submission/dist/kan-demo-package-final.zip.sha256`.

APK:

- `submission/live-demo/zpk-local-release.apk`
- SHA-256: see `submission/live-demo/zpk-local-release.apk.sha256`
- `submission/live-demo/zpk-litert-release.apk`
- SHA-256: see `submission/live-demo/zpk-litert-release.apk.sha256`

Command used:

```bash
./scripts/package_demo.sh
```

Local checks:

- Signed ARM64 release packaging completed inside the script.
- `unzip -l submission/dist/kan-demo-package-final.zip` includes `.env.example`, `scripts/prepare_kaggle_dataset.sh`, `scripts/publish_submission.sh`, `scripts/verify_submission.sh`, `submission/live-demo/index.html`, `submission/ARTIFACT_MANIFEST.md`, `submission/GITHUB_RELEASE_NOTES.md`, `submission/KAGGLE_DATASET_README.md`, `submission/KAGGLE_FORM.md`, `submission/YOUTUBE_DESCRIPTION.md`, `submission/kaggle-dataset-metadata.template.json`, `submission/kan-final-demo-video.mp4`, `submission/final-kaggle-writeup.md`, `submission/prize-claims.md`, `submission/publish-runbook.md`, `submission/final-video-script.md`, `submission/final-video-narration.txt`, `submission/final-video-captions.srt`, `submission/media-gallery-cover.svg`, `submission/media-gallery-cover.png`, `submission/video-raw/zpk-demo-flow.mp4`, `submission/video-raw/zpk-final-narration.aiff`, `docs/evidence/unsloth-scaffold-2026-05-01.md`, `unsloth/train_lora.py`, `unsloth/uv.lock`, `unsloth/outputs/dry_run_report.md`, and `unsloth/outputs/training_attempt_2026-05-01.md`.
- `submission/dist/kan-demo-package-final.zip.sha256` contains the current ZIP checksum.
- The archive includes `.env.example` but does not include `.env`.
- The archive includes `kan-app/lib`, `kan-app/test`, `kan-app/assets`, and
  minimal Android/iOS project files for code review.
- The archive excludes generated app state such as `.dart_tool`, `build`,
  `android/local.properties`, iOS Pods, and local Flutter export files.
- The archive excludes `submission/kaggle-writeup-draft.md` and `submission/video-script-draft.md`.
- The archive excludes raw `*.uiautomator.xml` dumps so public evidence cannot drift behind the app trace.
- The local APK is a signed ARM64 release build; it does not embed `KAN_GEMINI_API_KEY`.
- `./scripts/verify_submission.sh` scans the APK for Gemini key markers and
  scans the ZIP for Gemini API key patterns before reporting pass.
- The video duration is under 180 seconds.
- The media cover PNG is 1600x900.

Use:

Upload this ZIP as downloadable live-demo evidence if a public hosted demo is not ready. Install the APK with:

```bash
adb install -r zpk-local-release.apk
adb shell monkey -p gt.kan.kan_app 1
```
