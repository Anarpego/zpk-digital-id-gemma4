# ML Kit Gemma On-Device Evidence

Date: 2026-05-01

Device: Mac-hosted Android emulator `Medium_Phone_API_36.1`.

## What Was Added

- Added Flutter mode `KAN_REASONER=mlkit-gemma`.
- Added Dart reasoner `kan-app/lib/services/mlkit_gemma_reasoner.dart`.
- Added Android MethodChannel `gt.kan.kan_app/mlkit_gemma`.
- Added a native `status` probe so unsupported devices fail before generation
  and supported devices can show an explicit `AVAILABLE` trace.
- Added native `download` and `warmup` calls so a supported device that reports
  `DOWNLOADABLE` can fetch the on-device model, re-probe status, warm the
  runtime, and then generate locally.
- Added ML Kit dependency `com.google.mlkit:genai-prompt:1.0.0-beta1`.
- Raised Android `minSdk` to `26`, matching the Prompt API requirement.

Official basis:

- ML Kit Prompt API setup and status flow: https://developers.google.com/ml-kit/genai/prompt/android/get-started
- Android Gemma 4 on-device/AICore preview announcement: https://developer.android.com/blog/posts/gemma-4-the-new-standard-for-local-agentic-intelligence-on-android
- Current Maven artifact check: https://mvnrepository.com/artifact/com.google.mlkit/genai-prompt

Note: the current `1.0.0-beta1` AAR exposes `Generation.getClient()` and Prompt API status/generation classes. The preview model-selection classes shown in the April 2026 blog are not exposed in this local artifact, so this integration uses the available ML Kit Prompt API client and records the actual device status.

## Verification Commands

```bash
cd kan-app
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug \
  --dart-define=KAN_REASONER=mlkit-gemma \
  --dart-define=KAN_MLKIT_TIMEOUT_SECONDS=120
```

Results:

- `dart format --set-exit-if-changed lib test`: pass.
- `flutter analyze`: pass, no issues found.
- `flutter test`: pass, 41 tests.
- `flutter build apk --debug ...`: pass, generated `build/app/outputs/flutter-apk/app-debug.apk`.

## Emulator Runtime Result

Installed and launched on `Medium_Phone_API_36.1`:

```bash
adb install -r kan-app/build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n gt.kan.kan_app/.MainActivity
```

The app entered `ML Kit Gemma local` mode and invoked the native Prompt API bridge. The emulator returned:

```text
PlatformException(UNAVAILABLE, ML Kit GenAI Prompt API is unavailable on this device., {status: UNAVAILABLE}, null)
```

The app then fell back to deterministic local guidance and preserved the trace in the UI.

Current code now probes `mlkit_gemma.status` before a generation request. If a
supported device reports `DOWNLOADABLE`, the app calls `mlkit_gemma.download`,
re-probes status, warms the runtime, and then generates locally. If a device
reports anything other than `AVAILABLE` after setup, the app stops that model
path and falls back locally. Unit tests verify the successful order
`status -> warmup -> generate`, the downloadable order
`status -> download -> status -> warmup -> generate`, and the unavailable order
`status` only.

Updated runtime trace after the status-probe normalization:

```text
reasoner_mode(mlkit-gemma:aicore) -> fallback: Bad state: ML Kit Gemma status is UNAVAILABLE.
privacy_guard.raw_cui -> absent
privacy_guard.13_digit_identifier -> absent
agent_ledger.sign(android-keystore) -> ...
```

Updated evidence files:

- `docs/evidence/mlkit-gemma-status-probe-2026-05-01.png`
- `docs/evidence/mlkit-gemma-status-probe-2026-05-01.uiautomator.xml`

SHA-256:

```text
46347d0137822dc9c6e942063b63b14fbd9efac25487e8447dadea9f6637fd9d  docs/evidence/mlkit-gemma-status-probe-2026-05-01.png
c18ca4f52a6e08c884839762205050dfb5699efe9353da19bdb134d29b524399  docs/evidence/mlkit-gemma-status-probe-2026-05-01.uiautomator.xml
```

Screenshot: `docs/evidence/mlkit-gemma-emulator-unavailable-2026-05-01.png`

Screenshot SHA-256:

```text
c552728f2b24c0bfb7fc587bcd4031f7b7449f5cefdee3911b28171669485123
```

## Submission Guidance

Claim: ZPK Digital ID now has a compiled Android ML Kit/AICore on-device reasoner path with graceful fallback and visible trace evidence.

Do not claim: verified offline Gemma 4 generation. The available emulator reported `UNAVAILABLE`; a supported AICore device or developer-preview device is still required for a successful `mlkit_gemma.generateContent(...) -> ok` trace.
