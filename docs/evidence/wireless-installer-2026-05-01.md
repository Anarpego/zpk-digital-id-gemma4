# Wireless Installer Evidence

Date: 2026-05-01

Purpose: install ZPK Digital ID on a physical Android phone without USB and let
the app download the Gemma 4 LiteRT-LM artifact over HTTPS.

## Files

- Installer server: `installer/server.mjs`
- Runner: `scripts/wireless_installer.sh`
- Generated APK: `installer/dist/zpk-litert.apk`
- QR page: `/`
- QR SVG: `/qr.svg`
- Model endpoint: `/models/gemma-4-E2B-it.litertlm`

## Cloudflare Tunnel Flow

```bash
cloudflared tunnel --url http://127.0.0.1:3333
PUBLIC_URL=https://your-trycloudflare-url ./scripts/wireless_installer.sh
```

The script builds a LiteRT-LM APK with:

```text
KAN_REASONER=litert-gemma
KAN_LITERT_MODEL_PATH=/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm
KAN_LITERT_MODEL_URL=$PUBLIC_URL/models/gemma-4-E2B-it.litertlm
KAN_LITERT_MODEL_SHA256=ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42
```

## Smoke Result

Command:

```bash
PUBLIC_URL=https://zpk-installer.example PORT=3334 ./scripts/wireless_installer.sh
```

Result:

```text
✓ Built build/app/outputs/flutter-apk/app-debug.apk
ZPK wireless installer: https://zpk-installer.example
APK: installer/dist/zpk-litert.apk
QR: https://zpk-installer.example/qr.svg
```

## Boundary

This verifies the QR installer build and serving path. It does not by itself
prove successful physical-device Gemma 4 generation; that still needs a real
Android device with a usable LiteRT-LM GPU/OpenCL/NPU path.
