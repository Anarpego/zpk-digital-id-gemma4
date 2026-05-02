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
- Hosted Gemma 4 app mode verified with `gemma-4-31b-it`.
- ML Kit/AICore Android mode integrated and verified to fail closed on the Mac emulator.
- Validated JSON agent-response contract for hosted, Cactus, and ML Kit model outputs.
- Visible privacy/routing/tool traces.
- A complete identity safety workflow: register, authenticate, protect, recover, and revoke locally.

### Digital Equity & Inclusivity

This is the strongest Impact Track fit.

Evidence:

- Spanish-first workflow.
- Low-friction Android demo.
- Local-first identity protection for citizens who may not understand legal, cybersecurity, or credential systems.
- Complaint/recovery packet generation instead of generic chatbot advice.
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

### Unsloth Prize

Do not claim Unsloth prize readiness until there is:

- A completed training run.
- Adapter output.
- Before/after benchmark.
- Reproducible training environment evidence.

Current status is seed data, scaffold, verified CUDA/Unsloth imports, and a failed one-step Gemma 4 E2B attempt. The attempt downloaded the model, loaded weights, and tokenized the dataset, then failed with CUDA OOM on the 6 GB RTX 4050 before step 1.

### On-Device Gemma 4

Do not claim successful on-device Gemma 4 generation. The Android ML Kit/AICore path now compiles and runs, handles status probing, model download, and warmup on supported devices, but the available `Medium_Phone_API_36.1` emulator returns `UNAVAILABLE`. Claim only the integration/fallback evidence unless a supported AICore device produces a successful local generation trace.

### Offline Gemma 4

Do not claim offline Gemma 4. The offline result is the sensitive-data workflow: embedded synthetic catalog lookup, hash-verified civic threat bulletins, routing trace, Spanish guidance, and a local preliminary complaint packet. Gemma 4 is verified separately through hosted `gemma-4-31b-it`; the ML Kit/AICore path still needs a supported device for successful local generation.

### Production Government Or Crypto Claims

Do not claim production government integration, remote attestation, hardware-backed key custody on every device, or standards compliance. Say "DID-style" and "Android Keystore-backed HMAC-SHA256 local recovery credential" unless a real standards conformance suite and institution-backed key management are added.

### Production Legal Correctness

Do not claim legal advice or government production readiness. Say "preliminary complaint packet" and "citizen guidance".
