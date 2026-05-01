# Local Authentication Proof Evidence

Date: 2026-05-01

Purpose: make ZPK Digital ID behave more like a real identity wallet by adding
a relying-party authentication proof, not only registration and recovery.

## Implemented Controls

- Added `LocalAuthenticationService`.
- The app can issue a signed local authentication proof for
  `municipalidad-guatemala-demo`.
- Relying parties are checked against a local allowlist before a proof is
  issued.
- The authentication packet includes only redacted/selective claims:
  - citizen pseudonym
  - DID-style identifier
  - relying party
  - allowed scopes
  - challenge
  - risk assurance
  - scenario
  - local match count
  - issued and expiry timestamps
- The packet excludes raw CUI.
- Authentication verification rejects expired packets.
- Runtime Android uses the existing `DigitalIdentityFabric.device()` signer,
  so proofs are backed by Android Keystore in the app.
- Local revocation now blocks new authentication proofs and clears any
  displayed authentication proof in the app UI.
- Tests use deterministic Dart HMAC signing only for repeatable verification.

## Visible Trace

The app now shows:

```text
auth.challenge(local) -> ...
auth.relying_party(local_allowlist) -> approved
auth.scopes(local_policy) -> identity_recovery+citizen_support
auth.selective_disclosure(local) -> 4_claims
auth.raw_cui -> omitted
auth.sign(android-keystore) -> ...
auth.verify(local) -> ok
auth.valid_until(local) -> ...
auth.expires(local) -> 5m
auth.blocked(revocation) -> credential_revoked
```

## Verification

Commands run from `kan-app`:

```bash
flutter test test/services/local_authentication_service_test.dart test/widget_test.dart
```

Result: 7 targeted tests passed.

Coverage:

- Builds a signed authentication proof without raw CUI.
- Verifies the signed authentication packet.
- Rejects a tampered authentication packet.
- Rejects authentication proof issuance to an unknown relying party.
- Rejects an expired authentication packet.
- Rejects new authentication proof issuance after local revocation.
- Widget flow exposes `Probar autenticacion local`, then shows
  `auth.sign(...)` and `auth.verify(local) -> ok`.
- Widget flow revokes the local credential and then shows
  `auth.blocked(revocation) -> credential_revoked`.

## Non-Claims

This is a local authentication proof and verifier simulation. It is not yet a
W3C VC conformance suite, remote attestation, government relying-party
integration, or production certificate authority.
