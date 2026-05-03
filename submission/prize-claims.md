# Prize Claim Strategy

Date: 2026-05-01

Use only claims backed by current evidence unless more work is completed.

## Claim Now

### Main Track

Claim ZPK Digital ID as a working social-impact Android app with:

- Android app.
- Offline ZPK identity registration and synthetic CUI risk verification.
- DID-style document, Android Keystore-backed HMAC-SHA256 recovery credential, Android device-presence-gated verifier-enforced allowlisted expiring local authentication proof, signed and locally verified agent execution ledger, signed and locally verified redacted recovery packet, revocation that blocks later auth proofs, selective disclosure claims, and 15-minute consent proof.
- Android privacy hardening: screenshot/screen-recording blocked, backup/data extraction disabled, and cleartext traffic disabled.
- Spanish guidance, redacted institutional packet, and preliminary complaint packet.
- Citizen and institutional intake views for IGSS registration/recovery, SAT access/update, and school/university enrollment. No-CUI flows produce checklist and intake only, not identity credentials.
- Hosted Gemma 4 app mode verified with `gemma-4-31b-it`.
- Offline Gemma 4 E2B local generation verified with LiteRT-LM on the Mac after model download and `HF_HUB_OFFLINE=1`.
- Android LiteRT-LM bridge integrated with `litertlm-android`; emulator evidence loads the Gemma 4 E2B artifact from app-private storage and reaches prefill/decode before failing closed on missing OpenCL sampler support.
- Physical Motorola G15 evidence installs the real 2,583,085,056-byte Gemma 4 E2B model into app-private storage, then reports `DEVICE_LOW_MEMORY` because the phone has 3.86 GB RAM versus the app's 6 GB generation safety gate. The same Motor status now shows `Respaldo offline disponible`, `runtime.local_deterministic -> ready`, and `runtime.network_required -> false`. Claim this as honest device gating plus usable offline fallback, not successful generation.
- Pre-device LiteRT app-agent harness verifies the full Flutter UI consumes Gemma JSON from the Android channel, validates the agent contract, renders offline runtime status, and shows `litert_gemma.generate(...) -> ok` traces under controlled test conditions.
- ML Kit/AICore Android mode integrated and verified to fail closed on the Mac emulator.
- Validated JSON agent-response contract for hosted, Cactus, and ML Kit model outputs.
- Visible privacy/routing/tool traces.
- A complete identity safety workflow: register, authenticate, protect, recover, and revoke locally.
- Adaptation pipeline: 12,000 validated synthetic Guatemala/LatAm SFT examples, 1,200 RLKD-style structured teacher traces, SFT LoRA/QLoRA script, optional GRPO script, and deterministic rewards for JSON validity, no PII leakage, offline boundary, and redacted handoff.

### Digital Equity & Inclusivity

This is the strongest Impact Track fit.

Evidence:

- Spanish-first workflow.
- Low-friction Android demo.
- Local-first identity protection for citizens who may not understand legal, cybersecurity, or credential systems.
- Complaint/recovery packet generation instead of generic chatbot advice.
- Institution-ready flows for IGSS, SAT, education, public-service recovery, field school/health/aid access, and coercion safety, all using redacted packets rather than raw CUI handoff.
- Significant use case: helping a citizen register safely, limit disclosure, and recover after suspected DPI/CUI exposure.

### Cactus Prize

Claim cautiously only if special-prize routing allows partial local-inference evidence.

Evidence:

- Cactus Flutter SDK integrated.
- Telemetry disabled.
- Cactus local inference succeeded with `functiongemma-270m`, tools disabled.
- UI metrics captured: TTFT `926ms`, total `993ms`, `60.4 tok/s`.

Limitations to disclose:

- Cactus tool-calling fails with `completion failed with code -1`.
- Cactus catalog did not expose a verified Gemma 4 slug.
- Cactus output quality is not final-demo quality.

## Do Not Claim Yet

### Unsloth / Fine-Tuned Adapter Claim

Claim the adaptation dataset and training pipeline, but do not claim a trained adapter until there is:

- A completed training run.
- Adapter output.
- Before/after benchmark.
- Reproducible training environment evidence.

Current status is validated synthetic data, RLKD-style teacher traces, SFT/GRPO scripts, verified CUDA/Unsloth imports, and a failed one-step Gemma 4 E2B attempt. The attempt downloaded the model, loaded weights, and tokenized the earlier seed dataset, then failed with CUDA OOM on the 6 GB RTX 4050 before step 1.

### Android ML Kit/AICore Gemma 4

Do not claim successful Android ML Kit/AICore Gemma 4 generation. The Android ML Kit/AICore path now compiles and runs, handles status probing, model download, and warmup on supported devices, but the available `Medium_Phone_API_36.1` emulator returns `UNAVAILABLE`.

### Flutter Android In-App LiteRT-LM

Claim Android LiteRT-LM integration, model-install evidence, low-memory guard evidence, offline fallback evidence, and pre-device app-agent harness coverage, not successful native Android generation yet. Current Android evidence: native `litertlm-android` bridge, app-private model path, model mmap, Gemma 4 runtime settings, `RunPrefillAsync status: OK`, and `RunDecodeAsync`; the emulator then fails closed because the virtual device lacks a usable OpenCL sampler. A Motorola G15 installs the full model but is blocked by `DEVICE_LOW_MEMORY` and remains usable through `runtime.local_deterministic -> ready`. A higher-RAM Android device is still needed for native `litert_gemma.generate(...) -> ok`.

### Production Government Or Crypto Claims

Do not claim production government integration, remote attestation, hardware-backed key custody on every device, or standards compliance. Say "DID-style" and "Android Keystore-backed HMAC-SHA256 local recovery credential" unless a real standards conformance suite and institution-backed key management are added.

### Production Legal Correctness

Do not claim legal advice or government production readiness. Say "preliminary complaint packet" and "citizen guidance".
