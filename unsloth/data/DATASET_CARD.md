# ZPK Guatemala/LatAm Synthetic Agent SFT Dataset

This dataset is generated, not scraped. It contains no real CUI, DPI, phone
numbers, addresses, victim names, bank accounts, or case files.

## Purpose

Teach Gemma 4 to follow the ZPK app contract in Spanish:

- distinguish online bootstrap from offline citizen workflows;
- protect raw CUI/DPI and other PII;
- triage identity recovery, extortion evidence, economic fraud, remittance/SIM
  risk, IGSS registration, SAT access, school enrollment, and preventive wallet
  registration;
- return valid JSON accepted by the app's `AgentResponseContract`;
- produce citizen and administrator views with redacted institution handoff
  steps for Guatemala and Latin America;
- handle no-CUI intake cases without emitting a false identity credential.

## Splits

- Train examples: 9840
- Validation examples: 1080
- Test examples: 1080

## Format

Each row uses TRL conversational `messages` format with `system`, `user`, and
`assistant` turns. The assistant turn is strict JSON with:

- `summary`
- `next_steps`
- `national_scale_note`
- `safety_review.raw_cui_included=false`
- `safety_review.needs_human_review`

## Safety

The generator intentionally avoids 13-digit identifiers and real institutional
claims. Use `uv run python evaluate_dataset.py` before training.
