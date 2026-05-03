# iOS FlutterGemma Gemma 4 Smoke

Date: 2026-05-02

Purpose: prove that the Flutter app can run the real Gemma 4 E2B LiteRT-LM model through `flutter_gemma` on an iPhone Simulator, with local ZPK agent logic and no hosted LLM fallback.

## Environment

- Device: Xcode iPhone 17 Pro Simulator, iOS 26.4, UUID `9F3E7200-F2D6-4476-9DC6-913D03F44906`
- App target: `kan-app/lib/flutter_gemma4_smoke.dart`
- Model URL: `https://knight-adjustment-depot-translations.trycloudflare.com/models/gemma-4-E2B-it.litertlm`
- Model size: `2,583,085,056` bytes
- Runtime: `flutter_gemma` `0.14.1`, `ModelType.gemma4`, `ModelFileType.litertlm`, CPU backend
- Screenshot: `docs/evidence/ios-flutter-gemma4-smoke-2026-05-02.png`

## Command

```bash
cd kan-app
flutter run \
  -d 9F3E7200-F2D6-4476-9DC6-913D03F44906 \
  -t lib/flutter_gemma4_smoke.dart \
  --dart-define=KAN_FLUTTER_GEMMA_MODEL_URL=https://knight-adjustment-depot-translations.trycloudflare.com/models/gemma-4-E2B-it.litertlm \
  --dart-define=KAN_FLUTTER_GEMMA_MODEL_ID=gemma-4-E2B-it.litertlm \
  --dart-define=KAN_FLUTTER_GEMMA_TIMEOUT_SECONDS=1200
```

## Result

- First run downloaded the full model and set it as the active inference model.
- Relaunch reused the installed model: `Model already installed: gemma-4-E2B-it.litertlm (skipping download)`.
- LiteRT-LM FFI opened the model on iOS and initialized the engine.
- Gemma 4 generated valid JSON for the ZPK identity-recovery case.
- The app trace reported `flutter_gemma4_smoke.used_local_only -> true`.
- Privacy and schema checks passed:
  - `privacy_guard.raw_cui -> absent`
  - `privacy_guard.13_digit_identifier -> absent`
  - `agent_contract.schema(json) -> ok`
  - `agent_contract.safety_review(raw_cui=false) -> ok`
- Local trust fabric signed and verified the recovery ledger with iOS Keychain:
  - `trust_fabric.keystore(ios-keychain)`
  - `agent_ledger.verify(local) -> ok`

Key trace lines:

```text
flutter_gemma4_smoke.model -> gemma-4-E2B-it.litertlm
flutter_gemma4_smoke.used_local_only -> true
flutter_gemma4.generate(gemma-4-E2B-it.litertlm) -> ok
trust_fabric.keystore(ios-keychain) -> zpk-android-keystore-issuer-key-2026-05
agent_ledger.verify(local) -> ok
```

## Notes

This is a real on-device iOS/Simulator Gemma 4 proof, not the Android production proof. Android still needs a physical ARM64 phone run showing `litert_gemma.generate(...) -> ok`.
