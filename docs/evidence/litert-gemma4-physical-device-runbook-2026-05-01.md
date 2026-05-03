# LiteRT Gemma 4 Physical Device Runbook

Date: 2026-05-01

Purpose: final proof path for Android in-app offline Gemma 4 generation.

## Build And Serve

Use HTTPS for the model download:

```bash
cloudflared tunnel --url http://127.0.0.1:3333
PUBLIC_URL=https://<trycloudflare-url> ./scripts/wireless_installer.sh
```

Open the installer page or scan `/qr.svg` from the Android phone.

## In-App Checks

Optional ADB-assisted proof when a physical phone is connected:

```bash
./scripts/run_physical_litert_proof.sh --watch-seconds 300
```

The helper refuses Android emulators, checks for `arm64-v8a`, requires at least
6,000,000,000 bytes of physical RAM by default, installs the signed LiteRT APK,
opens the app, and captures logcat to
`docs/evidence/litert-gemma4-physical-adb-*.log`. Low-RAM phones such as the
Motorola G15 must use `./scripts/verify_motorola_physical_flow.sh` instead;
that proves the honest fallback path, not Gemma generation.

Manual no-cable path:

1. Install `zpk-litert-release.apk`.
2. Open ZPK Digital ID.
3. Confirm the `Motor agente offline` panel is visible.
4. Press refresh.
5. Expected before model install: `DOWNLOADABLE`.
6. Tap `Instalar Gemma offline` and wait for install/warmup traces.
7. Run the registration flow with synthetic CUI `1234567890101`.
8. If download/generation fails, tap `Copiar diagnostico` or `Copiar error`
   and save the copied text.
9. If generation succeeds, tap `Copiar trazas` and save the copied text.

## Winning Evidence

Claim Android in-app offline Gemma 4 only if copied traces include:

```text
litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> AVAILABLE
litert_gemma.install.warmup(gemma-4-E2B-it-litertlm) -> READY
litert_gemma.warmup(gemma-4-E2B-it-litertlm) -> READY
litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok
agent_contract.schema(json) -> ok
agent_contract.safety_review(raw_cui=false) -> ok
privacy_guard.raw_cui -> absent
agent_ledger.verify(local) -> ok
```

## Failure Boundary

Do not claim successful Android generation if the copied diagnostic contains
OpenCL, GPU delegate, model download, SHA-256, JSON contract, or native LiteRT
errors. In that case, claim only the implemented Android bridge, model status
panel, app-agent harness, and Mac offline LiteRT generation evidence.
