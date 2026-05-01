# Kan Gemma 4 Good Submission Package

This release contains the public judging artifacts for Kan, a local-first Android assistant for Guatemalan citizens responding to personal-data leaks.

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
- Final video: `42774441b15dd69af421c2f76d6e59b71203b4c27effb810b0b011da040bce34`
- Media cover: `3c1039c1843ee8763439b1be6fb27151056770e33f4f0e7e7a5d04f9ada16db3`
- APK: `97f46a47ac06bbdd232e70e98cec6a7d03b4093ca7a43e38ebb391f63ce97138`

The package includes `.env.example` but must not include `.env`.
