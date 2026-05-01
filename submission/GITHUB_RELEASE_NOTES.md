# ZPK Digital ID Gemma 4 Good Submission Package

This release contains the public judging artifacts for ZPK Digital ID, a local-first Android identity wallet for Guatemalan citizens. It demonstrates pseudonymous registration, selective disclosure, consent proof, CUI risk lookup, and recovery guidance without sending raw CUI to hosted reasoning by default.

## Assets

- `kan-demo-package-final.zip`: APK, static demo page, final video, media cover, writeup, evidence, screenshots, and Unsloth scaffold.
- `kan-demo-package-final.zip.sha256`: checksum for the demo package.
- `kan-final-demo-video.mp4`: narrated demo video under 3 minutes.
- `media-gallery-cover.png`: 1600x900 Kaggle media-gallery cover.

## Verify

```bash
./scripts/verify_submission.sh
shasum -a 256 -c submission/dist/kan-demo-package-final.zip.sha256
shasum -a 256 submission/kan-final-demo-video.mp4 submission/media-gallery-cover.png submission/live-demo/kan-debug.apk
```

Expected checksums:

- Demo ZIP: generate from the uploaded asset with `shasum -a 256`.
- Final video: `a01f26b7c8ef747415d7bb51280d1fabc82f0f27a6c7749b01494674ded6c5e1`
- Media cover: `882f32b3e35b8b73fcf7b32dda46f021fe82bfdcad33b44a5a707aa7de265875`
- APK: `e65033655d713cd53f3612565a62efd3b5f5d1af170323a6db0bf634609f97b2`

The package includes `.env.example` but must not include `.env`.
