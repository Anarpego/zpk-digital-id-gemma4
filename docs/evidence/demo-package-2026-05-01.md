# Demo Package Evidence

Date: 2026-05-01

Generated package:

- `submission/dist/kan-demo-package-20260501T172021Z.zip`
- Size: about 93 MB.
- Contents: default local-mode debug APK, narrated final demo video, selected evidence screenshots, README, license, checklist, evidence docs, submission drafts, and Unsloth seed data.

APK:

- `submission/live-demo/kan-debug.apk`
- SHA-256: `0e1010be2a9a850a2e694140156c32e7feb333254a0f061474100c5e20fdb8bb`

Command used:

```bash
./scripts/package_demo.sh
```

Verification:

- `flutter build apk --debug` completed inside the script.
- `unzip -l submission/dist/kan-demo-package-20260501T172021Z.zip` includes `.env.example`, `submission/live-demo/index.html`, `submission/ARTIFACT_MANIFEST.md`, `submission/kan-final-demo-video.mp4`, `submission/final-kaggle-writeup.md`, `submission/prize-claims.md`, `submission/publish-runbook.md`, `submission/final-video-script.md`, `submission/final-video-narration.txt`, `submission/final-video-captions.srt`, `submission/media-gallery-cover.svg`, `submission/video-raw/kan-demo-flow.mp4`, `docs/evidence/unsloth-scaffold-2026-05-01.md`, `unsloth/train_lora.py`, `unsloth/uv.lock`, `unsloth/outputs/dry_run_report.md`, and `unsloth/outputs/training_attempt_2026-05-01.md`.
- The archive includes `.env.example` but does not include `.env`.
- The APK is the default local-mode debug build; it does not embed `KAN_GEMINI_API_KEY`.

Use:

Upload this ZIP as downloadable live-demo evidence if a public hosted demo is not ready. Install the APK with:

```bash
adb install -r kan-debug.apk
adb shell monkey -p gt.kan.kan_app 1
```
