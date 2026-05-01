# Prize Claim Strategy

Date: 2026-05-01

Use only claims backed by current evidence unless more work is completed.

## Claim Now

### Main Track

Claim Kan as a working social-impact prototype with:

- Android app.
- Offline synthetic CUI verification for the sensitive-data path.
- Spanish guidance and complaint draft.
- Hosted Gemma 4 app mode verified with `gemma-4-31b-it`.
- Visible privacy/routing/tool traces.
- A complete breach-response workflow: detect, explain, act.

### Digital Equity & Inclusivity

This is the strongest Impact Track fit.

Evidence:

- Spanish-first workflow.
- Low-friction Android demo.
- Local-first breach response for citizens who may not understand legal or cybersecurity language.
- Complaint document generation instead of generic chatbot advice.
- Significant use case: helping a citizen move from suspected DPI/CUI exposure to a concrete next action.

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

Do not claim on-device Gemma 4. Current Gemma 4 evidence is hosted through the Gemini API with `gemma-4-31b-it`.

### Offline Gemma 4

Do not claim offline Gemma 4. The offline result is the sensitive-data workflow: embedded synthetic catalog lookup, routing trace, Spanish guidance, and local complaint draft. Gemma 4 is verified separately through hosted `gemma-4-31b-it`.

### Production Legal Correctness

Do not claim legal advice or production correctness. Say "preliminary complaint draft" and "citizen guidance".
