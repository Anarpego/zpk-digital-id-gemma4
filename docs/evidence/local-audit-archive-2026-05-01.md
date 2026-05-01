# Local Audit Archive Evidence

Date: 2026-05-01

Purpose: move ZPK Digital ID closer to a production app by retaining a
redacted, encrypted audit receipt on device after identity recovery
registration.

## Implemented Controls

- Added `AuditArchiveService` with an Android `NativeAuditArchive`.
- Android stores AES-GCM sealed envelopes in private app-internal storage:
  `filesDir/zpk-audit-archive`.
- The AES-256 key is generated and held by Android Keystore under
  `zpk-audit-archive-aes-gcm-2026-05`.
- Each record is hashed with SHA-256 before storage.
- The archived record excludes:
  - raw CUI
  - private local complaint text
- The visible receipt shows:
  - redacted record hash
  - internal storage location
  - archive record count
  - `audit_archive.raw_cui -> omitted`
  - `audit_archive.private_complaint -> omitted`
  - `audit_archive.encrypt(AES-GCM-256, android-keystore) -> sealed`
- The citizen can clear local audit receipts from the app UI.

## Verification

Commands run from `kan-app`:

- `flutter test test/services/audit_archive_test.dart test/widget_test.dart`:
  passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: 30 tests passed.
- `flutter build apk --debug`: passed.

The archive test verifies that the stored canonical record does not contain the
raw synthetic CUI and does not contain the private complaint text.
It also verifies `clearLocalArchive()` removes local archive records. The widget
test verifies the visible `Borrar archivo local` control and
`Archivo local borrado` receipt. The Android runtime check verifies that the
app-private stored artifact is a sealed envelope, not readable audit JSON.

## Android Runtime Evidence

Runtime run on Mac-hosted Android emulator `Medium_Phone_API_36.1`:

```bash
adb install -r kan-app/build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n gt.kan.kan_app/.MainActivity
adb shell input tap 540 1050
adb shell run-as gt.kan.kan_app ls -l files/zpk-audit-archive
adb shell run-as gt.kan.kan_app cat files/zpk-audit-archive/be97facab3fd2dfe18cce86a7cb0021e2adf119740ad946ce02e340fe2fcd44a.sealed.json
```

Observed app-private file:

```text
be97facab3fd2dfe18cce86a7cb0021e2adf119740ad946ce02e340fe2fcd44a.sealed.json
```

Exported sealed runtime envelope:

- `docs/evidence/local-audit-archive-sealed-runtime-2026-05-01.json`

SHA-256:

```text
dabbd5a4957b4538a0e252e41ddc975901dc875e5cdfd4557907bd6c5e2dc7e4  docs/evidence/local-audit-archive-sealed-runtime-2026-05-01.json
```

Negative check:

```bash
adb shell run-as gt.kan.kan_app cat files/zpk-audit-archive/be97facab3fd2dfe18cce86a7cb0021e2adf119740ad946ce02e340fe2fcd44a.sealed.json | rg -q "citizenPseudonym|zpk-gt-|1234567890101|recoveryPacketSignature"; test $? -eq 1
```

## Non-Claims

This is app-internal encrypted storage, not cross-device backup, HSM custody,
or a government audit service. A real deployment still needs retention policy,
user-controlled export/deletion, institutional verification, key recovery, and
incident response procedures.
