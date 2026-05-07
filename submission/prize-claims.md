# Prize Claim Strategy

Date: 2026-05-07

Use only claims backed by current evidence. Do not overclaim government integration, legal correctness, or trained weights.

## Claim Strongly

### Main Track

Claim ZPK Digital ID as a working Android social-impact app for local-first identity safety in Guatemala:

- Citizen mode and institutional ventanilla mode.
- Spanish-first intake for identity recovery, IGSS/SAT/school access, extortion, remittance fraud, field access, coercion safety, and prevention.
- Synthetic CUI/DPI only; no real PII or real breach data.
- Local privacy guard blocks raw CUI and 13-digit identifiers before model calls.
- Local breach/risk catalog and threat bulletins.
- Redacted complaint or intake packet generation.
- QR-style packet handoff to the local ventanilla workflow.
- Android privacy hardening: backup/data extraction disabled, cleartext traffic disabled, and `FLAG_SECURE`.
- Android Keystore signing in release for `sign_packet`.

### Gemma 4 / LiteRT Special Technology Track

Claim the final physical Android proof:

- Release APK: `submission/live-demo/zpk-citizen-gemma4-release.apk`.
- APK SHA-256: `7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb`.
- Installed `base.apk` on the Honor phone matched the same SHA-256.
- Model: `gemma-4-E2B-it.litertlm`.
- Model size: `2,583,085,056 bytes`.
- Model SHA-256: `ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42`.
- UI evidence: `docs/evidence/honor-release-citizen-gemma-final-2026-05-07.xml`.
- Verified tool path: `redact_pii`, `classify_case`, `lookup_codigo_penal`, `draft_denuncia`, `sign_packet`.
- Output: formal Ministerio Publico complaint for a WhatsApp extortion/card-photo request.
- Signature: Android Keystore issuer `zpk-android-keystore-issuer-key-2026-05`.

This is the strongest special-prize claim. Older Mac/iOS/Motorola evidence can be mentioned as supporting engineering context, but the primary claim is now the Honor physical-device release run.

### Digital Equity & Inclusivity

This remains the best impact track:

- The user does not need cybersecurity, legal, or AI background.
- The app "de-buttons" the workflow: tell the phone what happened, get the paper and safe next steps.
- CUI/DPI remains local; institutions receive redacted proof instead of copied raw identifiers.
- The design fits fragile infrastructure contexts in Guatemala and can scale to Central America and Latin America.

### Safety & Trust

Claim as a secondary angle:

- Visible tool trace instead of opaque chatbot answer.
- Safe-close loop if Gemma repeats tools or fails to call `final`.
- Best valid artifact is preserved and signed.
- Revocation, consent, redacted packet, and audit archive components exist in the app.

## Claim Carefully

### Cactus

Claim only supplemental local inference/routing evidence:

- Cactus Flutter SDK integrated.
- Telemetry disabled.
- Local inference trace exists for `functiongemma-270m`.

Do not make Cactus the primary special-track claim.

### Unsloth / Adaptation

Claim dataset and training pipeline only:

- 12,000 synthetic Guatemala/LatAm SFT examples.
- 1,200 ReAct teacher traces.
- SFT/GRPO scripts and deterministic reward code.

Do not claim a trained adapter, published weights, or benchmark improvement until a larger-GPU run produces actual adapter artifacts.

## Do Not Claim

- Production government integration with RENAP, IGSS, SAT, MP, banks, telcos, or police.
- Legal advice or guaranteed legal correctness.
- Real citizen enrollment.
- Real breach data.
- Remote attestation or standards certification.
- A trained fine-tuned Gemma 4 model.
- That every generated token is perfect. The app-level harness exists because small local models need repair, validation, safe-close, and local tools.
