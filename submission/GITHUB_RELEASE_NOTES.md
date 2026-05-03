# ZPK Digital ID Gemma 4 Good Submission Package

This release contains the public judging artifacts for ZPK Digital ID, a local-first Android identity wallet for Guatemalan citizens. It demonstrates pseudonymous registration, HMAC-SHA256-signed recovery credentials, selective disclosure, consent proof, CUI risk lookup, and recovery guidance without sending raw CUI to hosted reasoning by default.

## Assets

- `kan-demo-package-final.zip`: local APK, LiteRT APK, static artifact page, final video, media cover, writeup, evidence, screenshots, and adaptation pipeline.
- `kan-demo-package-final.zip.sha256`: checksum for the submission package.
- `kan-final-demo-video.mp4`: narrated final video under 3 minutes.
- `media-gallery-cover.png`: 1600x900 Kaggle media-gallery cover.

## Verify

```bash
./scripts/verify_submission.sh
(cd submission/dist && shasum -a 256 -c kan-demo-package-final.zip.sha256)
shasum -a 256 submission/kan-final-demo-video.mp4 submission/media-gallery-cover.png submission/live-demo/zpk-local-release.apk submission/live-demo/zpk-litert-release.apk
```

Expected checksums:

- Submission ZIP: generate from the uploaded asset with `shasum -a 256`.
- Final video: `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6`
- Media cover: `bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947`
- Local APK: see `submission/live-demo/zpk-local-release.apk.sha256`
- LiteRT APK: see `submission/live-demo/zpk-litert-release.apk.sha256`

The package includes `.env.example` but must not include `.env`.
