# Demo Package Evidence

Date: 2026-05-01

Generated package:

- `submission/dist/kan-demo-package-20260501T155615Z.zip`
- Size: about 78 MB.
- Contents: default local-mode debug APK, selected evidence screenshots, README, license, checklist, evidence docs, submission drafts, and Unsloth seed data.

APK:

- `submission/live-demo/kan-debug.apk`
- SHA-256: `0e1010be2a9a850a2e694140156c32e7feb333254a0f061474100c5e20fdb8bb`

Command used:

```bash
./scripts/package_demo.sh
```

Verification:

- `flutter build apk --debug` completed inside the script.
- `unzip -l submission/dist/kan-demo-package-20260501T155615Z.zip` includes `.env.example`, `submission/media-gallery-cover.svg`, `unsloth/train_lora.py`, `unsloth/uv.lock`, and `unsloth/outputs/dry_run_report.md`.
- The archive includes `.env.example` but does not include `.env`.
- The APK is the default local-mode debug build; it does not embed `KAN_GEMINI_API_KEY`.

Use:

Upload this ZIP as downloadable live-demo evidence if a public hosted demo is not ready. Install the APK with:

```bash
adb install -r kan-debug.apk
adb shell monkey -p gt.kan.kan_app 1
```
