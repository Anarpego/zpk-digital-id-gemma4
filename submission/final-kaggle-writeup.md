# ZPK Digital ID: Local-First Identity Protection for Guatemala

**Selected Impact Track: Digital Equity & Inclusivity**

ZPK Digital ID addresses a national-scale problem: people need digital identity and safe authentication, but vulnerable countries cannot assume every registry, aid program, employer portal, or public service will protect personal data perfectly. In Guatemala, a leaked DPI/CUI can expose a citizen to fraud, fake aid programs, SIM abuse, and bureaucratic confusion. ZPK turns that risk into a local wallet workflow: register, protect, and recover.

The demo uses only synthetic data. A citizen enters a test CUI, the app registers a pseudonymous ZPK identity on device, checks an embedded risk catalog, explains the result in Spanish, and prepares a private local complaint plus a signed redacted recovery packet without sending the raw CUI to a server.

## How ZPK Uses Gemma 4

ZPK combines local-first privacy with verified Gemma 4 reasoning. The app has four reasoner modes:

1. Deterministic local mode for reliable offline demos and tests.
2. Cactus local mode for on-device routing and local inference evidence.
3. Hosted Gemma 4 mode through the Gemini API using `gemma-4-31b-it`.
4. ML Kit/AICore mode for the official Android on-device Prompt API path.

The hosted Gemma 4 path is verified in the Android app. The trace shows `gemma_api.generateContent(gemma-4-31b-it) -> ok` and token accounting. The separate smoke test returned model version `gemma-4-31b-it`.

The ML Kit/AICore path compiles and runs on the Mac Android emulator, but the emulator reports the GenAI feature as `UNAVAILABLE`. ZPK now probes on-device status before generation, records that failure, and falls back locally, so I do not claim verified offline Gemma 4 generation without a supported AICore device.

## Agentic Identity Flow

The important change is that Gemma is no longer just a response generator. ZPK builds a structured local agent context before any model call:

- `agent.plan(...) -> validate_cui, local_breach_lookup, classify_identity_risk, select_privacy_route, draft_action_packet`
- `select_privacy_route(...) -> pii_block_ok`
- `privacy_guard.raw_cui -> absent`
- `privacy_guard.13_digit_identifier -> absent`
- `trust_fabric.did_document(local) -> did:zpk:gt:...`
- `trust_fabric.vc_selective_disclosure(local) -> ...`
- `trust_fabric.sign_credential(hmac-sha256) -> ok`
- `trust_fabric.keystore(android-keystore) -> zpk-android-keystore-issuer-key-2026-05`
- `trust_fabric.verify_credential_signature(local) -> ok`
- `trust_fabric.issue_consent(local, 15m) -> signed`
- `auth.relying_party(local_allowlist) -> approved`
- `auth.challenge(local) -> ...`
- `auth.sign(android-keystore) -> ...`
- `auth.verify(local) -> ok`
- `auth.valid_until(local) -> ...`
- `revocation.receipt(sha256) -> ...`
- `revocation.sign(android-keystore) -> ...`
- `auth.blocked(revocation) -> credential_revoked`
- `agent_ledger.hash_chain(sha256) -> ...`
- `agent_ledger.sign(android-keystore) -> ...`
- `audit_archive.redacted_record(sha256) -> ...`
- `audit_archive.raw_cui -> omitted`
- `audit_archive.encrypt(AES-GCM-256, android-keystore) -> sealed`
- `audit_archive.clear(...) -> ...`

This local trust fabric simulates the infrastructure a national digital identity system would need: a DID-style document, Android Keystore-backed HMAC-SHA256 verifiable-credential-style recovery credential, verifier-enforced allowlisted expiring local authentication proof, signed agent execution ledger, signed redacted recovery packet, selective disclosure claims, short-lived consent proof, signed local revocation receipt that blocks later auth proofs, a redacted institutional packet, and a citizen-clearable app-internal audit archive sealed with AES-GCM and Android Keystore. It is not a claim of government integration. It is an offline testbed showing how Guatemala, and later other Latin American countries, could protect people without centralizing raw identifiers.

## Local-First Architecture

The APK bundles `assets/breach_catalog.json`, a synthetic offline catalog with no real personal data. `LocalBreachCatalog.loadEmbeddedOrFallback()` loads it on device. The CUI is used only locally to create a pseudonymous ZPK citizen ID and risk assessment. Hosted reasoning receives only redacted facts such as match count, risk level, scenario, and action needs. A code-level `PrivacyGuard` now blocks the active raw CUI or any unredacted 13-digit identifier before hosted Gemma, Cactus local inference, or ML Kit/AICore generation.

The Android shell adds production-style privacy hardening for the demo: `FLAG_SECURE` blocks screenshots and screen recording, app backup/data extraction is disabled, cleartext traffic is disallowed, and local audit receipts are encrypted at rest before storage.

After a synthetic match, ZPK generates Spanish guidance and a preliminary complaint document locally. The app can be installed from the demo package and run without a backend.

## Cactus And Adaptation Evidence

ZPK integrates the Cactus Flutter SDK and disables Cactus telemetry in `ReasonerFactory`. A Cactus emulator run with `functiongemma-270m` and tools disabled succeeded locally with TTFT `926ms`, total `993ms`, and `60.4 tok/s`. I claim this cautiously as local inference/routing evidence only; Cactus tool-calling currently fails with `completion failed with code -1`.

ZPK also uses a Training-Free GRPO-style experience prior inspired by `arXiv:2510.08191`: verify locally before requesting data, separate plain explanation from legal steps, and fill documents only on device. Unsloth artifacts are prepared but not claimed as a trained result yet; the available 6 GB GPU reached Gemma 4 E2B load/tokenization before OOM.

## Impact

ZPK targets Digital Equity & Inclusivity because it turns identity safety into a Spanish-first mobile workflow for people who should not need to understand breach databases, LLMs, or legal forms. The strongest claim is not that ZPK is production government infrastructure today. It is that a privacy-preserving Android identity wallet, backed by Gemma 4 reasoning and local selective disclosure, can make safe digital identity practical in countries where cloud-only systems and centralized registries are risky.

## Reproducibility

The repository includes the Flutter app, synthetic catalog, tests, evidence screenshots, demo package script, Gemma 4 smoke script, ML Kit/AICore path, and Unsloth scaffold. Current local gates pass: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` with 36 tests, and `flutter build apk --debug`.
