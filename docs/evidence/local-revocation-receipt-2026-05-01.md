# Local Revocation Receipt Evidence

Date: 2026-05-01

Purpose: make the identity wallet behave more like production identity
infrastructure by turning revocation from a trace label into a signed local
citizen action.

## Implemented Controls

- Added `RevocationService`.
- Added a visible `Revocar credencial local` action in the Android UI.
- Revocation creates a signed redacted receipt with:
  - revocation ID
  - citizen pseudonym
  - DID
  - reason
  - SHA-256 receipt hash
  - Android Keystore or local-test HMAC signature
- Raw CUI is omitted from the revocation payload.
- The visible trace includes:
  - `revocation.redact(raw_cui) -> omitted`
  - `revocation.receipt(sha256) -> ...`
  - `revocation.sign(...) -> ...`

## Verification

Commands run from `kan-app`:

- `flutter test test/services/revocation_service_test.dart test/widget_test.dart`:
  passed.
- `flutter analyze`: passed with no issues.
- `flutter test`: 30 tests passed.
- `flutter build apk --debug`: passed.

The service test verifies that the signed revocation payload does not contain
the raw synthetic CUI.

## Non-Claims

This revokes the local app credential receipt only. A production national
deployment still needs online/offline revocation registries, institutional
distribution, recovery appeals, and legal policy for when a credential should
be reissued.
