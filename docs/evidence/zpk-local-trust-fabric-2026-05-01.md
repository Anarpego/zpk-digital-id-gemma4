# ZPK Local Trust Fabric Evidence

Date: 2026-05-01

This app now demonstrates ZPK Digital ID as a local-first identity wallet, not only a breach-response helper.

## Local-Only Infrastructure Simulated

- HMAC-derived pseudonymous citizen ID: `zpk-gt-...`
- DID-style document: `did:zpk:gt:zpk-gt-...`
- Android Keystore-backed HMAC-SHA256 verifiable-credential-style recovery credential: `ZpkIdentityRecoveryCredential`
- Signed SHA-256 agent execution ledger: local tool calls, credential issue, consent, and reasoner route
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
trust_fabric.keystore(android-keystore) -> zpk-android-keystore-issuer-key-2026-05
trust_fabric.verify_credential_signature(local) -> ok
trust_fabric.issue_consent(local, 15m) -> signed
agent_ledger.hash_chain(sha256) -> ...
agent_ledger.sign(android-keystore) -> ...
trust_fabric.institution_packet(redacted) -> ...
```

## Non-Claims

This is not a production government identity system or real public-sector integration. The app runtime now signs with Android Keystore, and tests verify tamper rejection with a deterministic local signer. A production deployment would still need institution-backed key governance, attestation policy, standards conformance testing, audits, and operations.
