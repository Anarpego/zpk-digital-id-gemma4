# Demo Package Evidence

Date: 2026-05-01

Generated package:

- `submission/dist/kan-demo-package-final.zip`
- `submission/dist/kan-demo-package-final.zip.sha256`
- Size: about 95 MB.
- Contents: default local-mode debug APK, narrated final demo video, media-gallery cover PNG/SVG, selected evidence screenshots, README, license, checklist, evidence docs, submission drafts, and Unsloth seed data.

APK:

- `submission/live-demo/kan-debug.apk`
- SHA-256: `97f46a47ac06bbdd232e70e98cec6a7d03b4093ca7a43e38ebb391f63ce97138`

Command used:

```bash
./scripts/package_demo.sh
```

Verification:

- `flutter build apk --debug` completed inside the script.
- `shasum -a 256 -c submission/dist/kan-demo-package-final.zip.sha256` passes.
- `unzip -l submission/dist/kan-demo-package-final.zip` includes `.env.example`, `scripts/prepare_kaggle_dataset.sh`, `scripts/publish_submission.sh`, `scripts/verify_submission.sh`, `submission/live-demo/index.html`, `submission/ARTIFACT_MANIFEST.md`, `submission/GITHUB_RELEASE_NOTES.md`, `submission/KAGGLE_DATASET_README.md`, `submission/KAGGLE_FORM.md`, `submission/YOUTUBE_DESCRIPTION.md`, `submission/kaggle-dataset-metadata.template.json`, `submission/kan-final-demo-video.mp4`, `submission/final-kaggle-writeup.md`, `submission/prize-claims.md`, `submission/publish-runbook.md`, `submission/final-video-script.md`, `submission/final-video-narration.txt`, `submission/final-video-captions.srt`, `submission/media-gallery-cover.svg`, `submission/media-gallery-cover.png`, `submission/video-raw/kan-demo-flow.mp4`, `docs/evidence/unsloth-scaffold-2026-05-01.md`, `unsloth/train_lora.py`, `unsloth/uv.lock`, `unsloth/outputs/dry_run_report.md`, and `unsloth/outputs/training_attempt_2026-05-01.md`.
- `./scripts/verify_submission.sh` passes against the generated artifacts.
- The archive includes `.env.example` but does not include `.env`.
- The APK is the default local-mode debug build; it does not embed `KAN_GEMINI_API_KEY`.

Use:

Upload this ZIP as downloadable live-demo evidence if a public hosted demo is not ready. Install the APK with:

```bash
adb install -r kan-debug.apk
adb shell monkey -p gt.kan.kan_app 1
```
