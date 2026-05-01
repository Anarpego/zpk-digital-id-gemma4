# Android Privacy Hardening Evidence

Date: 2026-05-01

Purpose: reduce mobile data-leak risk for CUI/DPI-style identity workflows.

## Implemented Controls

- `FLAG_SECURE` in `MainActivity.onCreate()` to block screenshots and screen recording in the production app window.
- `android:allowBackup="false"` to avoid Android app-data backup for identity data.
- `android:usesCleartextTraffic="false"` to block cleartext HTTP traffic.
- `android:fullBackupContent="@xml/backup_rules"` with all storage domains excluded.
- `android:dataExtractionRules="@xml/data_extraction_rules"` with cloud-backup and device-transfer exclusions.

## Verification

`flutter build apk --debug` completed successfully.

Manifest attributes were inspected from the built APK with:

```bash
$HOME/Library/Android/sdk/build-tools/36.1.0/aapt2 dump xmltree \
  --file AndroidManifest.xml \
  kan-app/build/app/outputs/flutter-apk/app-debug.apk \
  | rg "allowBackup|usesCleartextTraffic|dataExtractionRules|fullBackupContent"
```

Confirmed output includes:

```text
allowBackup=false
fullBackupContent=@0x7f100000
usesCleartextTraffic=false
dataExtractionRules=@0x7f100001
```

## Non-Claims

This does not replace device management, endpoint hardening, remote attestation,
or a formal mobile security audit. It is a real Android privacy hardening layer
for the local-first demo app.
