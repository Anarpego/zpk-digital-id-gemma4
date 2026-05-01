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

## Non-Claims

This is app-internal storage, not cross-device backup, HSM custody, or a
government audit service. A real deployment still needs retention policy,
user-controlled export/deletion, institutional verification, and incident
response procedures.
