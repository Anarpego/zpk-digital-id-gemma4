# Emulator Guided Agent Flow - 2026-05-02

Historical note: this evidence captured the first guided-flow UI. The current
sectioned UX evidence is `docs/evidence/emulator-sectioned-agent-flow-2026-05-02.md`.

## Scope

Validated an emulator-safe Android build after changing the app from a
technical-first dashboard to a citizen-guided identity protection flow.

## What Changed

- First screen now asks the citizen what happened in plain language.
- Primary action is pinned as `Ayudarme ahora` so it remains available.
- Runtime and Gemma diagnostics moved under `Estado tecnico del motor`.
- After a case runs, the app presents a plain-language agent outcome before
  technical traces.
- Debug builds allow screenshots for evidence; release builds keep
  `FLAG_SECURE` enabled.

## Emulator Evidence

- Device: `emulator-5554`, `sdk_gphone64_arm64`.
- Installed APK: `kan-app/build/app/outputs/flutter-apk/app-debug.apk`.
- APK SHA-256: `f970b32b0b28c49842537d7018827ccec15abc415b64142da92f7e600a182a99`.
- Screenshot: `docs/evidence/emulator-guided-agent-flow-2026-05-02.png`.
- Screenshot SHA-256: `b6963525aac40fa3352b00eb8b16292a9f65379f4137e08e0946ef179061b61f`.
- Result screenshot: `docs/evidence/emulator-guided-agent-result-2026-05-02.png`.
- Result screenshot SHA-256: `82f834a527070c5cd62a6c7c5d15f86cb87ba211e06f021dd49b4ca31b79c7d5`.

## Verification Commands

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug --dart-define=KAN_REASONER=local`
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- `adb shell am start -n gt.kan.kan_app/.MainActivity`

## Result

The emulator installs and launches the current app successfully. The visible UI
shows the guided agent flow with citizen scenario choices, local wallet status,
offline status, synthetic CUI field, and the persistent `Ayudarme ahora` action.
After running the local case, the emulator result screen shows `Hay riesgo de
identidad`, local CUI/catalog review, no-PII routing, a pseudonymous local
identity, and a redacted institutional recovery packet path.
