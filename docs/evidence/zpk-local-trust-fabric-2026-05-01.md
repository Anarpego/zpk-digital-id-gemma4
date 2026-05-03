# ZPK Local Trust Fabric Evidence

Date: 2026-05-01

This app now demonstrates ZPK Digital ID as a local-first identity wallet, not only a breach-response helper.

## Local-Only Infrastructure Evidence

- HMAC-derived pseudonymous citizen ID: `zpk-gt-...`
- DID-style document: `did:zpk:gt:zpk-gt-...`
- Android Keystore-backed HMAC-SHA256 verifiable-credential-style recovery credential: `ZpkIdentityRecoveryCredential`
- Signed and locally verified SHA-256 agent execution ledger: local tool calls, credential issue, consent, and reasoner route
- Hash-verified offline civic threat bulletins: Guatemala and Latin America fraud patterns matched without raw CUI
- Signed and locally verified redacted recovery packet: private complaint remains local, institutional packet excludes raw CUI
- Selective disclosure claims: risk, match count, scenario, pseudonymous citizen ID
- Short-lived signed consent proof: 15 minutes
- Redacted institutional packet: no raw CUI
- Recovery/revocation status

## Agent Trace

The local agent builds this state before model reasoning:

```text
agent.plan(...) -> validate_cui, local_breach_lookup, classify_identity_risk, preserve_evidence, select_privacy_route, prepare_action_packet
select_privacy_route(local_model) -> pii_block_ok
threat_bulletin.verify(offline_hash_pack) -> 8/8_hash_ok
threat_bulletin.match(CUI+correo+nombre+telefono) -> gt-dpi-fraud-ngo-2026-04,latam-sim-swap-cui-2026-04
institution_recovery_packet(public_service_or_registry_breach) -> redacted_claim+presence_proof+review_request
field_access_voucher(school_clinic_aid_without_connectivity) -> limited_claim+offline_qr+no_document_copy
coercion_safety_plan(identity_threat_with_personal_safety_risk) -> sealed_timeline+safe_contact_summary
threat_bulletin.action(dpi_photo_identity_theft) -> Preparar denuncia preliminar, alertas bancarias y bloqueo preventivo de tramites no reconocidos.
trust_fabric.did_document(local) -> did:zpk:gt:...
trust_fabric.vc_selective_disclosure(local) -> ...
trust_fabric.sign_credential(hmac-sha256) -> ok
trust_fabric.keystore(android-keystore) -> zpk-android-keystore-issuer-key-2026-05
trust_fabric.verify_credential_signature(local) -> ok
trust_fabric.issue_consent(local, 15m) -> signed
agent_ledger.hash_chain(sha256) -> ...
agent_ledger.sign(android-keystore) -> ...
agent_ledger.verify(local) -> ok
recovery_packet.sign(android-keystore) -> ...
recovery_packet.verify(local) -> ok
trust_fabric.institution_packet(redacted) -> ...
```

## Non-Claims

This is not a production government identity system or real public-sector integration. The app runtime now signs with Android Keystore, and tests verify ledger and recovery-packet tamper rejection with a deterministic local signer. A production deployment would still need institution-backed key governance, attestation policy, standards conformance testing, audits, and operations.
