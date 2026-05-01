# YouTube Upload Fields

Use these fields when uploading `submission/kan-final-demo-video.mp4`.

## Title

ZPK Digital ID: Local-First Identity Protection with Gemma 4

## Description

ZPK Digital ID is an Android-first identity wallet for Guatemalan citizens who need safe registration, authentication, and recovery even when institutions leak personal data.

The demo uses synthetic data only. It creates a pseudonymous ZPK identity locally, emits DID-style and verifiable-credential-style recovery artifacts, checks synthetic CUI risk on device, explains the result in plain Spanish, and prepares a redacted recovery packet without sending the CUI to a server.

Technical evidence in the repository includes:

- Flutter Android app and debug APK.
- Hosted Gemma 4 mode verified with `gemma-4-31b-it`.
- Visible routing/tool traces for local registration, selective disclosure, consent proof, and document generation.
- Cactus local-inference metrics on Android.
- Unsloth Gemma 4 E2B scaffold plus a documented 6 GB GPU OOM training attempt.

Repository: paste public GitHub URL after upload
Demo package: paste public demo ZIP, release asset, or Kaggle Dataset URL after upload

Submitted for the Gemma 4 Good Hackathon.

## Tags

Gemma 4, Kaggle, Android, Flutter, digital equity, privacy, Guatemala, Cactus, Unsloth
