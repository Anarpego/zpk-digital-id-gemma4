# YouTube Upload Fields

Use these fields when uploading `submission/kan-final-demo-video.mp4`.

## Title

ZPK Digital ID: Local-First Identity Protection with Gemma 4

## Description

ZPK Digital ID is an Android-first identity wallet for Guatemalan citizens who need safe registration, authentication, and recovery even when institutions leak personal data.

The submitted app uses synthetic data only. It creates a pseudonymous ZPK identity locally, emits DID-style and verifiable-credential-style recovery artifacts, issues a signed local authentication proof, checks synthetic CUI risk on device, explains the result in plain Spanish, and prepares a redacted recovery packet without sending the CUI to a server.

Technical evidence in the repository includes:

- Flutter Android app and signed ARM64 release APKs.
- Honor Android physical-device proof with local Gemma 4 E2B through LiteRT-LM.
- Visible ReAct tool traces for PII redaction, case classification, local Guatemala lookup, document generation, safe close, and local signing.
- Citizen mode plus local institutional ventanilla mode for signed redacted packet handoff.
- Android Keystore signing, selective disclosure, consent proof, revocation receipt, and encrypted local audit archive.
- Cactus local-inference metrics on Android as supporting context.
- Gemma 4 E2B adaptation pipeline with 12,000 validated synthetic SFT examples, 1,200 RLKD-style teacher traces, SFT/QLoRA code, GRPO rewards, and a documented 6 GB GPU OOM training attempt.

Repository: https://github.com/Anarpego/zpk-digital-id-gemma4
Live demo / release: https://github.com/Anarpego/zpk-digital-id-gemma4/releases/tag/v2026.05.07-kaggle
Demo package ZIP: https://github.com/Anarpego/zpk-digital-id-gemma4/releases/download/v2026.05.07-kaggle/kan-demo-package-final.zip
Primary APK: https://github.com/Anarpego/zpk-digital-id-gemma4/releases/download/v2026.05.07-kaggle/zpk-citizen-gemma4-release.apk

Checksums:
- APK SHA-256: 7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb
- Video SHA-256: c6ef528c650cafefa339c228372966bbda7f812b905891cf8dace605761f4f63
- Cover SHA-256: bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947

Submitted for the Gemma 4 Good Hackathon.

## Tags

Gemma 4, Kaggle, Android, Flutter, digital equity, privacy, Guatemala, Cactus, Unsloth
