# ZPK Local Trust Fabric Evidence

Date: 2026-05-01

This app now demonstrates ZPK Digital ID as a local-first identity wallet, not only a breach-response helper.

## Local-Only Infrastructure Simulated

- HMAC-derived pseudonymous citizen ID: `zpk-gt-...`
- DID-style document: `did:zpk:gt:zpk-gt-...`
- HMAC-SHA256-signed verifiable-credential-style recovery credential: `ZpkIdentityRecoveryCredential`
- Selective disclosure claims: risk, match count, scenario, pseudonymous citizen ID
- Short-lived signed consent proof: 15 minutes
- Redacted institutional packet: no raw CUI
- Recovery/revocation status

## Agent Trace

The local agent builds this state before model reasoning:

```text
agent.plan(...) -> validate_cui, local_breach_lookup, classify_identity_risk, select_privacy_route, draft_action_packet
select_privacy_route(local_model) -> pii_block_ok
trust_fabric.did_document(local) -> did:zpk:gt:...
trust_fabric.vc_selective_disclosure(local) -> ...
trust_fabric.sign_credential(hmac-sha256) -> ok
trust_fabric.verify_credential_signature(local) -> ok
trust_fabric.issue_consent(local, 15m) -> signed
trust_fabric.institution_packet(redacted) -> ...
```

## Non-Claims

This is not a production government identity system or real public-sector integration. The credential is now tamper-evident with local HMAC-SHA256 signing and verification, but a production deployment would still replace the demo issuer key with secure hardware-backed or institution-backed key management and standards conformance testing.
