# Prize Claim Strategy

Date: 2026-05-01

Use only claims backed by current evidence unless more work is completed.

## Claim Now

### Main Track

Claim Kan as a working social-impact prototype with:

- Android app.
- Offline synthetic CUI verification.
- Spanish guidance and complaint draft.
- Hosted Gemma 4 app mode verified with `gemma-4-31b-it`.
- Visible privacy/routing/tool traces.

### Digital Equity & Inclusivity

This is the strongest Impact Track fit.

Evidence:

- Spanish-first workflow.
- Low-friction Android demo.
- Local-first breach response for citizens who may not understand legal or cybersecurity language.
- Complaint document generation instead of generic chatbot advice.

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

Current status is seed data plus scaffold only.

### On-Device Gemma 4

Do not claim on-device Gemma 4. Current Gemma 4 evidence is hosted through the Gemini API with `gemma-4-31b-it`.

### Production Legal Correctness

Do not claim legal advice or production correctness. Say "preliminary complaint draft" and "citizen guidance".
