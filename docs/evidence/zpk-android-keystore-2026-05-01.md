# ZPK Android Keystore Evidence

Date: 2026-05-01

Purpose: reduce the strongest production-readiness gap in the local identity
fabric by moving the app runtime signing key out of Dart source and into Android
Keystore.

## Implementation

- Dart signer interface: `kan-app/lib/services/identity_signer.dart`
- Production app signer: `DeviceKeystoreIdentitySigner`
- Android channel: `gt.kan.kan_app/identity_keystore`
- Native method: `signHmacSha256`
- Native key store: `AndroidKeyStore`
- Key alias: `zpk-android-keystore-issuer-key-2026-05`
- Proof suite: `HmacSha256Signature2026`

The app path in `main.dart` now constructs `DigitalIdentityFabric.device()`.
Widget and service tests keep `LocalHmacIdentitySigner`, so tests remain
deterministic without a platform channel.

## Runtime Evidence

Commands run locally on the Mac Android emulator:

```bash
flutter build apk --debug
adb install -r kan-app/build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p gt.kan.kan_app 1
adb shell input tap 540 1050
adb exec-out screencap -p > docs/evidence/zpk-android-keystore-trace-2026-05-01.png
adb exec-out cat /sdcard/window.xml > docs/evidence/zpk-android-keystore-trace-2026-05-01.uiautomator.xml
```

The UIAutomator trace includes:

```text
trust_fabric.keystore(android-keystore) -> zpk-android-keystore-issuer-key-2026-05
trust_fabric.verify_credential_signature(local) -> ok
```

The same signer is reused with purpose-separated payloads for the local agent
execution ledger. Tests verify the ledger hash chain and ensure it does not
contain the raw CUI.

## Non-Claims

This is not government-grade key governance, remote attestation, W3C VC
certification, or a hardware-backed guarantee on every Android device. It is a
real Android Keystore-bound signing path for the demo app, with local runtime
evidence on the emulator.
