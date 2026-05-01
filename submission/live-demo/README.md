# ZPK Digital ID Demo Package

This package is intended for Kaggle live-demo/download evidence. It contains a debug Android APK built in default local mode, selected screenshots, a narrated final demo video, and documentation links.

Open `index.html` for a simple static demo landing page.

## Install

Use an Android emulator or connected Android device:

```bash
adb install -r kan-debug.apk
adb shell monkey -p gt.kan.kan_app 1
```

Use synthetic CUI `1234567890101` for the main flow.

## What This Demo Shows

- Offline ZPK identity registration.
- DID-style document and HMAC-SHA256-signed recovery credential.
- Selective disclosure claims and 15-minute consent proof.
- Local Spanish guidance.
- Preliminary complaint document generation.
- Visible tool traces for privacy routing and redacted institutional packet generation.

## What This Demo Does Not Include

- Real personal data or real breach data.
- Embedded API keys.
- Production legal advice.
- Hosted Gemma 4 API mode.

Hosted Gemma 4 and Cactus evidence are documented separately in `docs/evidence/`.
