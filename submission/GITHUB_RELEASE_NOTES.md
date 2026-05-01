# Kan Gemma 4 Good Submission Package

This release contains the public judging artifacts for Kan, a local-first Android assistant for Guatemalan citizens responding to personal-data leaks.

## Assets

- `kan-demo-package-20260501T173449Z.zip`: APK, static demo page, final video, writeup, evidence, screenshots, and Unsloth scaffold.
- `kan-final-demo-video.mp4`: narrated demo video under 3 minutes.

## Verify

```bash
./scripts/verify_submission.sh
shasum -a 256 submission/dist/kan-demo-package-20260501T173449Z.zip submission/kan-final-demo-video.mp4 submission/live-demo/kan-debug.apk
```

Expected checksums:

- Demo ZIP: generate from the uploaded asset with `shasum -a 256`.
- Final video: `42774441b15dd69af421c2f76d6e59b71203b4c27effb810b0b011da040bce34`
- APK: `0e1010be2a9a850a2e694140156c32e7feb333254a0f061474100c5e20fdb8bb`

The package includes `.env.example` but must not include `.env`.
