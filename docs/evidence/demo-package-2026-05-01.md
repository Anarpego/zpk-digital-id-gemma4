# Demo Package Evidence

Date: 2026-05-01

Generated package:

- `submission/dist/kan-demo-package-final.zip`
- `submission/dist/kan-demo-package-final.zip.sha256`
- Size: about 95 MB.
- Contents: default local-mode debug APK, narrated final demo video, media-gallery cover PNG/SVG, selected evidence screenshots, README, license, checklist, evidence docs, submission drafts, and Unsloth seed data.

APK:

- `submission/live-demo/kan-debug.apk`
- SHA-256: see `submission/live-demo/kan-debug.apk.sha256`

Command used:

```bash
./scripts/package_demo.sh
```

Local checks:

- `flutter build apk --debug` completed inside the script.
- `unzip -l submission/dist/kan-demo-package-final.zip` includes `.env.example`, `scripts/prepare_kaggle_dataset.sh`, `scripts/publish_submission.sh`, `scripts/verify_submission.sh`, `submission/live-demo/index.html`, `submission/ARTIFACT_MANIFEST.md`, `submission/GITHUB_RELEASE_NOTES.md`, `submission/KAGGLE_DATASET_README.md`, `submission/KAGGLE_FORM.md`, `submission/YOUTUBE_DESCRIPTION.md`, `submission/kaggle-dataset-metadata.template.json`, `submission/kan-final-demo-video.mp4`, `submission/final-kaggle-writeup.md`, `submission/prize-claims.md`, `submission/publish-runbook.md`, `submission/final-video-script.md`, `submission/final-video-narration.txt`, `submission/final-video-captions.srt`, `submission/media-gallery-cover.svg`, `submission/media-gallery-cover.png`, `submission/video-raw/zpk-demo-flow.mp4`, `submission/video-raw/zpk-final-narration.aiff`, `docs/evidence/unsloth-scaffold-2026-05-01.md`, `unsloth/train_lora.py`, `unsloth/uv.lock`, `unsloth/outputs/dry_run_report.md`, and `unsloth/outputs/training_attempt_2026-05-01.md`.
- `submission/dist/kan-demo-package-final.zip.sha256` contains the current ZIP checksum.
- The archive includes `.env.example` but does not include `.env`.
- The APK is the default local-mode debug build; it does not embed `KAN_GEMINI_API_KEY`.
- `./scripts/verify_submission.sh` scans the APK for Gemini key markers and
  scans the ZIP for Gemini API key patterns before reporting pass.
- The video duration is under 180 seconds.
- The media cover PNG is 1600x900.

Use:

Upload this ZIP as downloadable live-demo evidence if a public hosted demo is not ready. Install the APK with:

```bash
adb install -r kan-debug.apk
adb shell monkey -p gt.kan.kan_app 1
```
