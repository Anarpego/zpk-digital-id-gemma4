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

The repeatable gate is `./scripts/verify_release_build.sh`. It builds
`app-release.apk`, verifies the signature state with Android SDK `apksigner`,
fails if a release APK unexpectedly verifies without `ZPK_RELEASE_*`
credentials, and fails if a signed release uses the Android debug certificate.

## Non-Claims

No production signing certificate is committed or generated in this repository.
A real deployment still needs institution-controlled signing keys, Play
Integrity or equivalent attestation policy, release management, and key
rotation procedures.

## Verification

Commands run on 2026-05-01:

- `flutter analyze` from `kan-app`: passed with no issues.
- `flutter test` from `kan-app`: 43 tests passed.
- `./scripts/package_demo.sh`: rebuilt `submission/live-demo/kan-debug.apk`
  and `submission/dist/kan-demo-package-final.zip`.
- `./scripts/verify_submission.sh`: passed.
- `./scripts/verify_release_build.sh`: passed, produced intentionally unsigned
  release APK without `ZPK_RELEASE_*` credentials.
- Release APK SHA-256:
  `0ad8b8a919e3f998cb0edc1a80b23ff64e1dc88c2bdd4fa169243f654a4b4e60`.
- `aapt2 dump badging submission/live-demo/kan-debug.apk`: confirmed
  `application-label:'ZPK Digital ID'`.
- `aapt2 dump xmltree --file AndroidManifest.xml
  submission/live-demo/kan-debug.apk`: confirmed `allowBackup=false`,
  `usesCleartextTraffic=false`, `fullBackupContent`, and
  `dataExtractionRules`.
