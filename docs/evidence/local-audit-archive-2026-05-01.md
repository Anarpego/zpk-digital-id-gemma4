# Local Audit Archive Evidence

Date: 2026-05-01

Purpose: move ZPK Digital ID closer to a production app by retaining a
redacted, append-only audit receipt on device after identity recovery
registration.

## Implemented Controls

- Added `AuditArchiveService` with an Android `NativeAuditArchive`.
- Android stores redacted JSON records in private app-internal storage:
  `filesDir/zpk-audit-archive`.
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

## Verification

Commands run from `kan-app`:

- `flutter test test/services/audit_archive_test.dart test/widget_test.dart`:
  passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: 28 tests passed.
- `flutter build apk --debug`: passed.

The archive test verifies that the stored canonical record does not contain the
raw synthetic CUI and does not contain the private complaint text.

## Android Runtime Evidence

Runtime run on Mac-hosted Android emulator `Medium_Phone_API_36.1`:

```bash
adb install -r kan-app/build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n gt.kan.kan_app/.MainActivity
adb shell input tap 540 1050
adb shell run-as gt.kan.kan_app ls -l files/zpk-audit-archive
adb shell run-as gt.kan.kan_app cat files/zpk-audit-archive/38854b33ba2fb9c9dde114cd377ee483dcc9b679fb0e9d74c4b943bb293eac43.json
```

Observed app-private file:

```text
38854b33ba2fb9c9dde114cd377ee483dcc9b679fb0e9d74c4b943bb293eac43.json
```

Exported redacted runtime record:

- `docs/evidence/local-audit-archive-runtime-2026-05-01.json`

SHA-256:

```text
38854b33ba2fb9c9dde114cd377ee483dcc9b679fb0e9d74c4b943bb293eac43  docs/evidence/local-audit-archive-runtime-2026-05-01.json
```

Negative check:

```bash
rg -q "1234567890101" docs/evidence/local-audit-archive-runtime-2026-05-01.json; test $? -eq 1
```

## Non-Claims

This is app-internal storage, not cross-device backup, HSM custody, or a
government audit service. A real deployment still needs retention policy,
user-controlled export/deletion, institutional verification, and incident
response procedures.
