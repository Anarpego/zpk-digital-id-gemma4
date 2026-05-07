# ZPK Digital ID Demo Package

This package is intended for Kaggle live artifact/download evidence. It contains a reliable local-mode Android APK, a LiteRT-mode Android APK for physical-device Gemma testing, a citizen-mode Gemma 4 APK for the main judge demo, selected screenshots, a narrated final video, documentation links, physical-device evidence, and the auditable Flutter app source needed to inspect the implementation.

Open `index.html` for a simple static artifact page.

## Install

Use an Android emulator or connected Android device:

```bash
adb install -r zpk-local-release.apk
adb shell monkey -p gt.kan.kan_app 1
```

Use synthetic CUI `1234567890101` for the main flow.

For the offline Gemma 4 path on a physical device, install:

```bash
adb install -r zpk-litert-release.apk
adb shell monkey -p gt.kan.kan_app 1
```

For the primary citizen/institution demo with the Gemma 4 ReAct home screen, install:

```bash
adb install -r zpk-citizen-gemma4-release.apk
adb shell monkey -p gt.kan.kan_app 1
```

If installing the model by cable for this release APK, place it at:

```text
/sdcard/Android/data/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm
```

Expected model SHA-256:

```text
ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

The final physical-device proof used this APK on an Honor Android device. The installed `base.apk` SHA-256 matched `zpk-citizen-gemma4-release.apk.sha256`.

If the LiteRT APK was built with `LITERT_PUBLIC_URL`, use `Instalar Gemma offline`
inside the app before running a case. Otherwise use `../docs/evidence/litert-gemma4-physical-device-runbook-2026-05-01.md`
with the QR/Cloudflare installer flow.

## What This Demo Shows

- Offline ZPK identity registration.
- DID-style document and HMAC-SHA256-signed recovery credential.
- Selective disclosure claims and 15-minute consent proof.
- Local Spanish guidance.
- Preliminary complaint document generation.
- Visible tool traces for privacy routing and redacted institutional packet generation.
- LiteRT Gemma runtime status, install diagnostics, and copyable agent traces in the LiteRT APK.
- Citizen-mode Gemma 4 ReAct flow: voice/photo/text intake, local Gemma 4 E2B tool timeline, safe close, Android Keystore-signed artifact, QR packet, and Modo Ventanilla.

## What This Demo Does Not Include

- Real personal data or real breach data.
- Embedded API keys.
- Production legal advice.
- Hosted Gemma 4 API mode in these downloadable APKs.
- Real government or bank integration.

Hosted Gemma 4, LiteRT, Cactus, and final physical-device evidence are documented separately in `docs/evidence/`.

## Source Included

The ZIP includes `kan-app/lib`, `kan-app/test`, `kan-app/assets`, and minimal
Android/iOS project files. It excludes generated build state, local SDK paths,
Pods, APK build outputs, and secret files.
