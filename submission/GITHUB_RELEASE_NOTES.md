# ZPK Digital ID Gemma 4 Good Submission Package

This release contains the public judging artifacts for ZPK Digital ID, a local-first Android identity wallet for Guatemalan citizens. It demonstrates pseudonymous registration, HMAC-SHA256-signed recovery credentials, selective disclosure, consent proof, CUI risk lookup, and recovery guidance without sending raw CUI to hosted reasoning by default.

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
- Final video: `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6`
- Media cover: `15ba1a8f5037973ce6b0c76defdfd05bee438d2f8ddf15393cc75070e4a6f2b6`
- APK: `7b164de2b62af2130f21dcae29d3ba85c7dcb71446242d81bf8755494c164f3b`

The package includes `.env.example` but must not include `.env`.
