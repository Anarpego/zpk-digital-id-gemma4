# ZPK Digital ID: Local-First Identity Protection for Guatemala

**Selected Impact Track: Digital Equity & Inclusivity**

ZPK Digital ID addresses a national-scale problem: people need digital identity and safe authentication, but vulnerable countries cannot assume every registry, aid program, employer portal, or public service will protect personal data perfectly. In April 2026, Guatemalan public reporting described repeated attacks on government, employment, university, and public-service systems, including exposed DPI/CUI, contacts, salaries, bank data, credentials, and ransom demands. In that context, a leaked identity can trigger fraud, extortion, fake aid programs, SIM abuse, loan scams, and bureaucratic confusion. ZPK turns that risk into a local wallet workflow: register, protect, recover, and safely hand off only redacted proof.

The submitted app uses only synthetic data. A citizen selects a mission such as IGSS registration/recovery, SAT access/update, school or university enrollment, identity recovery, extortion evidence preservation, economic fraud/remittance triage, public-service recovery, field access, coercion safety, suspicion, or prevention. With a test CUI, the app registers a pseudonymous ZPK identity on device. Without a CUI, institution flows generate only a checklist and institutional intake packet, not a false credential. ZPK checks an embedded risk catalog, explains the result in Spanish, and prepares a private local complaint or intake plus a signed redacted packet without sending the raw CUI to a server.

## How ZPK Uses Gemma 4

ZPK combines local-first privacy with verified Gemma 4 reasoning. The app has five reasoner modes and one offline edge smoke path:

1. Deterministic local mode for reliable offline operation and tests.
2. Cactus local mode for on-device routing and local inference evidence.
3. Hosted Gemma 4 mode through the Gemini API using `gemma-4-31b-it`.
4. ML Kit/AICore mode for the official Android on-device Prompt API path.
5. LiteRT-LM Gemma 4 E2B Android mode for app-controlled local model loading.
6. LiteRT-LM Gemma 4 E2B local smoke path on the Mac for true offline generation evidence.

The hosted Gemma 4 path is verified in the Android app. The trace shows `gemma_api.generateContent(gemma-4-31b-it) -> ok` and token accounting. The separate smoke test returned model version `gemma-4-31b-it`. I also verified real offline Gemma 4 E2B generation through Google AI Edge LiteRT-LM on the Mac after downloading the model once: `litert_gemma.generate(gemma-4-E2B-it, HF_HUB_OFFLINE=1) -> ok`, returning JSON explaining that ZPK can orient without internet because Gemma runs local and the CUI stays on device.

The ML Kit/AICore path compiles and runs on the Mac Android emulator, but the emulator reports the GenAI feature as `UNAVAILABLE`. ZPK also has an Android LiteRT-LM bridge using Google AI Edge `litertlm-android`: the emulator loads the 2.4 GB Gemma 4 E2B artifact from app-private storage and reaches prefill/decode, then fails closed because the virtual device lacks a usable OpenCL sampler. On a physical Motorola G15, the app installed the real 2,583,085,056-byte Gemma 4 E2B model into app-private storage, then correctly reported `DEVICE_LOW_MEMORY` because the phone exposes 3.86 GB RAM versus a 6 GB safety gate. The Motor view now shows `Respaldo offline disponible`, `runtime.local_deterministic -> ready`, and `runtime.network_required -> false` on that device. I do not claim successful Android in-app Gemma 4 generation on the G15; the successful offline Gemma 4 generation claim is backed by the Mac LiteRT-LM smoke path and iOS/Apple Silicon FlutterGemma path.

## Agentic Identity Flow

The important change is that Gemma is no longer just a response generator. ZPK builds a structured local agent context before any model call and accepts model output only when it satisfies a JSON agent-response contract:

- `agent.plan(...) -> validate_cui, local_breach_lookup, classify_identity_risk, preserve_evidence, select_privacy_route, prepare_action_packet`
- `select_privacy_route(...) -> pii_block_ok`
- `preserve_evidence(threat_or_extortion) -> sealed_local_timeline+redacted_report`
- `economic_fraud_triage(loan_remittance_employment_scam) -> freeze_checklist+institution_packet`
- `institution_recovery_packet(public_service_or_registry_breach) -> redacted_claim+presence_proof+review_request`
- `igss_registration_agent(social_security_registration_or_recovery) -> eligibility_checklist+presence_proof+institution_intake`
- `sat_access_agent(tax_portal_access_or_update) -> portal_safety_check+redacted_update_packet`
- `education_enrollment_agent(school_or_university_registration) -> guardian_consent+limited_student_claim+institution_intake`
- `field_access_voucher(school_clinic_aid_without_connectivity) -> limited_claim+offline_qr+no_document_copy`
- `coercion_safety_plan(identity_threat_with_personal_safety_risk) -> sealed_timeline+safe_contact_summary`
- `threat_bulletin.verify(offline_hash_pack) -> 8/8_hash_ok`
- `threat_bulletin.match(...) -> Guatemala and Latin America risk context`
- `privacy_guard.raw_cui -> absent`
- `privacy_guard.13_digit_identifier -> absent`
- `agent_contract.schema(json) -> ok`
- `agent_contract.safety_review(raw_cui=false) -> ok`
- `trust_fabric.did_document(local) -> did:zpk:gt:...`
- `trust_fabric.vc_selective_disclosure(local) -> ...`
- `trust_fabric.sign_credential(hmac-sha256) -> ok`
- `trust_fabric.keystore(android-keystore) -> zpk-android-keystore-issuer-key-2026-05`
- `trust_fabric.verify_credential_signature(local) -> ok`
- `trust_fabric.issue_consent(local, 15m) -> signed`
- `auth.relying_party(local_allowlist) -> approved`
- `auth.device_presence(android-keyguard) -> verified`
- `auth.challenge(local) -> ...`
- `auth.sign(android-keystore) -> ...`
- `auth.verify(local) -> ok`
- `auth.valid_until(local) -> ...`
- `revocation.receipt(sha256) -> ...`
- `revocation.sign(android-keystore) -> ...`
- `auth.blocked(revocation) -> credential_revoked`
- `agent_ledger.hash_chain(sha256) -> ...`
- `agent_ledger.sign(android-keystore) -> ...`
- `agent_ledger.verify(local) -> ok`
- `recovery_packet.sign(android-keystore) -> ...`
- `recovery_packet.verify(local) -> ok`
- `audit_archive.redacted_record(sha256) -> ...`
- `audit_archive.raw_cui -> omitted`
- `audit_archive.encrypt(AES-GCM-256, android-keystore) -> sealed`
- `audit_archive.clear(...) -> ...`

This local trust fabric simulates the infrastructure a national digital identity system would need: a DID-style document, Android Keystore-backed HMAC-SHA256 verifiable-credential-style recovery credential, Android device-presence-gated verifier-enforced allowlisted expiring local authentication proof, signed and locally verified agent execution ledger, signed and locally verified redacted recovery packet, selective disclosure claims, short-lived consent proof, signed local revocation receipt that blocks later auth proofs, a redacted institutional packet, and a citizen-clearable app-internal audit archive sealed with AES-GCM and Android Keystore. It is not a claim of government integration or emergency response. It is an offline testbed showing how Guatemala, and later other Latin American countries, could protect people without centralizing raw identifiers.

## Local-First Architecture

The APK bundles `assets/breach_catalog.json`, a synthetic offline catalog with no real personal data, and 8 hash-verified civic threat bulletins for Guatemala and Latin America fraud, extortion, SIM-swap, public-service account-takeover, field access, and coercion-safety patterns. `LocalBreachCatalog.loadEmbeddedOrFallback()` loads the risk catalog on device. The CUI is used only locally to create a pseudonymous ZPK citizen ID and risk assessment. Internet is used only for optional first-time model download or future bulletin updates; the CUI check, Gemma reasoning on supported hardware after install, identity proofs, authentication, revocation, redacted packet, and encrypted audit run offline. Hosted reasoning receives only redacted facts such as match count, risk level, scenario, threat-bulletin IDs, and action needs. A code-level `PrivacyGuard` now blocks the active raw CUI or any unredacted 13-digit identifier before hosted Gemma, Cactus local inference, ML Kit/AICore, or LiteRT-LM generation, and `AgentResponseContract` rejects model output that is not valid JSON or leaks identifiers.

The Android shell adds production-style privacy hardening: `FLAG_SECURE` blocks screenshots and screen recording, app backup/data extraction is disabled, cleartext traffic is disallowed, and local audit receipts are encrypted at rest before storage.

After a synthetic match, ZPK generates Spanish guidance and a preliminary complaint document locally. For IGSS, SAT, and education cases, it also shows an institutional intake view: the institution sees facts, pseudonym, hash, and decision checklist, not a copied DPI. For extortion-style cases, it preserves a sealed local timeline. For economic fraud/remittance cases, it produces bank, telco, and institution handoff steps without exposing full CUI. For field access and coercion risk, it prepares a limited offline claim or safe-contact summary. The app can be installed from the submission package and run without a backend.

## Cactus And Adaptation Evidence

ZPK integrates the Cactus Flutter SDK and disables Cactus telemetry in `ReasonerFactory`. A Cactus emulator run with `functiongemma-270m` and tools disabled succeeded locally with TTFT `926ms`, total `993ms`, and `60.4 tok/s`. I claim this cautiously as local inference/routing evidence only; Cactus tool-calling currently fails with `completion failed with code -1`.

ZPK also uses a Training-Free GRPO-style experience prior inspired by `arXiv:2510.08191`: verify locally before requesting data, separate plain explanation from legal steps, and fill documents only on device. The adaptation folder now contains a real fine-tuning pipeline, not a paper-only claim: a deterministic generator produced 12,000 synthetic Guatemala/LatAm Spanish examples with train/validation/test splits for identity recovery, extortion evidence, economic fraud/remittance triage, IGSS registration, SAT access, school enrollment, and preventive wallet registration. The dataset quality gate passed: strict JSON, unique IDs, synthetic metadata, no 13-digit identifiers, and `raw_cui_included=false`. It also includes 1,200 structured teacher traces inspired by RLKD (`arXiv:2505.16142v4`), reward functions for valid JSON, no PII leakage, offline boundary, and actionable redacted handoff, plus SFT LoRA/QLoRA and optional GRPO entrypoints. I do not claim a trained adapter yet; the available 6 GB GPU reached Gemma 4 E2B load/tokenization before OOM.

## Impact

ZPK targets Digital Equity & Inclusivity because it turns identity safety into a Spanish-first mobile workflow for people who should not need to understand breach databases, LLMs, or legal forms. The strongest claim is not that ZPK is production government infrastructure today. It is that a privacy-preserving Android identity wallet, backed by Gemma 4 reasoning and local selective disclosure, can make safe digital identity practical in countries where cloud-only systems and centralized registries are risky.

## Reproducibility

The repository includes the Flutter app, synthetic catalog, tests, evidence screenshots, packaging script, hosted Gemma 4 smoke script, LiteRT-LM Android bridge, QR wireless installer, LiteRT-LM offline Gemma 4 smoke script, LiteRT app-agent harness, ML Kit/AICore path, and the Gemma 4 adaptation pipeline. Current local gates pass: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, and signed ARM64 release APK packaging.
