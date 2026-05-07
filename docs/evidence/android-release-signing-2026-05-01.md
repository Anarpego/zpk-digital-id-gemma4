# Android Release Signing Evidence

Date: 2026-05-01

Purpose: avoid accidentally presenting a debug-key signed artifact as a
production release.

## Implemented Controls

- App label changed from Flutter scaffold `kan_app` to `ZPK Digital ID`.
- Release builds no longer fall back to Android debug signing keys.
- The QR-served LiteRT APK is now a signed ARM64 release build for browser sideloading, not a Flutter debug/test APK.
- Optional release signing is controlled through environment variables:
  - `ZPK_RELEASE_KEYSTORE`
  - `ZPK_RELEASE_STORE_PASSWORD`
  - `ZPK_RELEASE_KEY_ALIAS`
  - `ZPK_RELEASE_KEY_PASSWORD`

If those variables are missing, the Gradle release build is not signed with the
debug key. The Kaggle package now requires these signing variables and ships
both public APKs as signed ARM64 release artifacts:
`submission/live-demo/zpk-local-release.apk` and
`submission/live-demo/zpk-litert-release.apk`.

The repeatable gate is `./scripts/verify_release_build.sh`. It builds
`app-release.apk`, verifies the signature state with Android SDK `apksigner`,
fails if a release APK unexpectedly verifies without `ZPK_RELEASE_*`
credentials, and fails if a signed release uses the Android debug certificate.
`./scripts/verify_submission.sh` also verifies that the packaged local and
LiteRT APKs are signed and not using the Android debug certificate.

## Non-Claims

No production government signing certificate is committed in this repository.
The local sideload certificate used for the QR APK is stored under ignored
`.secrets/` and is only suitable for hackathon/device testing. A real
deployment still needs institution-controlled signing keys, Play Integrity or
equivalent attestation policy, release management, and key rotation procedures.

## Verification

Latest refresh on 2026-05-03:

- `flutter analyze` from `kan-app`: passed with no issues.
- `flutter test` from `kan-app`: passed at the time of this evidence capture. Current test count is tracked in `goal-completion-audit-2026-05-07.md`.
- `./scripts/package_demo.sh` with `ZPK_RELEASE_*` and `LITERT_PUBLIC_URL`:
  rebuilt `submission/live-demo/zpk-local-release.apk`,
  `submission/live-demo/zpk-litert-release.apk`, and
  `submission/dist/kan-demo-package-final.zip`.
- `./scripts/verify_submission.sh`: passed and verified the local and LiteRT APK
  signatures are not the Android debug certificate.
- `./scripts/verify_release_build.sh` with `ZPK_RELEASE_*`: passed, produced a
  signed non-debug `app-release.apk`.
- Packaged signed LiteRT ARM64 release APK SHA-256: see
  `submission/live-demo/zpk-litert-release.apk.sha256`.
- Packaged signed local ARM64 release APK SHA-256: see
  `submission/live-demo/zpk-local-release.apk.sha256`.
- Signed generic release gate APK SHA-256: emitted by
  `./scripts/verify_release_build.sh` for the current local build.
- Signed LiteRT release certificate:
  `CN=ZPK Digital ID Sideload, O=ZPK, C=GT`; RSA 4096; APK Signature Scheme v2.
- `aapt2 dump badging submission/live-demo/zpk-local-release.apk`: confirmed
  `application-label:'ZPK Digital ID'`.
- `aapt2 dump xmltree --file AndroidManifest.xml
  submission/live-demo/zpk-local-release.apk`: confirmed `allowBackup=false`,
  `usesCleartextTraffic=false`, `fullBackupContent`, and
  `dataExtractionRules`.
