# ZPK Local Trust Fabric Evidence

Date: 2026-05-01

This app now demonstrates ZPK Digital ID as a local-first identity wallet, not only a breach-response helper.

## Local-Only Infrastructure Simulated

- Pseudonymous citizen ID: `zpk-gt-...`
- DID-style document: `did:zpk:gt:zpk-gt-...`
- Verifiable-credential-style recovery credential: `ZpkIdentityRecoveryCredential`
- Selective disclosure claims: risk, match count, scenario, pseudonymous citizen ID
- Short-lived consent proof: 15 minutes
- Redacted institutional packet: no raw CUI
- Recovery/revocation status

## Agent Trace

The local agent builds this state before model reasoning:

```text
agent.plan(...) -> validate_cui, local_breach_lookup, classify_identity_risk, select_privacy_route, draft_action_packet
select_privacy_route(local_model) -> pii_block_ok
trust_fabric.did_document(local) -> did:zpk:gt:...
trust_fabric.vc_selective_disclosure(local) -> ...
trust_fabric.issue_consent(local, 15m) -> ok
trust_fabric.institution_packet(redacted) -> ...
```

## Non-Claims

This is not a production government identity system, not real public-sector integration, and not production cryptography. It is an offline testbed showing how a national or Latin America-wide identity recovery wallet could protect citizens even when institutions are breached.
