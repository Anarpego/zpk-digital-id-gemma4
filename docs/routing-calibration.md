# Routing Calibration

Kan needs to show local-first intelligence for the Cactus prize without sending personal data by default. The current prototype uses a deterministic routing policy that is easy to test and explain in the video.

## Routes

- `local_tools`: validation, local breach lookup, and template fill only.
- `local_model`: on-device model via Cactus for explanation and tone.
- `abstract_server`: optional future route for complex legal reasoning, with CUI and PII removed.

## Current Policy

- Invalid CUI: `local_tools`, 99% confidence.
- Local breach match: `local_model`, 92% confidence.
- Suspicion without match: `abstract_server`, 66% confidence, no PII.
- Preventive check without match: `local_tools`, 84% confidence.

## Conformal / TF-GRPO Use

The next calibration step is to collect synthetic cases, compare route choices against expected expert labels, and tune confidence thresholds to achieve a chosen error rate. The Training-Free GRPO paper (`arXiv:2510.08191`) is useful here because it lets Kan keep an experience prior for routing and tool-use behavior without paying for fine-tuning every iteration.

For the hackathon, the important evidence is visible: the app explains why it stayed local or when it would escalate, and every route declares whether personal data leaves the device.
