# Emulator Sectioned Agent Flow - 2026-05-02

## Scope

Validated the app after replacing the single long-scroll dashboard with task
sections for a low-technical-background citizen flow.

## UX Changes

- Bottom navigation now separates `Ayuda`, `Acciones`, `Evidencia`, and
  `Motor`.
- `Ayuda` contains the compact incident selector, synthetic CUI field, and one
  primary action.
- `Acciones` shows the citizen outcome and immediate next steps without
  technical traces.
- `Evidencia` keeps audit traces, local breach lookup, trust fabric, recovery
  packets, and model traces for judges or institutions.
- `Motor` owns LiteRT/Gemma runtime status, install, and offline self-test.

## Emulator Evidence

- Device: `emulator-5554`, `sdk_gphone64_arm64`.
- Installed APK: `kan-app/build/app/outputs/flutter-apk/app-debug.apk`.
- APK SHA-256:
  `42db79b2ee566e34862415b49ab9aa63852988970debb477192cbbef2854d6ef`.
- Help screenshot:
  `docs/evidence/emulator-sectioned-agent-help-2026-05-02.png`.
- Help screenshot SHA-256:
  `f9b12a8a2f78f41204e64a8e6c5c597fd057ddfb7773927a534a0fcdbd601332`.
- Actions screenshot:
  `docs/evidence/emulator-sectioned-agent-actions-2026-05-02.png`.
- Actions screenshot SHA-256:
  `159754927ac80d40ead85b6f5a8fbc1bdf9b13b8230a41bf798063b515758900`.
- Evidence screenshot:
  `docs/evidence/emulator-sectioned-agent-evidence-2026-05-02.png`.
- Evidence screenshot SHA-256:
  `c8cd06392d45ca6f9e855ad33cf87c1101e3986a49ab786c5480231979c0b07e`.

## Verification Commands

- `dart format lib/features/identity_wallet/home_screen.dart test/widget_test.dart`
- `flutter analyze`
- `flutter test`
- `flutter build apk --debug --dart-define=KAN_REASONER=local`
- `adb install -r kan-app/build/app/outputs/flutter-apk/app-debug.apk`
- `adb shell am start -n gt.kan.kan_app/.MainActivity`

## Result

The emulator installs and runs the sectioned UX. The citizen can start from a
short `Ayuda` flow, receive the next action in `Acciones`, and keep technical
proof in `Evidencia` without mixing the runtime diagnostics into the primary
task.
