# Android Release Signing Evidence

Date: 2026-05-01

Purpose: avoid accidentally presenting a debug-key signed artifact as a
production release.

## Implemented Controls

- App label changed from Flutter scaffold `kan_app` to `ZPK Digital ID`.
- Release builds no longer fall back to Android debug signing keys.
- Optional release signing is controlled through environment variables:
  - `ZPK_RELEASE_KEYSTORE`
  - `ZPK_RELEASE_STORE_PASSWORD`
  - `ZPK_RELEASE_KEY_ALIAS`
  - `ZPK_RELEASE_KEY_PASSWORD`

If those variables are missing, the Gradle release build is not signed with the
debug key. The Kaggle package continues to ship a clearly named debug APK for
local judging evidence.

## Non-Claims

No production signing certificate is committed or generated in this repository.
A real deployment still needs institution-controlled signing keys, Play
Integrity or equivalent attestation policy, release management, and key
rotation procedures.

## Verification

Commands run on 2026-05-01:

- `flutter analyze` from `kan-app`: passed with no issues.
- `flutter test` from `kan-app`: 22 tests passed.
- `./scripts/package_demo.sh`: rebuilt `submission/live-demo/kan-debug.apk`
  and `submission/dist/kan-demo-package-final.zip`.
- `./scripts/verify_submission.sh`: passed.
- `aapt2 dump badging submission/live-demo/kan-debug.apk`: confirmed
  `application-label:'ZPK Digital ID'`.
- `aapt2 dump xmltree --file AndroidManifest.xml
  submission/live-demo/kan-debug.apk`: confirmed `allowBackup=false`,
  `usesCleartextTraffic=false`, `fullBackupContent`, and
  `dataExtractionRules`.
