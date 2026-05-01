# Kaggle Submission Fields

Use these fields for the final Kaggle submission. Replace placeholder URLs only after the public repository, demo ZIP, and video have been uploaded.

## Title

ZPK Digital ID: Local-First Identity Protection for Guatemala

## Subtitle

An Android-first digital identity wallet that registers citizens locally, protects CUI/DPI data with pseudonymous HMAC-signed proofs, and uses Gemma 4 reasoning for recovery guidance.

## Impact Track

Digital Equity & Inclusivity

## Repository URL

`TODO_PUBLIC_REPO_URL`

## Live Demo URL

`TODO_PUBLIC_DEMO_ZIP_OR_DATASET_URL`

Recommended artifact: `submission/dist/kan-demo-package-final.zip`.

## Video URL

`TODO_PUBLIC_VIDEO_URL`

Recommended artifact: `submission/kan-final-demo-video.mp4`.

## Short Summary

ZPK Digital ID targets a national-scale problem: citizens need digital identity and authentication, but vulnerable countries cannot assume every registry, aid program, or institution will protect personal data perfectly. The demo registers a synthetic Guatemalan citizen into a local wallet, creates a pseudonymous ZPK credential, verifies CUI risk against an embedded catalog, explains the result in Spanish, and generates a recovery packet on device.

## Technical Summary

ZPK Digital ID is a Flutter Android app with four reasoner modes: deterministic local mode for reliable offline demos, Cactus local mode for on-device model-routing evidence, hosted Gemma 4 mode verified with `gemma-4-31b-it`, and an ML Kit/AICore mode that compiles and fails closed on the Mac emulator when the GenAI feature is unavailable. The significant result is the local identity trust fabric: a DID-style document, HMAC-SHA256-signed recovery credential, selective disclosure claims, 15-minute consent proof, privacy route, Spanish explanation, and complaint packet without sending raw CUI to hosted reasoning by default. Evidence includes passing Flutter tests, Android APK build, Gemma 4 API smoke test, Cactus local-inference metrics, ML Kit/AICore fallback evidence, and a documented Unsloth training attempt that reached Gemma 4 E2B load/tokenization before failing on the available 6 GB GPU.

## Prize Claims

- Main Track: working social-impact prototype with Android app, local sensitive-data verification, Spanish guidance, document draft, hosted Gemma 4 evidence, and visible privacy traces.
- Impact Track: Digital Equity & Inclusivity.
- Cactus special prize: claim cautiously as partial local-inference/routing evidence only.
- On-device Gemma 4: do not claim successful generation unless a supported AICore device produces a local `generateContent` trace.
- Unsloth special prize: do not claim unless a larger GPU produces an adapter and before/after benchmark.

## Public Upload Checklist

- [ ] Public GitHub repository URL is reachable without login.
- [ ] Demo ZIP URL is reachable without login.
- [ ] Video URL is reachable without login and plays under 3 minutes.
- [ ] Kaggle writeup is pasted from `submission/final-kaggle-writeup.md`.
- [ ] Media gallery includes `submission/media-gallery-cover.png`.
- [ ] No `.env` or API key is uploaded.
